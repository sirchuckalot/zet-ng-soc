    
/****************************************************************************
 * top_zet_simple.sv
 ****************************************************************************/

/**
 * Module: top_zet_simple
 * 
 * This is a basic system that has:
 *  Simple Wishbone Interconnect
 *  ZET Processor Core
 *  Simple 16650 UART for outputting messages
 * 
 */

module top_zet_simple
    #(
        parameter CPU_MEM_ADDR_WIDTH_SPACE = 20,
        parameter EXT_MEM_ADDR_WIDTH = 32,
        parameter EXT_MEM_DATA_WIDTH = 32
    )
    (    
        input                               wb_ext_clk_i,
        input                               wb_ext_rst_i,

        // Wishbone external memory interface
        output [EXT_MEM_ADDR_WIDTH-1:0]     wb_ext_adr_o,
        output                              wb_ext_cyc_o,
        output [EXT_MEM_DATA_WIDTH-1:0]     wb_ext_dat_o,
        output [(EXT_MEM_DATA_WIDTH/8)-1:0] wb_ext_sel_o,
        output                              wb_ext_stb_o,
        output                              wb_ext_we_o,
        output                              wb_ext_cab_o,
        output [2:0]                        wb_ext_cti_o,
        output [1:0]                        wb_ext_bte_o,
        input                               wb_ext_ack_i,
        input                               wb_ext_rty_i,
        input                               wb_ext_err_i,
        input [EXT_MEM_DATA_WIDTH-1:0]      wb_ext_dat_i,
        
        // CPU Program Counter
        output cpu_pc,
    
        // Simple UART input/output
        output uart_int_o,
        output uart_tx_o,
        input uart_rx_i
    
    );

////////////////////////////////////////////////////////////////////////
//
// Wishbone interconnect
//
////////////////////////////////////////////////////////////////////////

wire wb_clk = wb_ext_clk_i;
wire wb_rst = wb_ext_rst_i;

`include "wb_intercon.vh"
    
////////////////////////////////////////////////////////////////////////
//
// ZET Processor Core
//
////////////////////////////////////////////////////////////////////////

/**
 * CPU_MEM_ADDR_WIDTH = 20 bits to address full 1MB of memory
 * MSB + 1 or bit 21 will be used to translate into memory mapped io
 * WB_IO_BIT = (CPU_MEM_ADDR_WIDTH + 1) - 1 = 20
 */
//localparam WB_IO_BIT = (CPU_MEM_ADDR_WIDTH + 1) - 1;
//assign wb_m2s_zet_cpu_adr[WB_IO_BIT] = wb_m2s_zet_cpu_tga;


// This is the correct 20 bit cpu address to 32 bit wishbone address translation
logic [19:1] wb_cpu_adr; // 16 bit data addressing
logic        wb_m2s_zet_cpu_tga; // cpu io_mem select
assign       wb_m2s_zet_cpu_adr = {11'b0, wb_m2s_zet_cpu_tga, wb_cpu_adr, 1'b0};

// This is our cpu program counter
logic [19:0] cpu_pc;

// At the moment, cpu interrupts are not supported
logic cpu_intr = 0;
logic cpu_inta;
logic cpu_nmi = 0;
logic cpu_nmia;

// Unused cpu signals
assign unused_wb_m2s_zet_cpu_cti = 3'b0;
logic unused_wb_s2m_zet_cpu_err = wb_s2m_zet_cpu_err;
logic unused_wb_s2m_zet_cpu_rty = wb_s2m_zet_cpu_rty;

zet zet0
    (// Wishbone master interface
     .wb_clk_i(wb_clk),
     .wb_rst_i(wb_rst),
     .wb_dat_i(wb_s2m_zet_cpu_dat), // input  [15:0] wb_dat_i
     .wb_dat_o(wb_m2s_zet_cpu_dat), // output [15:0] wb_dat_o
     .wb_adr_o(wb_cpu_adr),         // output [19:1] wb_adr_o
     .wb_we_o(wb_m2s_zet_cpu_we),
     .wb_tga_o(wb_m2s_zet_cpu_tga), // io/mem
     .wb_sel_o(wb_m2s_zet_cpu_sel), // output [ 1:0] wb_sel_o
     .wb_stb_o(wb_m2s_zet_cpu_stb),
     .wb_cyc_o(wb_m2s_zet_cpu_cyc),
     .wb_ack_i(wb_s2m_zet_cpu_ack),
     .wb_tgc_i(cpu_intr),  // intr
     .wb_tgc_o(cpu_inta),  // inta
     .nmi(cpu_nmi),
     .nmia(cpu_nmia),

     .pc(cpu_pc)  // for debugging purposes
    );
////////////////////////////////////////////////////////////////////////
//
// Wihsbone 16650 UART Core
//
////////////////////////////////////////////////////////////////////////

uart_top
    #(
        parameter SIM = 0,
        parameter debug = 0
    )
    (
        wb_clk_i, 
    
        // Wishbone signals
        wb_rst_i,
        wb_adr_i,
        wb_dat_i,
        wb_dat_o,
        wb_we_i,
        wb_stb_i,
        wb_cyc_i,
        wb_ack_o,
        wb_sel_i,
    
        int_o(uart_int_o), // interrupt request

        // UART signals
        // serial input/output
        stx_pad_o(uart_tx_o), srx_pad_i(uart_rx_i),

        // modem signals
        rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
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
