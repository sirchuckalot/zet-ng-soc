/*
 *  Zet CPU and PIC Wrapper
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
    
module zet_cpu_wrapper
    #(parameter s0_addr_1 = 21'h0_00000, // mem 0x00000 - 0xfffff
      parameter s0_mask_1 = 21'h1_00000, // Base RAM
      parameter s0_addr_2 = 21'h1_00000, // io  0x00000 - 0xfffff
      parameter s0_mask_2 = 21'h1_00000, // Base io
        
      parameter s1_addr_1 = 21'h0_00000, //
      parameter s1_mask_1 = 21'h1_FFFFF, // not used
      parameter s1_addr_2 = 21'h1_00000,
      parameter s1_mask_2 = 21'h1_00000, // not used

      parameter sE_addr_1 = 21'h1_000A0, // io 0x00A0 - 0x00A1
      parameter sE_mask_1 = 21'h1_0FFFE, // 8259A Slave Interrupt Controller

      parameter sF_addr_1 = 21'h1_00020, // io 0x0020 - 0x0021
      parameter sF_mask_1 = 21'h1_0FFFE) // 8259A Master Interrupt Controller
    
    (input         cpu_clk_i,
     input         cpu_rst_i,
        
     // Slave 0 interface
     input  [15:0] s0_dat_i,
     output [15:0] s0_dat_o,
     output [20:1] s0_adr_o,
     output [ 1:0] s0_sel_o,
     output        s0_we_o,
     output        s0_cyc_o,
     output        s0_stb_o,
     input         s0_ack_i,
        
     // Slave 1 interface
     input  [15:0] s1_dat_i,
     output [15:0] s1_dat_o,
     output [20:1] s1_adr_o,
     output [ 1:0] s1_sel_o,
     output        s1_we_o,
     output        s1_cyc_o,
     output        s1_stb_o,
     input         s1_ack_i,
    
     // CPU PIC Interrupts
     input  [15:0] pic_intv_i,
     input         pic_nmi_i,
        
     // CPU Program Counter
     output [19:0] cpu_pc_o
     );

    // wires to CPU  
    wire [19:0] cpu_pc;

    wire        cpu_stb_o;
    wire        cpu_cyc_o;
    wire        cpu_tga_o;
    wire [19:1] cpu_adr_o;
    wire        cpu_we_o;
    wire [ 1:0] cpu_sel_o;
    wire [15:0] cpu_dat_o;
    wire [15:0] cpu_dat_i;
    wire        cpu_ack_i;
    wire [ 1:0] cpu_tgc_i;    // intr, nmi
    wire [ 1:0] cpu_tgc_o;    // inta, nmia

    // wires to Pic 
    wire        picm_stb_i;
    wire        picm_cyc_i;
    wire        picm_tga_i;
    wire [19:1] picm_adr_i;
    wire [ 1:0] picm_sel_i;
    wire        picm_we_i;
    wire [15:0] picm_dat_i;
    wire [15:0] picm_dat_o;
    wire        picm_ack_o;
    
    wire [ 7:0] pic_cas;
  
    wire        pics_stb_i;
    wire        pics_cyc_i;
    wire        pics_tga_i;
    wire [19:1] pics_adr_i;
    wire [ 1:0] pics_sel_i;
    wire        pics_we_i;
    wire [15:0] pics_dat_i;
    wire [15:0] pics_dat_o;
    wire        pics_ack_o;
  
    wire        pics_nmi;     // not used
  
    wire [ 1:0] picm_tgc_o;   // int, nmi
    wire [ 1:0] picm_tgc_i;
    wire [ 1:0] pics_tgc_o;   // intv[2], dummy
    wire [ 1:0] pics_tgc_i;

    wire [15:0] pic_intv;
    wire        pic_nmi;
    
    // Default PIC assignments    
    assign pic_intv[ 0] = pic_intv_i[ 0];
    assign pic_intv[ 1] = pic_intv_i[ 1];
    assign pic_intv[ 2] = pics_tgc_o[ 1]; // (Int0A/IRQ02) cascaded slave
    assign pic_intv[ 3] = pic_intv_i[ 3];
    assign pic_intv[ 4] = pic_intv_i[ 4];
    assign pic_intv[ 5] = pic_intv_i[ 5];
    assign pic_intv[ 6] = pic_intv_i[ 6];
    assign pic_intv[ 7] = pic_intv_i[ 7];
    assign pic_intv[ 8] = pic_intv_i[ 8];
    assign pic_intv[ 9] = pic_intv_i[ 9];
    assign pic_intv[10] = pic_intv_i[10];
    assign pic_intv[11] = pic_intv_i[11];
    assign pic_intv[12] = pic_intv_i[12];
    assign pic_intv[13] = pic_intv_i[13];
    assign pic_intv[14] = pic_intv_i[14];
    assign pic_intv[15] = pic_intv_i[15];
    assign pic_nmi = pic_nmi_i;
    
    // Pass the CPU Program Counter out of this wrapper
    assign cpu_pc_o = cpu_pc;
    
    // primary interupt controller
    pic #(
        .int_vector (8'h08),
        .int_mask   (8'b11101000)
    ) picm (
        .wb_clk_i   (cpu_clk_i),
        .wb_rst_i   (cpu_rst_i),

        .nsp        (1'b1),               // master (1) or slave (0)
        .cas_i      (1'b0),                 // cascade input (slave)
        .cas_o      (pic_cas),            // cascade output (master)

        .pic_intv   (pic_intv[7:0]),    // input interupt vectors
        .pic_nmi    (pic_nmi),            // input nmi

        .wb_stb_i   (picm_stb_i),
        .wb_cyc_i   (picm_cyc_i),
        .wb_adr_i   (picm_adr_i),
        .wb_sel_i   (picm_sel_i),
        .wb_we_i    (picm_we_i),
        .wb_dat_i   (picm_dat_i),
        .wb_dat_o   (picm_dat_o),         // interrupt vector output (to cpu)
        .wb_ack_o   (picm_ack_o),

        .wb_tgc_o   (picm_tgc_o),         // intr, nmi  (to cpu)
        .wb_tgc_i   (picm_tgc_i),         // inta, nmia (from cpu)
        /* verilator lint_off PINCONNECTEMPTY */    
        .test_int_irr  (),
        .test_int_isr  ()
        /* verilator lint_on PINCONNECTEMPTY */
    );
    
    // secondary interrupt controller
    pic #(
        .int_vector (8'h70),
        .int_mask   (8'b11101111)
    ) pics (
        .wb_clk_i   (cpu_clk_i),
        .wb_rst_i   (cpu_rst_i),

        .nsp        (1'b0),               // master (1) or slave (0)
        .cas_i      (pic_cas[2]),         // cascade input (slave)
        /* verilator lint_off PINCONNECTEMPTY */
        .cas_o      (),               // cascade output (master)
        /* verilator lint_on PINCONNECTEMPTY */

        .pic_intv   (pic_intv[15:8]),   // input interupt vectors
        .pic_nmi    (1'b0),                     // input nmi

        .wb_stb_i   (pics_stb_i),
        .wb_cyc_i   (pics_cyc_i),
        .wb_adr_i   (pics_adr_i),
        .wb_sel_i   (pics_sel_i),
        .wb_we_i    (pics_we_i),
        .wb_dat_i   (pics_dat_i),
        .wb_dat_o   (pics_dat_o),           // interrupt vector output (to cpu)
        .wb_ack_o   (pics_ack_o),

        .wb_tgc_o   (pics_tgc_o),     // intv[2], dummy
        .wb_tgc_i   (pics_tgc_i),           // inta, nmia (from cpu)
        /* verilator lint_off PINCONNECTEMPTY */
        .test_int_irr  (),
        .test_int_isr  ()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // For now, lets use the newer ZET CPU Core v1.3.1
    zet zet (
        .pc (cpu_pc),

        // Wishbone master interface
        .wb_clk_i (cpu_clk_i),
        .wb_rst_i (cpu_rst_i),
        .wb_dat_i (cpu_dat_i),
        .wb_dat_o (cpu_dat_o),
        .wb_adr_o (cpu_adr_o),
        .wb_we_o  (cpu_we_o),
        .wb_tga_o (cpu_tga_o),
        .wb_sel_o (cpu_sel_o),
        .wb_stb_o (cpu_stb_o),
        .wb_cyc_o (cpu_cyc_o),
        .wb_ack_i (cpu_ack_i),
        .wb_tgc_i (cpu_tgc_i[1]),    // intr    (intr from pic)
        .wb_tgc_o (cpu_tgc_o[1]),    // inta    (inta to pic)
        .nmi      (cpu_tgc_i[0]),    // nmi     (nmir to cpu)
        .nmia     (cpu_tgc_o[0])     // nmia    (nmia from pic)
    );
    
    zet_cpu_switch
        #(.s0_addr_1 (s0_addr_1), // mem 0x00000 - 0xfffff
          .s0_mask_1 (s0_mask_1), // Base RAM
          .s0_addr_2 (s0_addr_2), // io  0x00000 - 0xfffff
          .s0_mask_2 (s0_mask_2), // Base io
        
          .s1_addr_1 (s1_addr_1), //
          .s1_mask_1 (s1_mask_1), // not used
          .s1_addr_2 (s1_addr_2),
          .s1_mask_2 (s1_mask_2), // not used

          .sE_addr_1 (sE_addr_1), // io 0x00A0 - 0x00A1
          .sE_mask_1 (sE_mask_1), // 8259A Slave Interrupt Controller

          .sF_addr_1 (sF_addr_1), // io 0x0020 - 0x0021
          .sF_mask_1 (sF_mask_1)  // 8259A Master Interrupt Controller
    ) zet_cpu_switch (

    // Master interface
    .m_dat_i (cpu_dat_o),
    .m_dat_o (cpu_dat_i),
    .m_adr_i ({cpu_tga_o, cpu_adr_o}),
    .m_sel_i (cpu_sel_o),
    .m_we_i  (cpu_we_o),
    .m_cyc_i (cpu_cyc_o),
    .m_stb_i (cpu_stb_o),
    .m_ack_o (cpu_ack_i),
    .m_tgc_o (cpu_tgc_i),
    .m_tgc_i (cpu_tgc_o),

    // Slave 0 interface
    .s0_dat_i (s0_dat_i),
    .s0_dat_o (s0_dat_o),
    .s0_adr_o (s0_adr_o), // tga_s, adr_s
    .s0_sel_o (s0_sel_o),
    .s0_we_o  (s0_we_o),
    .s0_cyc_o (s0_cyc_o),
    .s0_stb_o (s0_stb_o),
    .s0_ack_i (s0_ack_i),

    // Slave 1 interface
    .s1_dat_i (s1_dat_i),
    .s1_dat_o (s1_dat_o),
    .s1_adr_o (s1_adr_o), // tga_s, adr_s
    .s1_sel_o (s1_sel_o),
    .s1_we_o  (s1_we_o),
    .s1_cyc_o (s1_cyc_o),
    .s1_stb_o (s1_stb_o),
    .s1_ack_i (s1_ack_i),

    // slave E interface - PIC slave
    .sE_dat_i (pics_dat_o),
    .sE_dat_o (pics_dat_i),
    .sE_adr_o ({pics_tga_i, pics_adr_i}),
    .sE_sel_o (pics_sel_i),
    .sE_we_o  (pics_we_i),
    .sE_cyc_o (pics_cyc_i),
    .sE_stb_o (pics_stb_i),
    .sE_ack_i (pics_ack_o),
    
    .sE_tgc_o (pics_tgc_i),     // inta, nmia (from cpu)
    .sE_tgc_i (pics_tgc_o),     // intv[2], dummy

    // slave F interface - PIC master
    .sF_dat_i (picm_dat_o),
    .sF_dat_o (picm_dat_i),
    .sF_adr_o ({picm_tga_i, picm_adr_i}),
    .sF_sel_o (picm_sel_i),
    .sF_we_o  (picm_we_i),
    .sF_cyc_o (picm_cyc_i),
    .sF_stb_o (picm_stb_i),
    .sF_ack_i (picm_ack_o),

    .sF_tgc_o (picm_tgc_i),     // inta, nmia (from cpu)
    .sF_tgc_i (picm_tgc_o)      // intr, nmi  (to cpu)
    );   

endmodule


