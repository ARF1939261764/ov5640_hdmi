`timescale 1ns/100ps

module sccb_controller_tb;

logic       clk;
logic       rest_n;
logic[7:0]  device_addr;
logic[15:0] sub_addr;
logic       read;
logic       write;
logic[7:0]  write_data;
logic       request_ready;
logic[7:0]  read_data;
logic       resp_valid;
logic       resp_ready;
wire        sccb_scl;
wire        sccb_sda;

sccb_controller #(
  .SCL_DIV       (100),
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
  .request_ready(request_ready),
  .read_data    (read_data    ),
  .resp_valid   (resp_valid   ),
  .resp_ready   (resp_ready   ),
  .sccb_scl     (sccb_scl     ),
  .sccb_sda     (sccb_sda     )
);

initial begin
  clk = 0;
  rest_n =0;
  read =0;
  write =0;
  resp_ready  = 1;
  #100 rest_n = 1;
  #20;
  device_addr = 8'hA4;
  sub_addr    = 16'h5A98;
  read        = 0;
  write       = 1;
  write_data  = 8'h23;
  #30;
  read  = 0;
  write = 0;
end

always #10 clk = ~clk;

endmodule