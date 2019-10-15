
    
/****************************************************************************
 * zet_ng_soc_core_tb.sv
 ****************************************************************************/

/**
 * Module: zet_ng_soc_core_tb
 * 
 * TODO: Add module documentation
 */

`default_nettype none
module zet_ng_soc_core_tb


`ifdef VERILATOR

    (input wire clk,
    input wire  rst);

`endif

 ;

`ifndef VERILATOR
     
     vlog_tb_utils vtu();
     reg   clk = 1'b0;
     reg   rst = 1'b1;
     always #20 clk <= !clk;
     initial #100 rst <= 1'b0;

`endif

zet_ng_soc_core zet_ng_soc(
    .clk (clk),
    .rst (rst)
);

endmodule


