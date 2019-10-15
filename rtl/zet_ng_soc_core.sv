
    
/****************************************************************************
 * zet_ng_soc_core.sv
 ****************************************************************************/
  
/**
 * Module: zet_ng_soc_core
 * 
 * TODO: Add module documentation
 */
module zet_ng_soc_core(
    input clk,
    input rst
);

reg r_clk;
reg r_rst;

always @(posedge clk)
    if (rst) begin
        r_clk <= 1'b0;
        r_rst <= 1'b0;
    end
    else begin
        r_clk <= !r_clk;
        r_rst <= !r_rst;
    end

endmodule


