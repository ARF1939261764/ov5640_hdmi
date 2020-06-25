module frame_write(
  input logic       clk,
  input logic       rest_n,
  input logic       fifo_write_clk,
  input logic       fifo_write,
  input logic[15:0] fifo_write_data,
  input logic       fifo_addr_clean,
  i_avl_bus.master  avl_m0,
  output logic[1:0] occupy_block_num
);

logic[31:0] fifo_read_data;
logic       fifo_rdempty;
logic[11:0] fifo_rdusedw;
logic[31:0] count;

/********************************************************************************************************
状态机
********************************************************************************************************/
localparam  state_idle = 2'd0,
            state_write_data = 2'd1;
logic[1:0] state;

always @(posedge clk or negedge rest_n) begin
  if(!rest_n) begin
    state <= state_idle;
    occupy_block_num <= 1'd0;
  end
  else begin
    case(state)
      state_idle:begin
          if(fifo_rdusedw>=11'd256) begin
            avl_m0.write        <= 1'd1;
            avl_m0.begin_burst_transfer <= 1'd1;
            avl_m0.burst_count  <= 8'd255;
            occupy_block_num++;
            state               <= state_write_data;
          end
          else begin
            avl_m0.begin_burst_transfer <= 1'd0;
            avl_m0.write <= 1'd0;
            state       <= state_idle;
          end
          count <= 1'd0;
        end
      state_write_data:begin
          avl_m0.begin_burst_transfer <= 1'd0;
          if((count[7:0]==8'd255)&&avl_m0.request_ready) begin
            avl_m0.write <= 1'd0;
            state <= state_idle;
          end
        end
      default:begin
          state <= state_idle;
        end
    endcase
    if(fifo_addr_clean) begin
      count<=1'd0;
    end
    else if(avl_m0.request_ready) begin
      count<=count+1'd1;
    end
  end
end
/********************************************************************************************************
给出写SDRAM的相关信号
********************************************************************************************************/
assign avl_m0.address    = {9'd0,occupy_block_num[1:0],count[18:8],10'd0};
assign avl_m0.read       = 1'd0;
assign avl_m0.byte_en    = 4'hf;
assign avl_m0.write_data = fifo_read_data;
assign avl_m0.resp_ready = 1'd0;
/********************************************************************************************************
fifo实例
********************************************************************************************************/
aysnc_fifo_16_to_32 aysnc_fifo_16_to_32_inst0(
	.aclr   (fifo_addr_clean||!rest_n ),
	.data   (fifo_write_data          ),
	.rdclk  (clk                      ),
	.rdreq  (avl_m0.request_ready     ),
	.wrclk  (fifo_write_clk           ),
	.wrreq  (fifo_write               ),
	.q      (fifo_read_data           ),
	.rdempty(fifo_rdempty             ),
	.rdusedw(fifo_rdusedw             )
);

endmodule