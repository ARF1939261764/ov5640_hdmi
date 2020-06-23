module avl_bus_adapter (
  i_avl_bus.slave   avl_in,
  i_avl_bus.master  avl_out
);

assign avl_out.address              = avl_in.address;
assign avl_out.byte_en              = avl_in.byte_en;
assign avl_out.read                 = avl_in.read;
assign avl_out.write                = avl_in.write;
assign avl_out.write_data           = avl_in.write_data;
assign avl_out.begin_burst_transfer = avl_in.begin_burst_transfer;
assign avl_out.burst_count          = avl_in.burst_count;
assign avl_out.resp_ready           = avl_in.resp_ready;
assign avl_in.read_data             = avl_out.read_data;
assign avl_in.read_data_valid       = avl_out.read_data_valid;
assign avl_in.request_ready         = avl_out.request_ready;
  
endmodule