`timescale 1ns/100ps

module sccb_controller_tb;

logic       clk;
logic       rest_n;
logic[7:0]  device_addr;
logic[15:0] sub_addr;
logic       read;
logic       write;
logic[7:0]  write_data;
logic       request_done;
logic[7:0]  read_data;
logic       resp_valid;
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
  .request_done (request_done ),
  .read_data    (read_data    ),
  .resp_valid   (resp_valid   ),
  .sccb_scl     (sccb_scl     ),
  .sccb_sda     (sccb_sda     )
);

initial begin
  clk = 0;
  rest_n =0;
  read =0;
  write =0;
  #100 rest_n = 1;
  #20;
  device_addr = 8'hA4;
  sub_addr    = 16'h5A98;
  read        = 1;
  write       = 0;
  write_data  = 8'h23;
end

pulldown(sccb_sda);

always #10 clk = ~clk;

endmodule