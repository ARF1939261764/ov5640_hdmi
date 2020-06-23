module mux_n21 #(
  parameter WIDTH = 32,
            NUM   = 2
)(
  input  logic[$clog2(NUM)-1:0] sel,
  input  logic[WIDTH-1:0]       in[NUM-1:0],
  output logic[WIDTH-1:0]       out
);
  
assign out=in[sel];

endmodule
