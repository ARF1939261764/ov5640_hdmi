module frame_read(
  input  logic       clk,
  input  logic       rest_n,
  input  logic       fifo_read_clk,
  input  logic       fifo_read_resp,
  output logic[15:0] fifo_read_data,
  input  logic       fifo_addr_clean,
  i_avl_bus.master   avl_m0,
  input  logic[1:0]  occupy_block_num_screenshot,
  input  logic[1:0]  occupy_block_num_write
);

logic       wrreq;
logic       rdempty;
logic[10:0] rdusedw;
logic[31:0] count;
logic[1:0]  index;
logic[1:0]  index_add_1;
logic[1:0]  index_add_2;
logic       addr_clean_d0,addr_clean_d1,addr_clean;
logic[10:0] rdusedw_q;

/*异步信号处理*/
always @(posedge clk) begin
  addr_clean   <= addr_clean_d1;
  addr_clean_d1<=addr_clean_d0;
  addr_clean_d0<=fifo_addr_clean;
  rdusedw_q<=rdusedw;
end

assign index_add_1 = index + 2'd1;
assign index_add_2 = index + 2'd2;

/********************************************************************************************************
状态机
********************************************************************************************************/
localparam  state_idle = 2'd0,
            state_read_data = 2'd1;
logic[1:0] state;
always @(posedge clk or negedge rest_n) begin
  if(!rest_n) begin
    state <= state_idle;
    count <= 1'd0;
    index <= 1'd0;
  end
  else begin
    case(state)
      state_idle:begin
          avl_m0.begin_burst_transfer <= 1'd1;
          avl_m0.burst_count <= 8'd255;
          if(!rdusedw_q[8]) begin/*小于256*/
            avl_m0.read <= 1'd1;
            state <= state_read_data;
            if(
                (index_add_1 == occupy_block_num_write)||
                ((index_add_1 == occupy_block_num_screenshot)&&(index_add_2 == occupy_block_num_write))
              ) begin
              index <= index;
            end
            else begin
              index <= (index_add_1 == occupy_block_num_screenshot)?index_add_2:index_add_1;
            end
          end
          else begin
            avl_m0.read <= 1'd0;
            state <= state_idle;
          end
        end
      state_read_data:begin
          if(avl_m0.request_ready) begin
            avl_m0.begin_burst_transfer <= 1'd0;
          end
          if(count[7:0] == 8'd255) begin
            avl_m0.read <= 1'd0;
            state <= state_idle;
          end
          else begin
            state <= state_read_data;
          end
        end
      default:begin
          /*none*/
        end
    endcase
    if(addr_clean) begin
      count <= 1'd0;
    end
    else if(avl_m0.request_ready) begin
      count <= count + 1'd1;
    end
  end
end

assign avl_m0.address    = {9'd0,index[1:0],count[18:0],2'd0};
assign avl_m0.byte_en    = 4'hf;
assign avl_m0.write      = 1'd0;
assign avl_m0.write_data = 1'd0;
assign avl_m0.resp_ready = 1'd1;

/********************************************************************************************************
fifo实例
********************************************************************************************************/
aysnc_fifo_32_to_16 aysnc_fifo_32_to_16_inst0(
	.aclr   (addr_clean||!rest_n      ),
	.data   (avl_m0.read_data         ),
	.rdclk  (fifo_read_clk            ),
	.rdreq  (fifo_read_resp           ),
	.wrclk  (clk                      ),
	.wrreq  (avl_m0.read_data_valid   ),
	.q      (fifo_read_data           ),
	.rdempty(rdempty                  ),
	.rdusedw(rdusedw                  )
);

endmodule