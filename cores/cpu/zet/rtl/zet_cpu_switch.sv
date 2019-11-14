/*
 *  ZET CPU Wishbone switch and address decoder
 *  Copyright (C) 2019  Charley Picker <charleypicker@yahoo.com>
 *  Copyright (C) 2010  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *  Copyright (C) 2008, 2009 Sebastien Bourdeauducq - http://lekernel.net
 *  Copyright (C) 2000 Johny Chi - chisuhua@yahoo.com.cn
 *
 *  Adaptation and Portions taken from:
 *  Copyright (C) 2011  Geert Jan Laanstra <g.j.laanstraATutwente.nl>
 *  https://github.com/LaanstraGJ/zet/blob/master/cores/wb_switch/wb_switch.v
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

module zet_cpu_switch #(
        parameter s0_addr_1 = 21'h00000,  // Default Values
        parameter s0_mask_1 = 21'h00000,
        parameter s0_addr_2 = 21'h00000,
        parameter s0_mask_2 = 21'h00000,
        
        parameter s1_addr_1 = 21'h00000,
        parameter s1_mask_1 = 21'h00000,
        parameter s1_addr_2 = 21'h00000,
        parameter s1_mask_2 = 21'h00000,

        parameter sE_addr_1 = 21'h00000,
        parameter sE_mask_1 = 21'h00000,
        parameter sF_addr_1 = 21'h00000,
        parameter sF_mask_1 = 21'h00000
        )(
        // Master interface
        input  [15:0] m_dat_i,
        output [15:0] m_dat_o,
        input  [20:1] m_adr_i,
        input  [ 1:0] m_sel_i,
        input         m_we_i,
        input         m_cyc_i,
        input         m_stb_i,
        output        m_ack_o,

        output [ 1:0] m_tgc_o,
        input  [ 1:0] m_tgc_i,

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

        // Slave E interface - Pic Slave
        input  [15:0] sE_dat_i,
        output [15:0] sE_dat_o,
        output [20:1] sE_adr_o,
        output [ 1:0] sE_sel_o,
        output        sE_we_o,
        output        sE_cyc_o,
        output        sE_stb_o,
        input         sE_ack_i,

        output [ 1:0] sE_tgc_o,     // inta, nmia
        input  [ 1:0] sE_tgc_i,

        // Slave F interface - Pic Master
        input  [15:0] sF_dat_i,
        output [15:0] sF_dat_o,
        output [20:1] sF_adr_o,
        output [ 1:0] sF_sel_o,
        output        sF_we_o,
        output        sF_cyc_o,
        output        sF_stb_o,
        input         sF_ack_i,

        output [ 1:0] sF_tgc_o,     // inta, nmia
        input  [ 1:0] sF_tgc_i      // intr, nmi
        );

    `define mbusw_ls  20 + 2 + 16 + 1 + 1 + 1  // address + byte select + data + cyc + we + stb

    wire [3:0] slave_sel;
    wire [20:0] m_adr;
    wire [15:0] i_dat_s;   // internal shared bus, slave data to master
//    wire        def_ack_i; // default ack (we don't want to stall the bus)
    wire        i_bus_ack; // internal shared bus, ack signal

    wire [`mbusw_ls -1:0] i_bus_m;    // internal shared bus, master data and control to slave

    assign m_tgc_o = sF_tgc_i;        // intr, nmi
    assign sE_tgc_o = m_tgc_i;        // inta, nmia
    assign sF_tgc_o = m_tgc_i;        // inta, nmia

    assign m_dat_o = (m_tgc_i[0] | m_tgc_i[1]) ? (sF_dat_i | sE_dat_i) : i_dat_s; // int vector or slave data
    //assign m_dat_o = i_dat_s;
    assign m_ack_o = i_bus_ack;
    // Bus Acknowlegement
//    assign i_bus_ack =   s0_ack_i | s1_ack_i | sE_ack_i | sF_ack_i | def_ack_i;
    // Bus Acknowlegement - We will only accept ack from these slaves
    assign i_bus_ack =   s0_ack_i | s1_ack_i | sE_ack_i | sF_ack_i;
                            
    assign i_dat_s =
        //assign m_dat_o = // or'ed bus should be enough.... slaves should never drive bus when not selected.... only active interrupt controllers though
        ({16{slave_sel[ 0]}} & s0_dat_i) // slave read data
        |({16{slave_sel[1]}} & s1_dat_i)
        |({16{slave_sel[2]}} & sE_dat_i)
        |({16{slave_sel[3]}} & sF_dat_i);

    // add odd/even selection         
    assign m_adr = {m_adr_i, m_sel_i[1]};

    // Bus Selection logic
    assign slave_sel[ 0] =  ((m_adr & s0_mask_1) == s0_addr_1) | ((m_adr & s0_mask_2) == s0_addr_2);
    assign slave_sel[ 1] =  ((m_adr & s1_mask_1) == s1_addr_1) | ((m_adr & s1_mask_2) == s1_addr_2);
    assign slave_sel[ 2] =  ((m_adr & sE_mask_1) == sE_addr_1);
    assign slave_sel[ 3] =  ((m_adr & sF_mask_1) == sF_addr_1);

    // not implemented devices..
//    assign def_ack_i = m_stb_i & m_cyc_i & ~(|slave_sel[3:0]);

    assign i_bus_m = {m_adr_i, m_sel_i, m_dat_i, m_we_i, m_cyc_i, m_stb_i};

    assign {s0_adr_o, s0_sel_o, s0_dat_o, s0_we_o, s0_cyc_o}  = i_bus_m[`mbusw_ls -1:1];  // slave 0
    assign  s0_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[0];     // stb_o = cyc_i & stb_i & slave_sel

    assign {s1_adr_o, s1_sel_o, s1_dat_o, s1_we_o, s1_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave 1
    assign  s1_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[1];

    assign {sE_adr_o, sE_sel_o, sE_dat_o, sE_we_o, sE_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave E
    assign  sE_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[2];

    assign {sF_adr_o, sF_sel_o, sF_dat_o, sF_we_o, sF_cyc_o} = i_bus_m[`mbusw_ls -1:1];    // slave F
    assign  sF_stb_o = i_bus_m[1] & i_bus_m[0] & slave_sel[3];

endmodule