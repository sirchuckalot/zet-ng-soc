/*
 *  v586 CPU Wishbone Wrapper
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

module v586_cpu_wb_wrapper
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
     input             interrupt_do,
     input  [7:0]      interrupt_vector,
     output            interrupt_done,
     
     output [4:0]      debug_o
);

// Full AXI4 to AXI4 lite memory bridge
wire m00_AXI_RSTN;
wire m00_AXI_CLK;
wire [31:0] m00_AXI_AWADDR;
wire m00_AXI_AWVALID;
wire m00_AXI_AWREADY;
wire [1:0] m00_AXI_AWBURST;
wire [7:0] m00_AXI_AWLEN;
wire [2:0] m00_AXI_AWSIZE;
wire [31:0] m00_AXI_ARADDR;
wire m00_AXI_ARVALID;
wire m00_AXI_ARREADY;
wire [1:0] m00_AXI_ARBURST;
wire [7:0] m00_AXI_ARLEN;
wire [2:0] m00_AXI_ARSIZE;
wire [31:0] m00_AXI_WDATA;
wire m00_AXI_WVALID;
wire m00_AXI_WREADY;
wire [3:0] m00_AXI_WSTRB;
wire m00_AXI_WLAST;
wire [31:0] m00_AXI_RDATA;
wire m00_AXI_RVALID;
wire m00_AXI_RREADY;
wire m00_AXI_RLAST;
wire m00_AXI_BVALID;
wire m00_AXI_BREADY;

// Full AXI4 to AXI4 lite io bridge
wire [31:0] m01_AXI_AWADDR;
wire m01_AXI_AWVALID;
wire m01_AXI_AWREADY;
wire [1:0] m01_AXI_AWBURST;
wire [7:0] m01_AXI_AWLEN;
wire [2:0] m01_AXI_AWSIZE;
wire [31:0] m01_AXI_ARADDR;
wire m01_AXI_ARVALID;
wire m01_AXI_ARREADY;
wire [1:0] m01_AXI_ARBURST;
wire [7:0] m01_AXI_ARLEN;
wire [2:0] m01_AXI_ARSIZE;
wire [31:0] m01_AXI_WDATA;
wire m01_AXI_WVALID;
wire m01_AXI_WREADY;
wire [3:0] m01_AXI_WSTRB;
wire m01_AXI_WLAST;
wire [31:0] m01_AXI_RDATA;
wire m01_AXI_RVALID;
wire m01_AXI_RREADY;
wire m01_AXI_RLAST;
wire m01_AXI_BVALID;
wire m01_AXI_BREADY;

v586 v586 (
    .m00_AXI_RSTN(!cpu_rst_i), // Change polarity!!
    .m00_AXI_CLK(cpu_clk_i),
        
    .m00_AXI_AWADDR(m00_AXI_AWADDR),
    .m00_AXI_AWVALID(m00_AXI_AWVALID),
    .m00_AXI_AWREADY(m00_AXI_AWREADY),
    .m00_AXI_AWBURST(m00_AXI_AWBURST),
    .m00_AXI_AWLEN(m00_AXI_AWLEN),
    .m00_AXI_AWSIZE(m00_AXI_AWSIZE),
    .m00_AXI_ARADDR(m00_AXI_ARADDR), 
    .m00_AXI_ARVALID(m00_AXI_ARVALID), 
    .m00_AXI_ARREADY(m00_AXI_ARREADY), 
    .m00_AXI_ARBURST(m00_AXI_ARBURST), 
    .m00_AXI_ARLEN(m00_AXI_ARLEN), 
    .m00_AXI_ARSIZE(m00_AXI_ARSIZE), 
    .m00_AXI_WDATA(m00_AXI_WDATA), 
    .m00_AXI_WVALID(m00_AXI_WVALID), 
    .m00_AXI_WREADY(m00_AXI_WREADY),
    .m00_AXI_WSTRB(m00_AXI_WSTRB), 
    .m00_AXI_WLAST(m00_AXI_WLAST), 
    .m00_AXI_RDATA(m00_AXI_RDATA), 
    .m00_AXI_RVALID(m00_AXI_RVALID), 
    .m00_AXI_RREADY(m00_AXI_RREADY), 
    .m00_AXI_RLAST(m00_AXI_RLAST), 
    .m00_AXI_BVALID(m00_AXI_BVALID), 
    .m00_AXI_BREADY(m00_AXI_BREADY),
        
        
    .m01_AXI_AWADDR(m01_AXI_AWADDR),
    .m01_AXI_AWVALID(m01_AXI_AWVALID), 
    .m01_AXI_AWREADY(m01_AXI_AWREADY), 
    .m01_AXI_AWBURST(m01_AXI_AWBURST), 
    .m01_AXI_AWLEN(m01_AXI_AWLEN), 
    .m01_AXI_AWSIZE(m01_AXI_AWSIZE), 
    .m01_AXI_ARADDR(m01_AXI_ARADDR), 
    .m01_AXI_ARVALID(m01_AXI_ARVALID), 
    .m01_AXI_ARREADY(m01_AXI_ARREADY), 
    .m01_AXI_ARBURST(m01_AXI_ARBURST), 
    .m01_AXI_ARLEN(m01_AXI_ARLEN), 
    .m01_AXI_ARSIZE(m01_AXI_ARSIZE), 
    .m01_AXI_WDATA(m01_AXI_WDATA),
    .m01_AXI_WVALID(m01_AXI_WVALID), 
    .m01_AXI_WREADY(m01_AXI_WREADY), 
    .m01_AXI_WSTRB(m01_AXI_WSTRB), 
    .m01_AXI_WLAST(m01_AXI_WLAST), 
    .m01_AXI_RDATA(m01_AXI_RDATA),
    .m01_AXI_RVALID(m01_AXI_RVALID), 
    .m01_AXI_RREADY(m01_AXI_RREADY), 
    .m01_AXI_RLAST(m01_AXI_RLAST), 
    .m01_AXI_BVALID(m01_AXI_BVALID),
    .m01_AXI_BREADY(m01_AXI_BREADY),
        
    .int_pic(interrupt_do), 
    .iack(interrupt_done), 
    .ivect(interrupt_vector),

    .debug(debug_o)
);

// Memory AXI4 lite to Wishbone classic
wire [AW-1:0]     M_MEM_AXI_AWADDR;
wire [2 : 0]      M_MEM_AXI_AWPROT;
wire              M_MEM_AXI_AWVALID;
wire              M_MEM_AXI_AWREADY;
wire [DW-1:0]     M_MEM_AXI_WDATA;
wire [(DW/8)-1:0] M_MEM_AXI_WSTRB;
wire              M_MEM_AXI_WVALID;
wire              M_MEM_AXI_WREADY;
wire [1 : 0]      M_MEM_AXI_BRESP;
wire              M_MEM_AXI_BVALID;
wire              M_MEM_AXI_BREADY;
    //
wire [AW-1:0]     M_MEM_AXI_ARADDR;
wire [2:0]        M_MEM_AXI_ARPROT;
wire              M_MEM_AXI_ARVALID;
wire              M_MEM_AXI_ARREADY;
    //
wire              M_MEM_AXI_RVALID;
wire              M_MEM_AXI_RREADY;
wire [DW-1 : 0]   M_MEM_AXI_RDATA;
wire [1 : 0]      M_MEM_AXI_RRESP;
    
// Memory AXI4 to Wishbone Bridge
axi2axilite #(
    .C_AXI_ID_WIDTH(2),
    .C_AXI_DATA_WIDTH(DW),
    .C_AXI_ADDR_WIDTH(AW),
    .OPT_WRITES(1),
    .OPT_READS(1),
    // Log (based two) of the maximum number of outstanding AXI
    // (not AXI-lite) transactions.  If you multiply 2^LGFIFO * 256,
    // you'll get the maximum number of outstanding AXI-lite transactions
    .LGFIFO(4)
) axi2axilite_mem (
    .S_AXI_ACLK(cpu_clk_i),
    .S_AXI_ARESETN(!cpu_rst_i), // Change polarity!!
        //
    .S_AXI_AWVALID(m00_AXI_AWVALID),
    .S_AXI_AWREADY(m00_AXI_AWREADY),
    .S_AXI_AWID(2'b0),
    .S_AXI_AWADDR(m00_AXI_AWADDR),
    .S_AXI_AWLEN(m00_AXI_AWLEN),
    .S_AXI_AWSIZE(m00_AXI_AWSIZE),
    .S_AXI_AWBURST(m00_AXI_AWBURST),
    .S_AXI_AWLOCK(1'b0),
    .S_AXI_AWCACHE(4'b0),
    .S_AXI_AWPROT(3'b0),
    .S_AXI_AWQOS(4'b0),
        //
    .S_AXI_WVALID(m00_AXI_WVALID),
    .S_AXI_WREADY(m00_AXI_WREADY),
    .S_AXI_WDATA(m00_AXI_WDATA),
    .S_AXI_WSTRB(m00_AXI_WSTRB),
    .S_AXI_WLAST(m00_AXI_WLAST),
        //
    .S_AXI_BVALID(m00_AXI_BVALID),
    .S_AXI_BREADY(m00_AXI_BREADY),
    .S_AXI_BID(),
    .S_AXI_BRESP(),
        //
        //
    .S_AXI_ARVALID(m00_AXI_ARVALID),
    .S_AXI_ARREADY(m00_AXI_ARREADY),
    .S_AXI_ARID(2'b0),
    .S_AXI_ARADDR(m00_AXI_ARADDR),
    .S_AXI_ARLEN(m00_AXI_ARLEN),
    .S_AXI_ARSIZE(m00_AXI_ARSIZE),
    .S_AXI_ARBURST(m00_AXI_ARBURST),
    .S_AXI_ARLOCK(1'b0),
    .S_AXI_ARCACHE(4'b0),
    .S_AXI_ARPROT(3'b0),
    .S_AXI_ARQOS(4'b0),
        //
    .S_AXI_RVALID(m00_AXI_RVALID),
    .S_AXI_RREADY(m00_AXI_RREADY),
    .S_AXI_RID(),
    .S_AXI_RDATA(m00_AXI_RDATA),
    .S_AXI_RRESP(),
    .S_AXI_RLAST(m00_AXI_RLAST),
        //
        //
        //
        // Write address (issued by master, acceped by Slave)
    .M_AXI_AWADDR(M_MEM_AXI_AWADDR),
    .M_AXI_AWPROT(M_MEM_AXI_AWPROT),
    .M_AXI_AWVALID(M_MEM_AXI_AWVALID),
    .M_AXI_AWREADY(M_MEM_AXI_AWREADY),
    .M_AXI_WDATA(M_MEM_AXI_WDATA),
    .M_AXI_WSTRB(M_MEM_AXI_WSTRB),
    .M_AXI_WVALID(M_MEM_AXI_WVALID),
    .M_AXI_WREADY(M_MEM_AXI_WREADY),
    .M_AXI_BRESP(M_MEM_AXI_BRESP),
    .M_AXI_BVALID(M_MEM_AXI_BVALID),
    .M_AXI_BREADY(M_MEM_AXI_BREADY),
        //
    .M_AXI_ARADDR(M_MEM_AXI_ARADDR),
    .M_AXI_ARPROT(M_MEM_AXI_ARPROT),
    .M_AXI_ARVALID(M_MEM_AXI_ARVALID),
    .M_AXI_ARREADY(M_MEM_AXI_ARREADY),
        //
    .M_AXI_RVALID(M_MEM_AXI_RVALID),
    .M_AXI_RREADY(M_MEM_AXI_RREADY),
    .M_AXI_RDATA(M_MEM_AXI_RDATA),
    .M_AXI_RRESP(M_MEM_AXI_RRESP)
);

// Wishbone pipelined to wishbone classic
wire              o_mem_wb_reset;
wire              o_mem_wb_cyc;
wire              o_mem_wb_stb;
wire              o_mem_wb_we;
wire [(AW-3):0]   o_mem_wb_addr;
wire [(DW-1):0]   o_mem_wb_data;
wire [(DW/8-1):0] o_mem_wb_sel;
wire              i_mem_wb_ack;
wire              i_mem_wb_stall;
wire [(DW-1):0]   i_mem_wb_data;
wire              i_mem_wb_err;

axlite2wbsp #(
    .C_AXI_DATA_WIDTH(DW), // Width of the AXI R&W data
    .C_AXI_ADDR_WIDTH(AW), // AXI Address width
    .LGFIFO(4),
    .F_MAXSTALL(3),
    .F_MAXDELAY(3),
    .OPT_READONLY(1'b0),
    .OPT_WRITEONLY(1'b0)
) axlite2wbsp_mem (
    .i_clk(cpu_clk_i),
    .i_axi_reset_n(!cpu_rst_i), // Change polarity!!
        //
    .o_axi_awready(M_MEM_AXI_AWREADY), 
    .i_axi_awaddr(M_MEM_AXI_AWADDR), 
    .i_axi_awcache(4'b0), 
    .i_axi_awprot(3'b0),
    .i_axi_awvalid(M_MEM_AXI_AWVALID),
        //
    .o_axi_wready(M_MEM_AXI_WREADY), 
    .i_axi_wdata(M_MEM_AXI_WDATA), 
    .i_axi_wstrb(M_MEM_AXI_WSTRB), 
    .i_axi_wvalid(M_MEM_AXI_WVALID),
        //
    .o_axi_bresp(M_MEM_AXI_BRESP), 
    .o_axi_bvalid(M_MEM_AXI_BVALID), 
    .i_axi_bready(M_MEM_AXI_BREADY),
       //
    .o_axi_arready(M_MEM_AXI_ARREADY), 
    .i_axi_araddr(M_MEM_AXI_ARADDR), 
    .i_axi_arcache(4'b0), 
    .i_axi_arprot(3'b0), 
    .i_axi_arvalid(M_MEM_AXI_ARVALID),
        //
    .o_axi_rresp(M_MEM_AXI_RRESP), 
    .o_axi_rvalid(M_MEM_AXI_RVALID), 
    .o_axi_rdata(M_MEM_AXI_RDATA), 
    .i_axi_rready(M_MEM_AXI_RREADY),
        //
        // Wishbone interface
    .o_reset(o_mem_wb_reset), 
    .o_wb_cyc(o_mem_wb_cyc), 
    .o_wb_stb(o_mem_wb_stb), 
    .o_wb_we(o_mem_wb_we), 
    .o_wb_addr(o_mem_wb_addr), 
    .o_wb_data(o_mem_wb_data), 
    .o_wb_sel(o_mem_wb_sel),
    .i_wb_ack(i_mem_wb_ack), 
    .i_wb_stall(i_mem_wb_stall), 
    .i_wb_data(i_mem_wb_data), 
    .i_wb_err(i_mem_wb_err)
);

// Memory Wishbone pipelined to classic bridge
wbp2classic #(
    .AW(AW),
    .DW(DW)
) wbp2classic_mem (
    .i_clk(cpu_clk_i), 
    .i_reset(o_mem_wb_reset),
    .i_mcyc(o_mem_wb_cyc), 
    .i_mstb(o_mem_wb_stb), 
    .i_mwe(o_mem_wb_we), 
    .i_maddr(o_mem_wb_addr), 
    .i_mdata(o_mem_wb_data), 
    .i_msel(o_mem_wb_sel),
    .o_mstall(i_mem_wb_stall), 
    .o_mack(i_mem_wb_ack), 
    .o_mdata(i_mem_wb_data), 
    .o_merr(i_mem_wb_err),
    
    .o_scyc(wbm_cpu_mem_cyc_o), 
    .o_sstb(wbm_cpu_mem_stb_o), 
    .o_swe(wbm_cpu_mem_we_o), 
    .o_saddr(wbm_cpu_mem_adr_o), 
    .o_sdata(wbm_cpu_mem_dat_o), 
    .o_ssel(wbm_cpu_mem_sel_o),
    .i_sack(wbm_cpu_mem_ack_i), 
    .i_sdata(wbm_cpu_mem_dat_i), 
    .i_serr(wbm_cpu_mem_err_i),
    .o_scti(wbm_cpu_mem_cti_o), 
    .o_sbte(wbm_cpu_mem_bte_o)
);

/***********************************************************************/
// IO AXI4 lite to Wishbone classic
wire [AW-1:0]     M_IO_AXI_AWADDR;
wire [2 : 0]      M_IO_AXI_AWPROT;
wire              M_IO_AXI_AWVALID;
wire              M_IO_AXI_AWREADY;
wire [DW-1:0]     M_IO_AXI_WDATA;
wire [(DW/8)-1:0] M_IO_AXI_WSTRB;
wire              M_IO_AXI_WVALID;
wire              M_IO_AXI_WREADY;
wire [1 : 0]      M_IO_AXI_BRESP;
wire              M_IO_AXI_BVALID;
wire              M_IO_AXI_BREADY;
//
wire [AW-1:0]     M_IO_AXI_ARADDR;
wire [2:0]        M_IO_AXI_ARPROT;
wire              M_IO_AXI_ARVALID;
wire              M_IO_AXI_ARREADY;
//
wire              M_IO_AXI_RVALID;
wire              M_IO_AXI_RREADY;
wire [DW-1 : 0]   M_IO_AXI_RDATA;
wire [1 : 0]      M_IO_AXI_RRESP;
    
// Memory AXI4 to Wishbone Bridge
axi2axilite #(
        .C_AXI_ID_WIDTH(2),
        .C_AXI_DATA_WIDTH(DW),
        .C_AXI_ADDR_WIDTH(AW),
        .OPT_WRITES(1),
        .OPT_READS(1),
        // Log (based two) of the maximum number of outstanding AXI
        // (not AXI-lite) transactions.  If you multiply 2^LGFIFO * 256,
        // you'll get the maximum number of outstanding AXI-lite transactions
        .LGFIFO(4)
    ) axi2axilite_io (
        .S_AXI_ACLK(cpu_clk_i),
        .S_AXI_ARESETN(!cpu_rst_i), // Change polarity!!
        //
        .S_AXI_AWVALID(m01_AXI_AWVALID),
        .S_AXI_AWREADY(m01_AXI_AWREADY),
        .S_AXI_AWID(2'b0),
        .S_AXI_AWADDR(m01_AXI_AWADDR),
        .S_AXI_AWLEN(m01_AXI_AWLEN),
        .S_AXI_AWSIZE(m01_AXI_AWSIZE),
        .S_AXI_AWBURST(m01_AXI_AWBURST),
        .S_AXI_AWLOCK(1'b0),
        .S_AXI_AWCACHE(4'b0),
        .S_AXI_AWPROT(3'b0),
        .S_AXI_AWQOS(4'b0),
        //
        .S_AXI_WVALID(m01_AXI_WVALID),
        .S_AXI_WREADY(m01_AXI_WREADY),
        .S_AXI_WDATA(m01_AXI_WDATA),
        .S_AXI_WSTRB(m01_AXI_WSTRB),
        .S_AXI_WLAST(m01_AXI_WLAST),
        //
        .S_AXI_BVALID(m01_AXI_BVALID),
        .S_AXI_BREADY(m01_AXI_BREADY),
        .S_AXI_BID(),
        .S_AXI_BRESP(),
        //
        //
        .S_AXI_ARVALID(m01_AXI_ARVALID),
        .S_AXI_ARREADY(m01_AXI_ARREADY),
        .S_AXI_ARID(2'b0),
        .S_AXI_ARADDR(m01_AXI_ARADDR),
        .S_AXI_ARLEN(m01_AXI_ARLEN),
        .S_AXI_ARSIZE(m01_AXI_ARSIZE),
        .S_AXI_ARBURST(m01_AXI_ARBURST),
        .S_AXI_ARLOCK(1'b0),
        .S_AXI_ARCACHE(4'b0),
        .S_AXI_ARPROT(3'b0),
        .S_AXI_ARQOS(4'b0),
        //
        .S_AXI_RVALID(m01_AXI_RVALID),
        .S_AXI_RREADY(m01_AXI_RREADY),
        .S_AXI_RID(),
        .S_AXI_RDATA(m01_AXI_RDATA),
        .S_AXI_RRESP(),
        .S_AXI_RLAST(m01_AXI_RLAST),
        //
        //
        //
        // Write address (issued by master, acceped by Slave)
        .M_AXI_AWADDR(M_IO_AXI_AWADDR),
        .M_AXI_AWPROT(M_IO_AXI_AWPROT),
        .M_AXI_AWVALID(M_IO_AXI_AWVALID),
        .M_AXI_AWREADY(M_IO_AXI_AWREADY),
        .M_AXI_WDATA(M_IO_AXI_WDATA),
        .M_AXI_WSTRB(M_IO_AXI_WSTRB),
        .M_AXI_WVALID(M_IO_AXI_WVALID),
        .M_AXI_WREADY(M_IO_AXI_WREADY),
        .M_AXI_BRESP(M_IO_AXI_BRESP),
        .M_AXI_BVALID(M_IO_AXI_BVALID),
        .M_AXI_BREADY(M_IO_AXI_BREADY),
        //
        .M_AXI_ARADDR(M_IO_AXI_ARADDR),
        .M_AXI_ARPROT(M_IO_AXI_ARPROT),
        .M_AXI_ARVALID(M_IO_AXI_ARVALID),
        .M_AXI_ARREADY(M_IO_AXI_ARREADY),
        //
        .M_AXI_RVALID(M_IO_AXI_RVALID),
        .M_AXI_RREADY(M_IO_AXI_RREADY),
        .M_AXI_RDATA(M_IO_AXI_RDATA),
        .M_AXI_RRESP(M_IO_AXI_RRESP)
    );

// Wishbone pipelined to wishbone classic
wire              o_io_wb_reset;
wire              o_io_wb_cyc;
wire              o_io_wb_stb;
wire              o_io_wb_we;
wire [(AW-3):0]   o_io_wb_addr;
wire [(DW-1):0]   o_io_wb_data;
wire [(DW/8-1):0] o_io_wb_sel;
wire              i_io_wb_ack;
wire              i_io_wb_stall;
wire [(DW-1):0]   i_io_wb_data;
wire              i_io_wb_err;

axlite2wbsp #(
        .C_AXI_DATA_WIDTH(DW), // Width of the AXI R&W data
        .C_AXI_ADDR_WIDTH(AW), // AXI Address width
        .LGFIFO(4),
        .F_MAXSTALL(3),
        .F_MAXDELAY(3),
        .OPT_READONLY(1'b0),
        .OPT_WRITEONLY(1'b0)
    ) axlite2wbsp_io (
        .i_clk(cpu_clk_i),
        .i_axi_reset_n(!cpu_rst_i), // Change polarity!!
        //
        .o_axi_awready(M_IO_AXI_AWREADY), 
        .i_axi_awaddr(M_IO_AXI_AWADDR), 
        .i_axi_awcache(4'b0), 
        .i_axi_awprot(3'b0),
        .i_axi_awvalid(M_IO_AXI_AWVALID),
        //
        .o_axi_wready(M_IO_AXI_WREADY), 
        .i_axi_wdata(M_IO_AXI_WDATA), 
        .i_axi_wstrb(M_IO_AXI_WSTRB), 
        .i_axi_wvalid(M_IO_AXI_WVALID),
        //
        .o_axi_bresp(M_IO_AXI_BRESP), 
        .o_axi_bvalid(M_IO_AXI_BVALID), 
        .i_axi_bready(M_IO_AXI_BREADY),
        //
        .o_axi_arready(M_IO_AXI_ARREADY), 
        .i_axi_araddr(M_IO_AXI_ARADDR), 
        .i_axi_arcache(4'b0), 
        .i_axi_arprot(3'b0), 
        .i_axi_arvalid(M_IO_AXI_ARVALID),
        //
        .o_axi_rresp(M_IO_AXI_RRESP), 
        .o_axi_rvalid(M_IO_AXI_RVALID), 
        .o_axi_rdata(M_IO_AXI_RDATA), 
        .i_axi_rready(M_IO_AXI_RREADY),
        //
        // Wishbone interface
        .o_reset(o_io_wb_reset), 
        .o_wb_cyc(o_io_wb_cyc), 
        .o_wb_stb(o_io_wb_stb), 
        .o_wb_we(o_io_wb_we), 
        .o_wb_addr(o_io_wb_addr), 
        .o_wb_data(o_io_wb_data), 
        .o_wb_sel(o_io_wb_sel),
        .i_wb_ack(i_io_wb_ack), 
        .i_wb_stall(i_io_wb_stall), 
        .i_wb_data(i_io_wb_data), 
        .i_wb_err(i_io_wb_err)
    );

// Memory Wishbone pipelined to classic bridge
wbp2classic #(
        .AW(AW),
        .DW(DW)
    ) wbp2classic_io (
        .i_clk(cpu_clk_i), 
        .i_reset(o_io_wb_reset),
        .i_mcyc(o_io_wb_cyc), 
        .i_mstb(o_io_wb_stb), 
        .i_mwe(o_io_wb_we), 
        .i_maddr(o_io_wb_addr), 
        .i_mdata(o_io_wb_data), 
        .i_msel(o_io_wb_sel),
        .o_mstall(i_io_wb_stall), 
        .o_mack(i_io_wb_ack), 
        .o_mdata(i_io_wb_data), 
        .o_merr(i_io_wb_err),
    
        .o_scyc(wbm_cpu_io_cyc_o), 
        .o_sstb(wbm_cpu_io_stb_o), 
        .o_swe(wbm_cpu_io_we_o), 
        .o_saddr(wbm_cpu_io_adr_o), 
        .o_sdata(wbm_cpu_io_dat_o), 
        .o_ssel(wbm_cpu_io_sel_o),
        .i_sack(wbm_cpu_io_ack_i), 
        .i_sdata(wbm_cpu_io_dat_i), 
        .i_serr(wbm_cpu_io_err_i),
        .o_scti(wbm_cpu_io_cti_o), 
        .o_sbte(wbm_cpu_io_bte_o)
    );

endmodule


