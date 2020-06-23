module avl_bus_priority_encoder #(
  parameter SIGN_WIDTH = 8
)(
  input  logic[SIGN_WIDTH-1:0]         in,
  output logic[$clog2(SIGN_WIDTH)-1:0] out
);

function logic[$clog2(SIGN_WIDTH)-1:0] encoder(input logic[SIGN_WIDTH-1:0] in);
  int i;
  for(i=0;i<SIGN_WIDTH;i++) begin
    if(in[i]) begin
      break;
    end
  end
  return i[$clog2(SIGN_WIDTH)-1:0];
endfunction

assign out = encoder(in);

endmodule
