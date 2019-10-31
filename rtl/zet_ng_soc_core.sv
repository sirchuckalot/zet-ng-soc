
    
/****************************************************************************
 * zet_ng_soc_core.sv
 ****************************************************************************/
  
/**
 * Module: zet_ng_soc_core
 * 
 * TODO: Add module documentation
 */

module zet_ng_soc_core
    import dii_package::dii_flit;
    #(
        parameter ID       = 'x,
        parameter DEBUG_BASEID = 'x,
        parameter DEBUG_ROUTER_BUFFER_SIZE = 'x,
        parameter DEBUG_MAX_PKT_LEN,
        parameter USE_DEBUG = 'x,
        
        parameter MEM_SIZE = 128*1024*1024,
        parameter MEM_ADDR_WIDTH = $clog2(MEM_SIZE),
        parameter MEM_FILE = 'x
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

// Local debug subnet module mapping
// id_map [0] = MAM

// For testing, we immediately route MAM requests to external memory
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
    
    .stb_o(wb_ext_stb_o),
    .cyc_o(wb_ext_cyc_o),
    .ack_i(wb_ext_ack_i),
    .we_o(wb_ext_we_o),
    .addr_o(wb_ext_adr_o),
    .dat_o(wb_ext_dat_o),
    .dat_i(wb_ext_dat_i),
    .cti_o(wb_ext_cti_o),
    .bte_o(wb_ext_bte_o),
    .sel_o(wb_ext_sel_o));

endmodule


