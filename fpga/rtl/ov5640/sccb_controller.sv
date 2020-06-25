module sccb_controller #(
  parameter SCL_DIV        = 100,
            SUB_ADDR_WIDTH = 16
)(
  input  logic       clk,
  input  logic       rest_n,
  input  logic[7:0]  device_addr,
  input  logic[15:0] sub_addr,
  input  logic       read,
  input  logic       write,
  input  logic[7:0]  write_data,
  output logic       request_done,
  output logic[7:0]  read_data,
  output logic       resp_valid,
  output logic       error,
  output logic       sccb_scl,
  inout  logic       sccb_sda
);

logic sccb_sda_o;
logic sccb_sda_i;

assign sccb_sda   = sccb_sda_o?1'bz:1'd0;
assign sccb_sda_i = sccb_sda;

struct
{
  logic[7:0]  device_addr;
  logic[15:0] sub_addr;
  logic       read;
  logic       write;
  logic[7:0]  write_data;
}cmd;

/**********************************************************************
分频得到SCCB时钟
**********************************************************************/
logic[15:0] div_count;
always @(posedge clk or negedge rest_n) begin
  if(!rest_n) begin
    div_count<=16'd0;
  end
  else begin
    if(div_count == (SCL_DIV/4-1)) begin
      div_count <= 16'd0;
    end
    else begin
      div_count <= div_count+16'd1;
    end
  end
end
/**********************************************************************
状态机(两段式)
**********************************************************************/
localparam  state_idle            = 4'h0,
            state_rw_start        = 4'h1,
            state_rw_device_addr  = 4'h2,
            state_rw_sub_addr_1   = 4'h3,
            state_rw_sub_addr_2   = 4'h4,
            state_rw_stop         = 4'h5,
            state_w_write_data    = 4'h6,
            state_r_read_data     = 4'h7,
            state_rw_err_handle   = 4'h8;
/***变量,Flag****************************/
logic[3:0]  state;
logic       rw;
logic[5:0]  count;

logic[8:0] send_data;
logic[8:0] rcvd_data;

logic end_flag_state_rw_start;
logic end_flag_state_rw_device_addr;
logic end_flag_state_rw_sub_addr_1 ;
logic end_flag_state_rw_sub_addr_2 ;
logic end_flag_state_rw_stop;
logic end_flag_state_w_write_data ;
logic end_flag_state_r_read_data;
logic flag_rcvd_avk;

/***结束条件****************************/
assign end_flag_state_rw_start       = (count == 6'd1 );
assign end_flag_state_rw_device_addr = (count == 4*9-1)||(flag_rcvd_avk&&sccb_sda_i);
assign end_flag_state_rw_sub_addr_1  = (count == 4*9-1)||(flag_rcvd_avk&&sccb_sda_i);
assign end_flag_state_rw_sub_addr_2  = (count == 4*9-1)||(flag_rcvd_avk&&sccb_sda_i);
assign end_flag_state_rw_stop        = (count == 4    );
assign end_flag_state_w_write_data   = (count == 4*9-1)||(flag_rcvd_avk&&sccb_sda_i);
assign end_flag_state_r_read_data    = (count == 4*9-1);
assign flag_rcvd_avk                 = (count[5:2]==4'd8)&&(count[1:0]==2'd2);

/***状态机第一段****************************/
always @(posedge clk or negedge rest_n) begin
  if(!rest_n) begin
    state <= state_idle;
  end
  else begin
    if((div_count == 16'd0)||(state == state_idle)) begin
      case(state)
        state_idle:begin
            state <= (read||write)&&!request_done?state_rw_start:state_idle;
          end
        state_rw_start:begin
            state <= end_flag_state_rw_start?state_rw_device_addr:state_rw_start;
          end
        state_rw_device_addr:begin
            if(flag_rcvd_avk&&sccb_sda_i) begin
              state <= state_rw_err_handle;
            end
            else begin
              if(cmd.write||!rw) begin
                state <= end_flag_state_rw_device_addr?state_rw_sub_addr_1:state_rw_device_addr;
              end
              else begin
                state <= end_flag_state_rw_device_addr?state_r_read_data:state_rw_device_addr;
              end
            end
          end
        state_rw_sub_addr_1:begin
            if(flag_rcvd_avk&&sccb_sda_i) begin
              state <= state_rw_err_handle;
            end
            else begin
              state <= end_flag_state_rw_sub_addr_1?state_rw_sub_addr_2:state_rw_sub_addr_1;
            end
          end
        state_rw_sub_addr_2:begin
            if(flag_rcvd_avk&&sccb_sda_i) begin
              state <= state_rw_err_handle;
            end
            else begin
              if(cmd.write) begin
                state <= end_flag_state_rw_sub_addr_2?state_w_write_data:state_rw_sub_addr_2;
              end
              else begin
                state <= end_flag_state_rw_sub_addr_2?state_rw_stop:state_rw_sub_addr_2;
              end
            end
          end
        state_rw_stop:begin
            if(cmd.write||rw) begin
              state <= end_flag_state_rw_stop?state_idle:state_rw_stop;
            end
            else begin
              state <= end_flag_state_rw_stop?state_rw_start:state_rw_stop;
            end
          end
        state_w_write_data:begin
            if(flag_rcvd_avk&&sccb_sda_i) begin
              state <= state_rw_err_handle;
            end
            else begin
              state <= end_flag_state_w_write_data?state_rw_stop:state_w_write_data;
            end
          end
        state_r_read_data:begin
            state <= end_flag_state_r_read_data?state_rw_stop:state_r_read_data;
          end
        state_rw_err_handle:begin
            state <= state_rw_stop;
          end
      endcase
    end
  end
end
/***状态机第二段****************************/
always @(posedge clk) begin
  if((div_count == 16'd0)||(state == state_idle)) begin
    case(state)
      state_idle:begin
          count        <= 1'd0;
          sccb_scl     <= 1'd1;
          sccb_sda_o   <= 1'd1;
          rw           <= 1'd0;
          resp_valid   <= 1'd0;
          request_done <= 1'd0;
          if(read||write) begin
            cmd.device_addr <= device_addr;
            cmd.sub_addr    <= sub_addr;
            cmd.read        <= read;
            cmd.write       <= write;
            cmd.write_data  <= write_data ;
          end
          if((read||write)&&!request_done) begin
            /*开始新的处理,清除错误标志*/
            error <= 1'd0;
          end
        end
      state_rw_start:begin
          /*发送开始信号,同时准备需要发送的数据*/
          sccb_sda_o   <= 1'd0;
          sccb_scl     <= end_flag_state_rw_start?1'd0:1'd1;
          count        <= end_flag_state_rw_start?1'd0:count+1'd1;
          send_data    <= {cmd.device_addr[7:1],rw,1'd1};
        end
      state_rw_device_addr:begin
          /*发送从机地址,count[1:0]从0-3为一个scl时钟周期,0、3时为低电平,1、2时为高电平*/
          sccb_scl      <= count[1] ^ count[0];
          sccb_sda_o    <= send_data[8-count[5:2]];
          count         <= end_flag_state_rw_device_addr?1'd0:count+1'd1;
          send_data     <= end_flag_state_rw_device_addr?{cmd.sub_addr[15:8],1'd1}:send_data;
        end
      state_rw_sub_addr_1:begin
          /*发送寄存器地址高位,count[1:0]从0-3为一个scl时钟周期,0、3时为低电平,1、2时为高电平*/
          sccb_scl      <= count[1] ^ count[0];
          sccb_sda_o    <= send_data[8-count[5:2]];
          count         <= end_flag_state_rw_sub_addr_1?1'd0:count+1'd1;
          send_data     <= end_flag_state_rw_sub_addr_1?{cmd.sub_addr[7:0],1'd1}:send_data;
        end
      state_rw_sub_addr_2:begin
          /*发送寄存器地址低位,count[1:0]从0-3为一个scl时钟周期,0、3时为低电平,1、2时为高电平*/
          sccb_scl      <= count[1] ^ count[0];
          sccb_sda_o    <= send_data[8-count[5:2]];
          count         <= end_flag_state_rw_sub_addr_2?1'd0:count+1'd1;
          send_data     <= end_flag_state_rw_sub_addr_2?{cmd.write_data[7:0],1'd1}:send_data;
        end
      state_rw_stop:begin
          /*发送stop信号*/
          rw            <= end_flag_state_rw_stop?1'd1:rw;
          sccb_scl      <= count[2] || count[1] || count[0];
          sccb_sda_o    <= count[2] || count[1];
          request_done  <= (end_flag_state_rw_stop && cmd.write || (end_flag_state_rw_stop&&rw))?1'd1:1'd0;
          resp_valid    <= end_flag_state_rw_stop&&rw?1'd1:1'd0;
          count         <= end_flag_state_rw_stop?1'd0:count+1'd1;
        end
      state_w_write_data:begin
          /*发送需要写入到从器级的数据*/
          sccb_scl      <= count[1] ^ count[0];
          sccb_sda_o    <= send_data[8-count[5:2]];
          count         <= end_flag_state_w_write_data?1'd0:count+1'd1;
        end
      state_r_read_data:begin
          /*读数据*/
          if(count[1]&&!count[0]) begin
            rcvd_data   <=  {rcvd_data[7:0],sccb_sda_i};
          end
          sccb_sda_o    <= 1'd1;
          sccb_scl      <= count[1] ^ count[0];
          count         <= end_flag_state_r_read_data?1'd0:count+1'd1;
        end
      state_rw_err_handle:begin
          /*记录错误*/
          sccb_scl <= 1'd0;
          rw       <= 1'd1;
          error    <= 1'd1;
        end
    endcase
  end
end

assign read_data     = rcvd_data[8:1];

endmodule
