
    
/****************************************************************************
 * zet_ng_soc_core_tb.sv
 ****************************************************************************/

/**
 * Module: top_woodchuck_verilator
 * 
 * TODO: Add module documentation
 */

`default_nettype none
module top_woodchuck_verilator(
`ifdef VERILATOR
    input clk,
    input rst
`endif
);

import dii_package::dii_flit;

// Simulation parameters
parameter USE_DEBUG = 1;

// Debug parameters
parameter SYSTEM_VENDOR_ID = 2;
parameter SYSTEM_DEVICE_ID = 1;
parameter DEBUG_NUM_MODS = 2;
parameter DEBUG_SUBNET_BITS = 6;
parameter DEBUG_LOCAL_SUBNET = 0;
parameter DEBUG_MAX_PKT_LEN = 12;
parameter DEBUG_ROUTER_BUFFER_SIZE = 4;

// Memory parameters
parameter MEM_FILE = "";
parameter MEM_SIZE = 128*1024*1024; // 128MB equals 134217728 in bytes
//parameter MEM_ADDR_WIDTH = $clog2(MEM_SIZE);
parameter MEM_ADDR_WIDTH = 32;

logic rst_sys, rst_cpu;
    
`ifndef VERILATOR
    reg clk;
    reg rst;
`endif

// Reset signals
// In simulations with debug system, these signals can be triggered through
// the host software. In simulations without debug systems, we only rely on
// the global reset signal.
generate
    if (USE_DEBUG == 0) begin
        assign rst_sys = rst;
        assign rst_cpu = rst;
    end 
endgenerate

// OSD-based debug system
dii_flit [1:0] debug_ring_in;
dii_flit [1:0] debug_ring_out;
logic [1:0] debug_ring_in_ready;
logic [1:0] debug_ring_out_ready;

generate
    if (USE_DEBUG == 1) begin
        glip_channel c_glip_in(.*);
        glip_channel c_glip_out(.*);
        
        /* verilator lint_off UNUSED */
        logic com_rst, logic_rst;
        /* verilator lint_on UNUSED */

        // TCP communication interface (simulation only)
        glip_tcp_toplevel
            u_glip(
                // Inputs
                .clk_io    (clk),
                .clk_logic (clk),
                .rst(rst),
                
                // Input/Output
                .fifo_in   (c_glip_in),
                .fifo_out  (c_glip_out),
                
                // Outputs
                .logic_rst(logic_rst),
                .com_rst(com_rst)
            );

            // System Interface
        debug_interface
            #(
                .SYSTEM_VENDOR_ID   (SYSTEM_VENDOR_ID),
                .SYSTEM_DEVICE_ID   (SYSTEM_DEVICE_ID),
                .NUM_MODULES (DEBUG_NUM_MODS),
                .SUBNET_BITS (DEBUG_SUBNET_BITS),
                .LOCAL_SUBNET (DEBUG_LOCAL_SUBNET),
                .MAX_PKT_LEN (DEBUG_MAX_PKT_LEN),
                .DEBUG_ROUTER_BUFFER_SIZE (DEBUG_ROUTER_BUFFER_SIZE)
            )
            u_debuginterface(
                .clk           (clk),
                .rst           (rst),

                .sys_rst       (rst_sys),
                .cpu_rst       (rst_cpu),

                .glip_in       (c_glip_in),
                .glip_out      (c_glip_out),

                .ring_out       (debug_ring_in),
                .ring_out_ready (debug_ring_in_ready),
                .ring_in        (debug_ring_out),
                .ring_in_ready  (debug_ring_out_ready)
            );
    end
endgenerate

// Wishbone B3 interface wires for connecting generic memory interface
logic        wb_mem_clk_o;
logic        wb_mem_rst_o;
logic [MEM_ADDR_WIDTH-1:0] wb_mem_adr_o;
logic        wb_mem_cyc_o;
logic [31:0] wb_mem_dat_o;
logic [3:0]  wb_mem_sel_o;
logic        wb_mem_stb_o;
logic        wb_mem_we_o;
/* verilator lint_off UNUSED */
logic        wb_mem_cab_o;
/* verilator lint_on UNUSED */
logic [2:0]  wb_mem_cti_o;
logic [1:0]  wb_mem_bte_o;
logic        wb_mem_ack_i;
/* verilator lint_off UNDRIVEN */
logic        wb_mem_rty_i;
/* verilator lint_on UNDRIVEN */
logic        wb_mem_err_i;
logic [31:0] wb_mem_dat_i;

// The actual system: ZET Next Generation System on Chip
top_woodchuck
    #(.ID(0),
      .DEBUG_BASEID((DEBUG_LOCAL_SUBNET << (16 - DEBUG_SUBNET_BITS)) + 1),
      .DEBUG_ROUTER_BUFFER_SIZE(DEBUG_ROUTER_BUFFER_SIZE),
      .DEBUG_MAX_PKT_LEN(DEBUG_MAX_PKT_LEN),
      .USE_DEBUG(USE_DEBUG),
      .MEM_SIZE(MEM_SIZE),
      .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
      .MEM_FILE(MEM_FILE)
      )
    top_woodchuck(
        // Debug ring ports
        .debug_ring_in(debug_ring_in),
        .debug_ring_in_ready(debug_ring_in_ready),
        .debug_ring_out(debug_ring_out),
        .debug_ring_out_ready(debug_ring_out_ready),
    
        // Inputs
        .clk               (clk),
        .rst_cpu           (rst_cpu),
        .rst_sys           (rst_sys),
        .rst_dbg           (rst),
        
        // External bus Master
        .wb_ext_adr_o(wb_mem_adr_o),
        .wb_ext_cyc_o(wb_mem_cyc_o),
        .wb_ext_dat_o(wb_mem_dat_o),
        .wb_ext_sel_o(wb_mem_sel_o),
        .wb_ext_stb_o(wb_mem_stb_o),
        .wb_ext_we_o(wb_mem_we_o),
        .wb_ext_cab_o(wb_mem_cab_o),
        .wb_ext_cti_o(wb_mem_cti_o),
        .wb_ext_bte_o(wb_mem_bte_o),
        .wb_ext_ack_i(wb_mem_ack_i),
        .wb_ext_rty_i(wb_mem_rty_i),
        .wb_ext_err_i(wb_mem_err_i),
        .wb_ext_dat_i(wb_mem_dat_i)
        );
    
// Simple wishbone memory that is currently hard coded to use 32 bits and
// has a Wishbone B3 interface for burst accesses.
assign wb_mem_clk_o = clk;
assign wb_mem_rst_o = rst_sys;

wb_ram
    #(.depth (MEM_SIZE),
      .memfile(MEM_FILE),
      .aw(MEM_ADDR_WIDTH))
wb_ram
    (// Wishbone interface
     .wb_clk_i (wb_mem_clk_o),
     .wb_rst_i (wb_mem_rst_o),
     .wb_adr_i (wb_mem_adr_o),
     .wb_stb_i (wb_mem_stb_o),
     .wb_cyc_i (wb_mem_cyc_o),
     .wb_cti_i (wb_mem_cti_o),
     .wb_bte_i (wb_mem_bte_o),
     .wb_we_i  (wb_mem_we_o) ,
     .wb_sel_i (wb_mem_sel_o),
     .wb_dat_i (wb_mem_dat_o),
     .wb_dat_o (wb_mem_dat_i),
     .wb_ack_o (wb_mem_ack_i),
     .wb_err_o (wb_mem_err_i));
    
// When not using Verilator, we need this to support capturing vcd signals
`ifndef VERILATOR
    vlog_tb_utils vtu();
`endif

// Generate testbench signals.
// In Verilator, these signals are generated in the C++ toplevel testbench
`ifndef VERILATOR
    initial begin
        clk = 1'b0;
        rst = 1'b1;
    end

    always #20 clk <= !clk;
    initial #100 rst <= 1'b0;
`endif

endmodule

// Local Variables:
// verilog-library-directories:("." "../../../../src/rtl/*/verilog")
// verilog-auto-inst-param-value: t
// End:

