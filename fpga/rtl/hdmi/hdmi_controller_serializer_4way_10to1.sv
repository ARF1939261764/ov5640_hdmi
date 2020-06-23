`include "hdmi_controller_define.sv"
module hdmi_controller_serializer_4way_10to1 (
  input  logic      pixel_clk_5x,
  input  logic      rest_n,
  input  logic[9:0] data[3:0],
  output logic      data_out_p[3:0],
  output logic      data_out_n[3:0]
);

logic[2:0] cnt;

always @(posedge pixel_clk_5x or negedge rest_n) begin
  if(!rest_n) begin
    cnt <= 3'd0;
  end
  else begin
    cnt <= cnt[2]?3'd0:cnt+3'd1;
  end
end

logic[9:0] tmds_data[3:0];

always @(posedge pixel_clk_5x) begin:shift_block
  int i;
  for(i=0;i<4;i++) begin
    tmds_data[i]<=cnt[2]?data[i]:{2'd0,tmds_data[i][9:2]};
  end
end

/*serialization*/
`ifdef FPGA_TYPE_ALTERA_CYCLONE10LP
  /*p*/
  altddio_out	altddio_out_inst0_p (	
				.datain_h   ({tmds_data[3][0],tmds_data[2][0],tmds_data[1][0],tmds_data[0][0]}),
				.datain_l   ({tmds_data[3][1],tmds_data[2][1],tmds_data[1][1],tmds_data[0][1]}),
				.outclock   (pixel_clk_5x                                                     ),
				.dataout    ({data_out_p[3],data_out_p[2],data_out_p[1],data_out_p[0]}        ),
				.aclr       (1'b0     ),
				.aset       (1'b0     ),
				.oe         (1'b1     ),
				.oe_out     (         ),
				.outclocken (1'b1     ),
				.sclr       (1'b0     ),
				.sset       (1'b0     )
  );
	defparam
		altddio_out_inst0_p.extend_oe_disable = "OFF",
		altddio_out_inst0_p.intended_device_family = "Cyclone 10 LP",
		altddio_out_inst0_p.invert_output = "OFF",
		altddio_out_inst0_p.lpm_hint = "UNUSED",
		altddio_out_inst0_p.lpm_type = "altddio_out",
		altddio_out_inst0_p.oe_reg = "UNREGISTERED",
		altddio_out_inst0_p.power_up_high = "OFF",
		altddio_out_inst0_p.width = 4;
  /*n*/
  altddio_out	altddio_out_inst0_n (	
				.datain_h   (~{tmds_data[3][0],tmds_data[2][0],tmds_data[1][0],tmds_data[0][0]}),
				.datain_l   (~{tmds_data[3][1],tmds_data[2][1],tmds_data[1][1],tmds_data[0][1]}),
				.outclock   (pixel_clk_5x                                                      ),
				.dataout    ({data_out_n[3],data_out_n[2],data_out_n[1],data_out_n[0]}         ),
				.aclr       (1'b0     ),
				.aset       (1'b0     ),
				.oe         (1'b1     ),
				.oe_out     (         ),
				.outclocken (1'b1     ),
				.sclr       (1'b0     ),
				.sset       (1'b0     )
  );
	defparam
		altddio_out_inst0_n.extend_oe_disable = "OFF",
		altddio_out_inst0_n.intended_device_family = "Cyclone 10 LP",
		altddio_out_inst0_n.invert_output = "OFF",
		altddio_out_inst0_n.lpm_hint = "UNUSED",
		altddio_out_inst0_n.lpm_type = "altddio_out",
		altddio_out_inst0_n.oe_reg = "UNREGISTERED",
		altddio_out_inst0_n.power_up_high = "OFF",
		altddio_out_inst0_n.width = 4;
`endif

endmodule