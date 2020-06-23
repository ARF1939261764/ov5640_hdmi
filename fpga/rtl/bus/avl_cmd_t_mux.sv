`include "avl_bus_define.sv"
import avl_bus_type::*;
/*mux*/
module avl_cmd_t_mux #(
  parameter NUM = 8
)(
  input  avl_cmd_t              in[NUM-1:0],
  input  logic[$clog2(NUM)-1:0] sel,
  output avl_cmd_t              out
);

assign out=in[sel];
  
endmodule