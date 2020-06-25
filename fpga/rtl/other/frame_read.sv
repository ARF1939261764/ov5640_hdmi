module frame_read(
  input  logic       clk,
  input  logic       rest_n,
  input  logic       fifo_read_clk,
  input  logic       fifo_read_resp,
  output logic[15:0] fifo_read_data,
  input  logic       fifo_addr_clean,
  i_avl_bus.slave    avl_s0,
  input  logic[1:0]  occupy_block_num_screenshot,
  input  logic[1:0]  occupy_block_num_write
);



endmodule