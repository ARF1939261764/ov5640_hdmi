`timescale 1ns/10ps

module sdram_controller_tb;

logic        clk;
logic        rest_n;
logic        sdram_clk;
logic        sdram_cke;
logic        sdram_cs_n;
logic        sdram_ras_n;
logic        sdram_cas_n;
logic        sdram_we_n;
logic[ 1:0]  sdram_bank;
logic[12:0]  sdram_addr;
wire [15:0] sdram_data;
logic[ 1:0]  sdram_dqm;

i_avl_bus avl_bus();

sdram_controller sdram_controller_inst0(
  .clk        (clk),
  .rest_n     (rest_n),
  .avl_s0     (avl_bus),
  .sdram_clk  (sdram_clk  ),
  .sdram_cke  (sdram_cke  ),
  .sdram_cs_n (sdram_cs_n ),
  .sdram_ras_n(sdram_ras_n),
  .sdram_cas_n(sdram_cas_n),
  .sdram_we_n (sdram_we_n ),
  .sdram_bank (sdram_bank ),
  .sdram_addr (sdram_addr ),
  .sdram_data (sdram_data ),
  .sdram_dqm  (sdram_dqm  )
);

sdr sdr_inst0(
  .Dq   (sdram_data ), 
  .Addr (sdram_addr ), 
  .Ba   (sdram_bank ), 
  .Clk  (sdram_clk  ), 
  .Cke  (sdram_cke  ), 
  .Cs_n (sdram_cs_n ),
  .Ras_n(sdram_ras_n), 
  .Cas_n(sdram_cas_n), 
  .We_n (sdram_we_n ), 
  .Dqm  (sdram_dqm  )
);

initial begin
  clk = 0;
  rest_n = 0;
  avl_bus.write = 0;
  avl_bus.read  = 0;
  #100;
  rest_n =1;
  #100;
  avl_bus.address              = 0;
  avl_bus.byte_en              = 15;
  avl_bus.write                = 1;
  avl_bus.read                 = 0;
  avl_bus.write_data           = 32'h12345678;
  avl_bus.begin_burst_transfer = 1'd1;
  avl_bus.burst_count          = 8'd255;
  avl_bus.resp_ready           = 1'd0;
end

always #3.76 clk = ~clk;

endmodule

