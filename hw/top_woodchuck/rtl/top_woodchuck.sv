
    
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

/* verilator lint_off UNUSED */
logic [1:0] osd_mam_unused_ok;
assign osd_mam_unused_ok = {
    wb_s2m_osd_mam_err,
    wb_s2m_osd_mam_rty};
/* verilator lint_on UNUSED */

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
// ao486 CPU Wrapper
//
////////////////////////////////////////////////////////////////////////

ao486_cpu_wb_wrapper #(
    .AW(32),
    .DW(32)
) ao486 (
    .cpu_clk_i(clk),
    .cpu_rst_i(rst_cpu),

     // Memory Master Interface
    .wbm_cpu_mem_adr_o(wb_m2s_ao486_cpu_mem_adr),
    .wbm_cpu_mem_dat_o(wb_m2s_ao486_cpu_mem_dat),
    .wbm_cpu_mem_sel_o(wb_m2s_ao486_cpu_mem_sel),
    .wbm_cpu_mem_we_o(wb_m2s_ao486_cpu_mem_we),
    .wbm_cpu_mem_cyc_o(wb_m2s_ao486_cpu_mem_cyc),
    .wbm_cpu_mem_stb_o(wb_m2s_ao486_cpu_mem_stb),
    .wbm_cpu_mem_cti_o(wb_m2s_ao486_cpu_mem_cti),
    .wbm_cpu_mem_bte_o(wb_m2s_ao486_cpu_mem_bte),
    .wbm_cpu_mem_dat_i(wb_s2m_ao486_cpu_mem_dat),
    .wbm_cpu_mem_ack_i(wb_s2m_ao486_cpu_mem_ack),
    .wbm_cpu_mem_err_i(wb_s2m_ao486_cpu_mem_err),
    .wbm_cpu_mem_rty_i(wb_s2m_ao486_cpu_mem_rty),

    // IO Master Interface
    .wbm_cpu_io_adr_o(wb_m2s_ao486_cpu_io_adr),
    .wbm_cpu_io_dat_o(wb_m2s_ao486_cpu_io_dat),
    .wbm_cpu_io_sel_o(wb_m2s_ao486_cpu_io_sel),
    .wbm_cpu_io_we_o(wb_m2s_ao486_cpu_io_we),
    .wbm_cpu_io_cyc_o(wb_m2s_ao486_cpu_io_cyc),
    .wbm_cpu_io_stb_o(wb_m2s_ao486_cpu_io_stb),
    .wbm_cpu_io_cti_o(wb_m2s_ao486_cpu_io_cti),
    .wbm_cpu_io_bte_o(wb_m2s_ao486_cpu_io_bte),
    .wbm_cpu_io_dat_i(wb_s2m_ao486_cpu_io_dat),
    .wbm_cpu_io_ack_i(wb_s2m_ao486_cpu_io_ack),
    .wbm_cpu_io_err_i(wb_s2m_ao486_cpu_io_err),
    .wbm_cpu_io_rty_i(wb_s2m_ao486_cpu_io_rty),

    // CPU PIC Interrupts
    .interrupt_do(),
    .interrupt_vector(),
    .interrupt_done()
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


