module sccb_controller_test_ov5640(
  input  logic      clk,
  input  logic      rest_n,
  output logic      ov5640_xclk,
  output logic      sccb_scl,
  inout  wire       sccb_sda,
  output logic[7:0] sccb_read_data,
  output logic      signal_tap_clk
);

initial begin
  ov5640_xclk = 0;
end


logic[7:0]  device_addr;
logic[15:0] sub_addr;
logic       read;
logic       write;
logic[7:0]  write_data;
logic       request_done;
logic[7:0]  read_data;
logic       resp_valid;
logic       resp_ready;

reg[31:0] power_up_time;

always @(posedge clk or negedge rest_n) begin
	if(!rest_n) begin
		power_up_time = 0;
	end
	else begin
		if(power_up_time<10000000) begin
			power_up_time = power_up_time + 1;
		end
	end
end

assign device_addr = 8'h78;
assign sub_addr    = 16'h300E;
assign read        = power_up_time > 5000000;
assign write       = 1'd0;
assign write_data  = 8'h55;
assign resp_ready  = 1'd1;

assign sccb_read_data = read_data;


sccb_controller #(
  .SCL_DIV       (2500),
  .SUB_ADDR_WIDTH(16)
)
sccb_controller_inst0(
  .clk          (clk          ),
  .rest_n       (rest_n       ),
  .device_addr  (device_addr  ),
  .sub_addr     (sub_addr     ),
  .read         (read         ),
  .write        (write        ),
  .write_data   (write_data   ),
  .request_done (request_done),
  .read_data    (read_data    ),
  .resp_valid   (resp_valid   ),
  .resp_ready   (resp_ready   ),
  .sccb_scl     (sccb_scl     ),
  .sccb_sda     (sccb_sda     )
);

logic[15:0] count = 0;
always @(posedge clk) begin
	ov5640_xclk = ~ov5640_xclk;
	if(count == 124) begin
		count 			<= 0;
		signal_tap_clk <= ~signal_tap_clk;
	end
	else begin
		count++;
	end
end


endmodule
