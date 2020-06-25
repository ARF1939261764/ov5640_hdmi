module ov5640_config(
  input logic  clk,
  input logic  rest_n,
  output logic sccb_scl,
  inout  wire  sccb_sda,
  output logic config_done
);
localparam DELAY_TIME = 32'd1000;
/**********************************************************************
变量
**********************************************************************/
logic[15:0] index;
logic       error;
logic[31:0] config_data;
logic[15:0] config_data_num;
logic       sccb_request_done;
logic       sccb_error;
logic       sccb_write;
logic[31:0] delay_count;
logic       flag_config_end;
logic       flag_delay_en;
logic       flag_delay_00_en;
logic       flag_delay_01_en;
logic       flag_delay_end;
/**********************************************************************
初始化
**********************************************************************/
initial begin
  index <= 1'd0;
  config_done <= 1'd0;
end
/**********************************************************************
连线
**********************************************************************/
assign flag_config_end  = (index == config_data_num - 1'd1);
assign flag_delay_end   = (delay_count==DELAY_TIME);
assign flag_delay_00_en = index == 1'd0;
assign flag_delay_01_en = index == 1'd1;
assign flag_delay_en    = flag_delay_00_en||
                          flag_delay_01_en;
/**********************************************************************
状态机(一段式),负责读取配置数据并通过sccb控制器发送出去
**********************************************************************/
localparam  state_idle             = 4'd0,
            state_get_config_data  = 4'd1,
            state_send_config_data = 4'd2;

logic[1:0] state;

always @(posedge clk or negedge rest_n) begin
  if(!rest_n) begin
    config_done <= 1'd0;
    index       <= 1'd0;
    delay_count <= 1'd0;
  end
  else begin
    case(state)
      state_idle:begin
          state       <= config_done?state_idle:state_send_config_data;
          delay_count <= 1'd0;
        end
      state_get_config_data:begin
          if(!error) begin
            index <= index+1'd1;/*注意这里是阻塞赋值*/
          end
          state       <= flag_config_end?state_idle:state_send_config_data;
          config_done <= flag_config_end?1'd1:1'd0;
          delay_count <= 1'd0;
        end
      state_send_config_data:begin
          error      <= sccb_error;
          sccb_write <= sccb_request_done?1'd0:!flag_delay_en||flag_delay_end;
          state      <= sccb_request_done?state_get_config_data:state_send_config_data;
          if(flag_delay_en&&!flag_delay_end) begin
            delay_count++;
          end
        end
    endcase
  end
end
/**********************************************************************
配置数据RAM实例化
**********************************************************************/
ov5640_config_data #(
  .DEPTH(512)
)
ov5640_config_data_inst0(
  .clk            (clk            ),
  .address        (index          ),
  .read_data      (config_data    ),
  .config_data_num(config_data_num)
);

/**********************************************************************
SCCB控制器实例化
**********************************************************************/
sccb_controller #(
  .SCL_DIV       (500),
  .SUB_ADDR_WIDTH(16)
)
sccb_controller_inst0(
  .clk          (clk                ),
  .rest_n       (rest_n             ),
  .device_addr  (config_data[31:24] ),
  .sub_addr     (config_data[23: 8] ),
  .read         (1'd0               ),
  .write        (sccb_write         ),
  .write_data   (config_data[7:0]   ),
  .request_done (sccb_request_done  ),
  .read_data    (/*none*/           ),
  .resp_valid   (/*none*/           ),
  .error        (sccb_error         ),
  .sccb_scl     (sccb_scl           ),
  .sccb_sda     (sccb_sda           )
);

endmodule
