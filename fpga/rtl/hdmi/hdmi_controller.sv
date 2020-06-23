module hdmi_controller (
  input  logic       pixe_clk,
  input  logic       pixe_clk_5x,
  input  logic       rest_n,
  input  logic       hsync,
  input  logic       vsync,
  input  logic       de,
  input  logic[7:0]  red,
  input  logic[7:0]  green,
  input  logic[7:0]  blue,
  output logic       tmds_red_p,
  output logic       tmds_red_n,
  output logic       tmds_green_p,
  output logic       tmds_green_n,
  output logic       tmds_blue_p,
  output logic       tmds_blue_n,
  output logic       tmds_clk_p,
  output logic       tmds_clk_n
);

logic[9:0] encode_red,encode_green,encode_blue;
logic[9:0] tmds_data[3:0];
logic      tmds_data_out_p[3:0],tmds_data_out_n[3:0];

assign tmds_data[3] = 10'b1111100000;
assign tmds_data[2] = encode_red;
assign tmds_data[1] = encode_green;
assign tmds_data[0] = encode_blue;

assign tmds_clk_p   = tmds_data_out_p[3];
assign tmds_red_p   = tmds_data_out_p[2];
assign tmds_green_p = tmds_data_out_p[1];
assign tmds_blue_p  = tmds_data_out_p[0];

assign tmds_clk_n   = tmds_data_out_n[3];
assign tmds_red_n   = tmds_data_out_n[2];
assign tmds_green_n = tmds_data_out_n[1];
assign tmds_blue_n  = tmds_data_out_n[0];


hdmi_controller_encoder hdmi_controller_encoder_inst0_blue(
  .clk    (pixe_clk     ),
  .rest_n (rest_n       ),
  .data   (blue         ),
  .c0     (hsync        ),
  .c1     (vsync        ),
  .de     (de           ),
  .result (encode_blue  )
);

hdmi_controller_encoder hdmi_controller_encoder_inst1_green(
  .clk    (pixe_clk     ),
  .rest_n (rest_n       ),
  .data   (green        ),
  .c0     (1'd0         ),
  .c1     (1'd0         ),
  .de     (de           ),
  .result (encode_green )
);

hdmi_controller_encoder hdmi_controller_encoder_inst2_red(
  .clk    (pixe_clk     ),
  .rest_n (rest_n       ),
  .data   (red          ),
  .c0     (1'd0         ),
  .c1     (1'd0         ),
  .de     (de           ),
  .result (encode_red   )
);

hdmi_controller_serializer_4way_10to1 hdmi_controller_serializer_4way_10to1(
    .pixel_clk_5x (pixe_clk_5x     ),
    .rest_n       (rest_n          ),
    .data         (tmds_data       ),
    .data_out_p   (tmds_data_out_p ),
    .data_out_n   (tmds_data_out_n )
);


endmodule
