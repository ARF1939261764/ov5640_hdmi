`include "avl_bus_define.sv"
import avl_bus_type::*;

module avl_bus_n21_arb #(
  parameter ARB_METHOD = 0,/*0:轮询仲裁,1:优先级仲裁*/
            MASTER_NUM = 8 /*MASTER_NUM∈[1,16]*/
)(
  input  logic                          clk,
  input  logic                          rest,
  input  logic[MASTER_NUM-1:0]          request,
  input  avl_cmd_t                      avl_out_cmd,
  input  logic                          avl_out_request_ready,
  output logic[$clog2(MASTER_NUM)-1:0]  sel
);
/************************************************
参数
************************************************/
localparam SEL_WIDTH  = $clog2(MASTER_NUM);
/************************************************
变量
************************************************/
logic[$clog2(`ALV_BURST_MAX_COUNT)-1:0] burst_count;
logic[SEL_WIDTH-1:0]                    now_sel;
logic[SEL_WIDTH-1:0]                    sel_buff;
logic[SEL_WIDTH-1:0]                    last_sel;
logic                                   send_cmd_success;
logic[MASTER_NUM-1:0]                   encoder_in;
logic[SEL_WIDTH-1:0]                    encoder_out;

/************************************************
连线
************************************************/

assign now_sel          = encoder_out;
assign send_cmd_success = avl_out_request_ready&&(avl_out_cmd.read||avl_out_cmd.write);

/************************************************
突发传输处理
************************************************/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    burst_count<=1'd0;
    sel_buff<=1'd0;
  end
  else begin
    if(avl_out_cmd.begin_burst_transfer) begin
      burst_count<=avl_out_cmd.burst_count;
      sel_buff<=sel;
    end
    else if(send_cmd_success) begin
      burst_count<=(burst_count==0)?1'd0:(burst_count-1'd1);
    end
  end
end
/************************************************
记录上一次授权的通道
************************************************/
always @(posedge clk or negedge rest) begin
  if(!rest) begin
    last_sel<={SEL_WIDTH{1'd1}};
  end
  else begin
    if(send_cmd_success) begin
      last_sel=sel;
    end
  end
end
/************************************************
轮询/优先级仲裁
************************************************/
generate
genvar i;
  if(ARB_METHOD==0) begin
    assign sel              = burst_count==0?(now_sel+last_sel+1'd1):sel_buff;
    logic[MASTER_NUM-1:0] w[MASTER_NUM-1:0];
    for(i=0;i<MASTER_NUM-1;i++) begin:block_0
      assign w[i]={request[i:0],request[MASTER_NUM-1:i+1]};
    end
    assign w[MASTER_NUM-1]=request;
    mux_n21 #(
      .WIDTH(MASTER_NUM),
      .NUM  (MASTER_NUM)
    )mux_n21_inst0(
      .sel(last_sel   ),
      .in (w          ),
      .out(encoder_in )
    );
  end
  else if(ARB_METHOD==1) begin
    assign sel              = burst_count==0?now_sel:sel_buff;
    assign encoder_in = request;
  end
  else begin
    /*Illegal options*/
  end
endgenerate

avl_bus_priority_encoder #(
  .SIGN_WIDTH(MASTER_NUM)
)avl_bus_priority_encoder_inst0(
  .in (encoder_in),
  .out(encoder_out)
);

endmodule
