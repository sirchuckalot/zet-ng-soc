/*
 *  ao486 CPU Wishbone Wrapper
 *  Copyright (C) 2019  Charley Picker <charley.picker@yahoo.com>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

module ao486_cpu_wb_wrapper
    #(parameter AW = 32,
      parameter DW = 32)

    (input         cpu_clk_i,
     input         cpu_rst_i,

     // Memory Master Interface
     output [AW-1:0]   wbm_cpu_mem_adr_o,
     output [DW-1:0]   wbm_cpu_mem_dat_o,
     output [DW/8-1:0] wbm_cpu_mem_sel_o,
     output            wbm_cpu_mem_we_o,
     output            wbm_cpu_mem_cyc_o,
     output            wbm_cpu_mem_stb_o,
     output [2:0]      wbm_cpu_mem_cti_o,
     output [1:0]      wbm_cpu_mem_bte_o,
     input [DW-1:0]    wbm_cpu_mem_dat_i,
     input             wbm_cpu_mem_ack_i,
     input             wbm_cpu_mem_err_i,
     input             wbm_cpu_mem_rty_i,

     // IO Master Interface
     output [AW-1:0]   wbm_cpu_io_adr_o,
     output [DW-1:0]   wbm_cpu_io_dat_o,
     output [DW/8-1:0] wbm_cpu_io_sel_o,
     output            wbm_cpu_io_we_o,
     output            wbm_cpu_io_cyc_o,
     output            wbm_cpu_io_stb_o,
     output [2:0]      wbm_cpu_io_cti_o,
     output [1:0]      wbm_cpu_io_bte_o,
     input [DW-1:0]    wbm_cpu_io_dat_i,
     input             wbm_cpu_io_ack_i,
     input             wbm_cpu_io_err_i,
     input             wbm_cpu_io_rty_i,

     // CPU PIC Interrupts
     input               interrupt_do,
     input   [7:0]       interrupt_vector,
     output              interrupt_done
);

// Altera Avalon memory bus
logic [AW-1:0]   avm_address;
logic [DW-1:0]   avm_writedata;
logic [DW/8-1:0] avm_byteenable;
logic [2:0]      avm_burstcount;
logic            avm_write;
logic            avm_read;

logic            avm_waitrequest;
logic            avm_readdatavalid;
logic [DW-1:0]   avm_readdata;

// Altera Avalon io bus
logic [15:0]     avalon_io_address;
logic [3:0]      avalon_io_byteenable;

logic            avalon_io_read;
logic            avalon_io_readdatavalid;
logic [31:0]     avalon_io_readdata;

logic            avalon_io_write;
logic [31:0]     avalon_io_writedata;

logic            avalon_io_waitrequest;

ao486 ao486 (
    .clk(cpu_clk_i),
    .rst_n(!cpu_rst_i),

    // CPU Interrupt Control
    .interrupt_do(interrupt_do),
    .interrupt_vector(interrupt_vector),
    .interrupt_done(interrupt_done),

    // Altera Avalon memory bus
    .avm_address(avm_address),
    .avm_writedata(avm_writedata),
    .avm_byteenable(avm_byteenable),
    .avm_burstcount(avm_burstcount),
    .avm_write(avm_write),
    .avm_read(avm_read),

    .avm_waitrequest(avm_waitrequest),
    .avm_readdatavalid(avm_readdatavalid),
    .avm_readdata(avm_readdata),

    // Altera Avalon io bus
    .avalon_io_address(avalon_io_address),
    .avalon_io_byteenable(avalon_io_byteenable),

    .avalon_io_read(avalon_io_read),
    .avalon_io_readdatavalid(avalon_io_readdatavalid),
    .avalon_io_readdata(avalon_io_readdata),

    .avalon_io_write(avalon_io_write),
    .avalon_io_writedata(avalon_io_writedata),

    .avalon_io_waitrequest(avalon_io_waitrequest)
);

// First connect the memory bridge
avalon_to_wb_bridge #(
    .AW(AW),
    .DW(DW)
) avalon_wb_mem_brg (
    .wb_clk_i(cpu_clk_i),
    .wb_rst_i(cpu_rst_i),

    // Avalon Slave input
    .s_av_address_i(avm_address),
    .s_av_byteenable_i(avm_byteenable),
    .s_av_read_i(avm_read),
    .s_av_readdata_o(avm_readdata),
    .s_av_burstcount_i(avm_burstcount),
    .s_av_write_i(avm_write),
    .s_av_writedata_i(avm_writedata),
    .s_av_waitrequest_o(avm_waitrequest),
    .s_av_readdatavalid_o(avm_readdatavalid),

    // Wishbone Master Output
    .wbm_adr_o(wbm_cpu_mem_adr_o),
    .wbm_dat_o(wbm_cpu_mem_dat_o),
    .wbm_sel_o(wbm_cpu_mem_sel_o),
    .wbm_we_o(wbm_cpu_mem_we_o),
    .wbm_cyc_o(wbm_cpu_mem_cyc_o),
    .wbm_stb_o(wbm_cpu_mem_stb_o),
    .wbm_cti_o(wbm_cpu_mem_cti_o),
    .wbm_bte_o(wbm_cpu_mem_bte_o),
    .wbm_dat_i(wbm_cpu_mem_dat_i),
    .wbm_ack_i(wbm_cpu_mem_ack_i),
    .wbm_err_i(wbm_cpu_mem_err_i),
    .wbm_rty_i(wbm_cpu_mem_rty_i)
);

// Now connect the io bridge
avalon_to_wb_bridge #(
    .AW(AW),
    .DW(DW)
) avalon_wb_io_brg (
    .wb_clk_i(cpu_clk_i),
    .wb_rst_i(cpu_rst_i),
  
    // Avalon Slave input
    .s_av_address_i(avalon_io_address),
    .s_av_byteenable_i(avalon_io_byteenable),
    .s_av_read_i(avalon_io_read),
    .s_av_readdata_o(avalon_io_readdata),
    .s_av_burstcount_i(avalon_io_burstcount),
    .s_av_write_i(avalon_io_write),
    .s_av_writedata_i(avalon_io_writedata),
    .s_av_waitrequest_o(avalon_io_waitrequest),
    .s_av_readdatavalid_o(avalon_io_readdatavalid),
    
    // Wishbone Master Output
    .wbm_adr_o(wbm_cpu_io_adr_o),
    .wbm_dat_o(wbm_cpu_io_dat_o),
    .wbm_sel_o(wbm_cpu_io_sel_o),
    .wbm_we_o(wbm_cpu_io_we_o),
    .wbm_cyc_o(wbm_cpu_io_cyc_o),
    .wbm_stb_o(wbm_cpu_io_stb_o),
    .wbm_cti_o(wbm_cpu_io_cti_o),
    .wbm_bte_o(wbm_cpu_io_bte_o),
    .wbm_dat_i(wbm_cpu_io_dat_i),
    .wbm_ack_i(wbm_cpu_io_ack_i),
    .wbm_err_i(wbm_cpu_io_err_i),
    .wbm_rty_i(wbm_cpu_io_rty_i)
);        

endmodule


