
int sdram_read_write_record=$fopen("sdram_read_write_record.txt","w");
module sdram_sim_model #(
  parameter         SIZE               = 32*1024,
                    RECORD_SEND_CMD_EN = 0,
                    REQUEST_RANDOM     = 1,
                    DATA_VALID_RANDOM  = 1,
            string  INIT_FILE          = ""
)(
  input  logic        clk,
  input  logic        rest,
  i_avl_bus.slave     avl_m0
);
localparam ADD_WIDTH=($clog2(SIZE)+10)-2;
logic[3:0][7:0] ram[2**ADD_WIDTH];
logic request_ready_mask;
logic read_data_valid_mask;
logic read_data_valid;

/***记录成功发出过的命令***********/
function void record_read_write_info();
  if(avl_m0.write||avl_m0.read) begin
    $fdisplay(sdram_read_write_record,"%s,%h,%1h,%h,%1d,%d,%t",
      avl_m0.write?"w":"r",avl_m0.address,avl_m0.byte_en,avl_m0.write_data,avl_m0.begin_burst_transfer,avl_m0.burst_count,$realtime);
  end
endfunction

always@(posedge clk or negedge rest) begin
  if(!rest) begin
    read_data_valid<=0;
  end
  else begin
    if(avl_m0.write&&avl_m0.request_ready) begin
      if(avl_m0.byte_en[0]) ram[avl_m0.address[ADD_WIDTH+1:2]][0] <= avl_m0.write_data[7:0];
      if(avl_m0.byte_en[1]) ram[avl_m0.address[ADD_WIDTH+1:2]][1] <= avl_m0.write_data[15:8];
      if(avl_m0.byte_en[2]) ram[avl_m0.address[ADD_WIDTH+1:2]][2] <= avl_m0.write_data[23:16];
      if(avl_m0.byte_en[3]) ram[avl_m0.address[ADD_WIDTH+1:2]][3] <= avl_m0.write_data[31:24];
    end 
    if((avl_m0.resp_ready==1)&&avl_m0.read_data_valid) begin
      read_data_valid<=0;
    end
    if(avl_m0.read&&avl_m0.request_ready) begin
      avl_m0.read_data<=ram[avl_m0.address[ADD_WIDTH+1:2]];
      read_data_valid<=1;
    end
  end
end

always @(posedge clk) begin
  if(RECORD_SEND_CMD_EN&&avl_m0.request_ready) begin
    record_read_write_info();
  end
end

assign avl_m0.request_ready=request_ready_mask&&(!read_data_valid||(avl_m0.resp_ready&&avl_m0.read_data_valid));
assign avl_m0.read_data_valid=read_data_valid&&read_data_valid_mask;

always @(posedge clk) begin:block_0
  logic[31:0] temp;
  temp=$random();
  request_ready_mask=REQUEST_RANDOM?(temp[3:0]==0):1;
  read_data_valid_mask=DATA_VALID_RANDOM?(temp[7:4]==0):1;
end

initial begin
  request_ready_mask=0;
  if(INIT_FILE.len>0) begin
    $readmemh(INIT_FILE,ram);
  end
  else begin
    foreach(ram[i]) begin
      ram[i]=0;
    end
  end
end

endmodule