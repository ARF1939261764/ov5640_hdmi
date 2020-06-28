module ov5640_controller (
	input logic        ov5640_clk,
  input logic        sccb_clk,
  input logic        rest_n,
  output logic       ov5640_scl,
  inout  wire        ov5640_sda,
  input  logic       ov5640_vsync,
  input  logic       ov5640_href,
  input  logic       ov5640_pclk,
  output logic       ov5640_xclk,
  input  logic[7:0]  ov5640_data,
  output logic       write_clk,
  output logic       write,
  output logic[15:0] write_data,
  output logic       addr_clean
);
logic[15:0] data_count;
logic last_vsync,now_vsync;
/********************************************************************************************************
检测ov5640_vsync下降沿,生成addr_clean信号
********************************************************************************************************/
always @(posedge ov5640_pclk or negedge rest_n) begin
	if(!rest_n) begin
		last_vsync <= 1'd0;
		now_vsync  <= 1'd0;
	end
	else begin
		last_vsync <= now_vsync;
		now_vsync  <= ov5640_vsync;
	end
end

assign addr_clean = last_vsync & ~now_vsync;
assign write_clk  = ov5640_pclk;

/********************************************************************************************************
将8位数据组合成16位数据
********************************************************************************************************/
always @(posedge ov5640_pclk or negedge rest_n) begin
	if(!rest_n) begin
		data_count <= 1'd0;
	end
	else begin
		if(ov5640_href == 1'd0) begin
			data_count <= 1'd0;
		end
		else begin
			write_data 	<= {write_data[7:0],ov5640_data};
			data_count  <= data_count + 1'd1;
		end
		write <= data_count[0];
	end
end

/********************************************************************************************************
配置模块实例化
********************************************************************************************************/
ov5640_config ov5640_config_inst0(
  .clk        (sccb_clk),
  .rest_n     (rest_n),
  .sccb_scl   (ov5640_scl),
  .sccb_sda   (ov5640_sda),
  .config_done()
);

/********************************************************************************************************
PLL
********************************************************************************************************/
assign ov5640_xclk = ov5640_clk;

endmodule
