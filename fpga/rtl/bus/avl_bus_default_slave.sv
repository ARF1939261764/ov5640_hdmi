module avl_bus_default_slave(
  i_avl_bus.slave avl_s
);

assign avl_s.request_ready   ='d0;
assign avl_s.read_data       ='d0;
assign avl_s.read_data_valid ='d0;

endmodule
