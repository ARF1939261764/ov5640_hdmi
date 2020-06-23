module avl_bus_default_master(
  i_avl_bus.master avl_m
);

assign avl_m.address              ='d0;
assign avl_m.byte_en              ='d0;
assign avl_m.read                 ='d0;
assign avl_m.write                ='d0;
assign avl_m.write_data           ='d0;
assign avl_m.begin_burst_transfer ='d0;
assign avl_m.burst_count          ='d0;
assign avl_m.resp_ready           ='d0;

endmodule
