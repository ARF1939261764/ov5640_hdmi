`timescale 1ns/100ps
module dmt_timing_generate_tb;

logic pixe_clk;
logic rest_n;
logic vsycn;
logic hsync;
logic de;

dmt_timing_generate dmt_timing_generate_inst0(
  .pixe_clk (pixe_clk ),
  .rest_n   (rest_n   ),
  .vsycn    (vsycn    ),
  .hsync    (hsync    ),
  .de       (de       )
);

initial begin
  pixe_clk=0;
  rest_n=0;
  #100;
  rest_n=1;
end

always #5 pixe_clk = ~pixe_clk;

endmodule