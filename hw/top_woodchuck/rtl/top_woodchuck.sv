
    
/****************************************************************************
 * zet_ng_soc_core.sv
 ****************************************************************************/
  
/**
 * Module: top_woodchuck
 * 
 * TODO: Add module documentation
 */

module top_woodchuck
    import dii_package::dii_flit;
    #(
        parameter ID       = 0,
        parameter DEBUG_BASEID = 1,
        parameter DEBUG_ROUTER_BUFFER_SIZE = 4,
        parameter DEBUG_MAX_PKT_LEN = 12,
        parameter USE_DEBUG = 1,
        
        parameter MEM_SIZE = 128*1024*1024,
        parameter MEM_ADDR_WIDTH = $clog2(MEM_SIZE),
        parameter MEM_FILE = ""
     )
     (
         // Debug ring ports
         input           dii_flit [1:0] debug_ring_in,
         output [1:0]    debug_ring_in_ready,
         output          dii_flit [1:0] debug_ring_out,
         input [1:0]     debug_ring_out_ready,
         
         // Wishbone external memory interface
         output [MEM_ADDR_WIDTH-1:0]   wb_ext_adr_o,
         output          wb_ext_cyc_o,
         output [31:0]   wb_ext_dat_o,
         output [3:0]    wb_ext_sel_o,
         output          wb_ext_stb_o,
         output          wb_ext_we_o,
         /* verilator lint_off UNDRIVEN */
         output          wb_ext_cab_o,
         /* verilator lint_on UNDRIVEN */
         output [2:0]    wb_ext_cti_o,
         output [1:0]    wb_ext_bte_o,
         input           wb_ext_ack_i,
         /* verilator lint_off UNUSED */
         input           wb_ext_rty_i,
         input           wb_ext_err_i,
         /* verilator lint_on UNUSED */
         input [31:0]    wb_ext_dat_i,

        // Clock and reset inputs
        input           clk,
        input           rst_cpu, rst_sys, rst_dbg
     );

////////////////////////////////////////////////////////////////////////
//
// Wishbone interconnect
//
////////////////////////////////////////////////////////////////////////

wire wb_clk = clk;
wire wb_rst = rst_sys;

`include "wb_intercon.vh"
    
////////////////////////////////////////////////////////////////////////
//
// OSD Debug Ring Expand Router
//
////////////////////////////////////////////////////////////////////////
    
// create DI ring segment with routers
localparam DEBUG_MODS_PER_CORE = 1;
localparam DEBUG_MODS_PER_CORE_NONZERO = (DEBUG_MODS_PER_CORE == 0) ? 1 : DEBUG_MODS_PER_CORE;

dii_flit [DEBUG_MODS_PER_CORE_NONZERO-1:0] dii_in;
logic [DEBUG_MODS_PER_CORE_NONZERO-1:0] dii_in_ready;
dii_flit [DEBUG_MODS_PER_CORE_NONZERO-1:0] dii_out;
logic [DEBUG_MODS_PER_CORE_NONZERO-1:0] dii_out_ready;

generate
    if (USE_DEBUG == 1) begin : gen_debug_ring
        genvar i;
        logic [DEBUG_MODS_PER_CORE-1:0][15:0] id_map;
        for (i = 0; i < DEBUG_MODS_PER_CORE; i = i+1) begin
            assign id_map[i][15:0] = 16'(DEBUG_BASEID+i);
        end

        debug_ring_expand
            #(.BUFFER_SIZE(DEBUG_ROUTER_BUFFER_SIZE),
              .PORTS(DEBUG_MODS_PER_CORE))
            u_debug_ring_segment
                (.clk           (clk),
                 .rst           (rst_dbg),
                 .id_map        (id_map),
                 .dii_in        (dii_in),
                 .dii_in_ready  (dii_in_ready),
                 .dii_out       (dii_out),
                 .dii_out_ready (dii_out_ready),
                 .ext_in        (debug_ring_in),
                 .ext_in_ready  (debug_ring_in_ready),
                 .ext_out       (debug_ring_out),
                 .ext_out_ready (debug_ring_out_ready));
    end // if (USE_DEBUG)
endgenerate

// Local debug module mapping
// id_map [0] = MAM

////////////////////////////////////////////////////////////////////////
//
// Master OSD MAM Wishbone Debug Module
//
////////////////////////////////////////////////////////////////////////

// Unused connections
// wire wb_s2m_osd_mam_err;
// wire wb_s2m_osd_mam_rty;
osd_mam_wb #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(MEM_ADDR_WIDTH),
    .MAX_PKT_LEN(DEBUG_MAX_PKT_LEN),
    .MEM_SIZE0(MEM_SIZE),
    .BASE_ADDR0(0))
u_mam_dm_wb(
    .clk_i(clk),
    .rst_i(rst_dbg),
    
    .debug_in(dii_out[0]),
    .debug_in_ready(dii_out_ready[0]),
    .debug_out(dii_in[0]),
    .debug_out_ready(dii_in_ready[0]),    
    .id (16'(DEBUG_BASEID)),
    
    .stb_o(wb_m2s_osd_mam_stb),
    .cyc_o(wb_m2s_osd_mam_cyc),
    .ack_i(wb_s2m_osd_mam_ack),
    .we_o(wb_m2s_osd_mam_we),
    .addr_o(wb_m2s_osd_mam_adr),
    .dat_o(wb_m2s_osd_mam_dat),
    .dat_i(wb_s2m_osd_mam_dat),
    .cti_o(wb_m2s_osd_mam_cti),
    .bte_o(wb_m2s_osd_mam_bte),
    .sel_o(wb_m2s_osd_mam_sel));

////////////////////////////////////////////////////////////////////////
//
// ZET CPU Wrapper
//
////////////////////////////////////////////////////////////////////////

// ZET CPU Wrapper

// ZET Master to Wishbone adapter wires
logic [15:0] wb_zet_cpu_wrapper_dat_i;
logic [15:0] wb_zet_cpu_wrapper_dat_o;
logic [20:1] wb_zet_cpu_wrapper_adr_o;
logic [ 1:0] wb_zet_cpu_wrapper_sel_o;
logic        wb_zet_cpu_wrapper_we_o;
logic        wb_zet_cpu_wrapper_cyc_o;
logic        wb_zet_cpu_wrapper_stb_o;
logic        wb_zet_cpu_wrapper_ack_i;

zet_cpu_wrapper
    #(.s0_addr_1(21'h0_00000), // mem 0x00000 - 0xfffff
      .s0_mask_1(21'h1_00000), // Base RAM
      .s0_addr_2(21'h1_00000), // io  0x00000 - 0xfffff
      .s0_mask_2(21'h1_00000), // Base io

      .s1_addr_1(21'h0_00000), //
      .s1_mask_1(21'h1_FFFFF), // not used
      .s1_addr_2(21'h1_00000),
      .s1_mask_2(21'h1_00000), // not used

      .sE_addr_1(21'h1_000A0), // io 0x00A0 - 0x00A1
      .sE_mask_1(21'h1_0FFFE), // 8259A Slave Interrupt Controller

      .sF_addr_1(21'h1_00020), // io 0x0020 - 0x0021
      .sF_mask_1(21'h1_0FFFE)  // 8259A Master Interrupt Controller
     ) zet_cpu_wrapper (
      .cpu_clk_i(wb_clk),
      .cpu_rst_i(rst_cpu),
        
      // Slave 0 interface
      .s0_dat_i(wb_zet_cpu_wrapper_dat_i), // input  [15:0] s0_dat_i
      .s0_dat_o(wb_zet_cpu_wrapper_dat_o), // output [15:0] s0_dat_o
      .s0_adr_o(wb_zet_cpu_wrapper_adr_o), // output [20:1] s0_adr_o
      .s0_sel_o(wb_zet_cpu_wrapper_sel_o), // output [ 1:0] s0_sel_o
      .s0_we_o(wb_zet_cpu_wrapper_we_o),   // output        s0_we_o
      .s0_cyc_o(wb_zet_cpu_wrapper_cyc_o), // output        s0_cyc_o
      .s0_stb_o(wb_zet_cpu_wrapper_stb_o), // output        s0_stb_o
      .s0_ack_i(wb_zet_cpu_wrapper_ack_i), // input         s0_ack_i
        
      // Slave 1 interface
      .s1_dat_i(),
      .s1_dat_o(),
      .s1_adr_o(),
      .s1_sel_o(),
      .s1_we_o(),
      .s1_cyc_o(),
      .s1_stb_o(),
      .s1_ack_i(),
    
      // CPU PIC Interrupts
      .pic_intv_i(), // input  [15:0] pic_intv_i
      .pic_nmi_i(),  // input         pic_nmi_i

      // CPU Program Counter
      .cpu_pc_o()    // output [19:0] cpu_pc_o
     );

// Wishbone Adapter

// Unused signals
// wb_m2s_zet_cpu_cti
// wb_m2s_zet_cpu_bte
localparam WB_ADAPTER_ADDR_WIDTH = 32;
localparam WB_ADAPTER_WBM_DATA_WIDTH = 16;
localparam WB_ADAPTER_WBM_SELECT_WIDTH = (WB_ADAPTER_WBM_DATA_WIDTH/8);
localparam WB_ADAPTER_WBS_DATA_WIDTH = 32;
localparam WB_ADAPTER_WBS_SELECT_WIDTH = (WB_ADAPTER_WBS_DATA_WIDTH/8);
wb_adapter
    #(.ADDR_WIDTH(WB_ADAPTER_ADDR_WIDTH),             // width of address bus in bits
      .WBM_DATA_WIDTH(WB_ADAPTER_WBM_DATA_WIDTH),     // width of master data bus in bits (8, 16, 32, or 64)
      .WBM_SELECT_WIDTH(WB_ADAPTER_WBM_SELECT_WIDTH), // width of master word select bus (1, 2, 4, or 8)
      .WBS_DATA_WIDTH(WB_ADAPTER_WBS_DATA_WIDTH),     // width of slave data bus in bits (8, 16, 32, or 64)
      .WBS_SELECT_WIDTH(WB_ADAPTER_WBS_SELECT_WIDTH)  // width of slave word select bus (1, 2, 4, or 8)
    ) wb_adapter (
        .clk(clk),                                    // input wire clk
        .rst(rst_cpu),                                // input wire rst

        // Wishbone master input
        .wbm_adr_i(wb_zet_cpu_wrapper_adr_o),         // input  wire [ADDR_WIDTH-1:0]       wbm_adr_i
        .wbm_dat_i(wb_zet_cpu_wrapper_dat_o),         // input  wire [WBM_DATA_WIDTH-1:0]   wbm_dat_i
        .wbm_dat_o(wb_zet_cpu_wrapper_dat_i),         // output wire [WBM_DATA_WIDTH-1:0]   wbm_dat_o
        .wbm_we_i(wb_zet_cpu_wrapper_we_o),           // input  wire                        wbm_we_i
        .wbm_sel_i(wb_zet_cpu_wrapper_sel_o),         // input  wire [WBM_SELECT_WIDTH-1:0] wbm_sel_i
        .wbm_stb_i(wb_zet_cpu_wrapper_stb_o),         // input  wire                        wbm_stb_i
        .wbm_ack_o(wb_zet_cpu_wrapper_ack_i),         // output wire                        wbm_ack_o
        .wbm_err_o(),                                 // output wire                        wbm_err_o
        .wbm_rty_o(),                                 // output wire                        wbm_rty_o
        .wbm_cyc_i(wb_zet_cpu_wrapper_cyc_o),         // input  wire                        wbm_cyc_i

        // Wishbone slave output
       .wbs_adr_o(wb_m2s_zet_cpu_adr),                // output wire [ADDR_WIDTH-1:0]       wbs_adr_o
       .wbs_dat_i(wb_s2m_zet_cpu_dat),                // input  wire [WBS_DATA_WIDTH-1:0]   wbs_dat_i
       .wbs_dat_o(wb_m2s_zet_cpu_dat),                // output wire [WBS_DATA_WIDTH-1:0]   wbs_dat_o
       .wbs_we_o(wb_m2s_zet_cpu_we),                  // output wire                        wbs_we_o
       .wbs_sel_o(wb_m2s_zet_cpu_sel),                // output wire [WBS_SELECT_WIDTH-1:0] wbs_sel_o
       .wbs_stb_o(wb_m2s_zet_cpu_stb),                // output wire                        wbs_stb_o
       .wbs_ack_i(wb_s2m_zet_cpu_ack),                // input  wire                        wbs_ack_i
       .wbs_err_i(wb_s2m_zet_cpu_err),                // input  wire                        wbs_err_i
       .wbs_rty_i(wb_s2m_zet_cpu_rty),                // input  wire                        wbs_rty_i
       .wbs_cyc_o(wb_m2s_zet_cpu_cyc)                 // output wire                        wbs_cyc_o
    );

////////////////////////////////////////////////////////////////////////
//
// External Memory Interface Connections
//
////////////////////////////////////////////////////////////////////////

assign wb_ext_adr_o = wb_m2s_ext_ram_adr;
assign wb_ext_dat_o = wb_m2s_ext_ram_dat;
assign wb_ext_sel_o = wb_m2s_ext_ram_sel;
assign wb_ext_we_o = wb_m2s_ext_ram_we;
assign wb_ext_cyc_o = wb_m2s_ext_ram_cyc;
assign wb_ext_stb_o = wb_m2s_ext_ram_stb;
assign wb_ext_cti_o = wb_m2s_ext_ram_cti;
assign wb_ext_bte_o = wb_m2s_ext_ram_bte;
assign wb_s2m_ext_ram_dat = wb_ext_dat_i;
assign wb_s2m_ext_ram_ack = wb_ext_ack_i;
assign wb_s2m_ext_ram_err = wb_ext_err_i;
assign wb_s2m_ext_ram_rty = wb_ext_rty_i;

endmodule


