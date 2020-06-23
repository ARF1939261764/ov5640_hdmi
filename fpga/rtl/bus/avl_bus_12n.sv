`include "avl_bus_define.sv"
import avl_bus_type::*;

module avl_bus_12n #(
  parameter     SLAVE_NUM                     = 4,
                SEL_FIFO_DEPTH                = 4,
            int ADDR_MAP_TAB_FIELD_LEN[0:31]  = '{32{32'd22}},
            int ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{
                            {22'd01,10'd0},{22'd02,10'd0},{22'd03,10'd0},{22'd04,10'd0},
                            {22'd05,10'd0},{22'd06,10'd0},{22'd07,10'd0},{22'd08,10'd0},
                            {22'd09,10'd0},{22'd10,10'd0},{22'd11,10'd0},{22'd12,10'd0},
                            {22'd13,10'd0},{22'd14,10'd0},{22'd15,10'd0},{22'd16,10'd0},
                            {22'd17,10'd0},{22'd18,10'd0},{22'd19,10'd0},{22'd20,10'd0},
                            {22'd21,10'd0},{22'd22,10'd0},{22'd23,10'd0},{22'd24,10'd0},
                            {22'd25,10'd0},{22'd26,10'd0},{22'd27,10'd0},{22'd28,10'd0},
                            {22'd29,10'd0},{22'd30,10'd0},{22'd31,10'd0},{22'd32,10'd0}
                          }
)(
  input  logic     clk,
  input  logic     rest,
  i_avl_bus.slave  avl_in,
  i_avl_bus.master avl_out[SLAVE_NUM-1:0]
);
generate
  if(SLAVE_NUM==1) begin
    avl_bus_adapter avl_bus_adapter_inst0(.avl_in(avl_in),.avl_out(avl_out[0]));
  end
  else begin
    /*******************************************************
    参数
    *******************************************************/
    localparam SEL_WIDTH  = $clog2(SLAVE_NUM);
    /*******************************************************
    变量
    *******************************************************/
    logic[SEL_WIDTH-1:0] sel;
    logic                invalid_addr;

    logic                sel_fifo_full;
    logic                sel_fifo_empty;
    logic                sel_fifo_half;
    logic                sel_fifo_write;
    logic                sel_fifo_read;
    logic[SEL_WIDTH-1:0] sel_fifo_writeData;
    logic[SEL_WIDTH-1:0] sel_fifo_readData;

    /*******************************************************
    连线
    *******************************************************/
    genvar i;
    logic[31:0] read_data[SLAVE_NUM-1:0];
    logic[SLAVE_NUM-1:0] read_data_valid,request_ready;
    for(i=0;i<SLAVE_NUM;i++) begin:block_0
      assign avl_out[i].address              = avl_in.address[31-ADDR_MAP_TAB_FIELD_LEN[i]:0];
      assign avl_out[i].byte_en              = avl_in.byte_en;
      assign avl_out[i].read                 = avl_in.read &&(i[SEL_WIDTH-1:0]==sel)&&!invalid_addr&&!sel_fifo_full;
      assign avl_out[i].write                = avl_in.write&&(i[SEL_WIDTH-1:0]==sel)&&!invalid_addr&&!sel_fifo_full;
      assign avl_out[i].write_data           = avl_in.write_data;
      assign avl_out[i].begin_burst_transfer = avl_in.begin_burst_transfer;
      assign avl_out[i].burst_count          = avl_in.burst_count;
      assign request_ready[i]                = avl_out[i].request_ready;

      assign avl_out[i].resp_ready           = avl_in.resp_ready&&(i[SEL_WIDTH-1:0]==sel_fifo_readData)&&!invalid_addr;

      assign read_data[i]                    = avl_out[i].read_data;
      assign read_data_valid[i]              = avl_out[i].read_data_valid;
    end
    assign sel_fifo_write                    = avl_in.read&&avl_in.request_ready;
    assign sel_fifo_writeData                = sel;

    assign avl_in.read_data_valid            = read_data_valid[sel_fifo_readData];
    assign sel_fifo_read                     = avl_in.read_data_valid&&avl_in.resp_ready;

    assign avl_in.request_ready              = request_ready[sel]&&!sel_fifo_full;
    

    /*******************************************************
    实例化module
    *******************************************************/
    /*地址映射*/
    avl_bus_12n_addr_map #(
      .SLAVE_NUM              (SLAVE_NUM              ),
      .ADDR_MAP_TAB_FIELD_LEN (ADDR_MAP_TAB_FIELD_LEN ),
      .ADDR_MAP_TAB_ADDR_BLOCK(ADDR_MAP_TAB_ADDR_BLOCK)
    )
    avl_bus_12n_addr_map_inst0(
      .addr         (avl_in.address),
      .sel          (sel           ),
      .invalid_addr (invalid_addr  )
    );
    /*sel信号fifo*/
    fifo_sync #(
      .DEPTH(SEL_FIFO_DEPTH),  /*允许为0,2,4,8,16*/
      .WIDTH(SEL_WIDTH     )
    )
    fifo_sync_inst0_sel_fifo(
      .clk       (clk               ),
      .rest      (rest              ),
      .flush     (1'd0              ),
      .full      (sel_fifo_full     ),
      .empty     (sel_fifo_empty    ),
      .half      (sel_fifo_half     ),
      .write     (sel_fifo_write    ),
      .read      (sel_fifo_read     ),
      .write_data(sel_fifo_writeData),
      .read_data (sel_fifo_readData )
    );
    /*read_data信号mux*/
    mux_n21 #(
      .WIDTH     (32),
      .NUM       (SLAVE_NUM) 
    )
    mux_n21_resp_mux(
      .sel       (sel_fifo_readData ),
      .in        (read_data         ),
      .out       (avl_in.read_data  )
    );
  end
endgenerate
endmodule
/***********************************************************************************
地址映射模块
***********************************************************************************/
module avl_bus_12n_addr_map #(
  parameter     SLAVE_NUM                     = 16,
  parameter int ADDR_MAP_TAB_FIELD_LEN[0:31]  = '{32{32'd22}},
  parameter int ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{32{1'd0}}
)(
  input  logic[31:0]                  addr,
  output logic[$clog2(SLAVE_NUM)-1:0] sel,
  output logic                        invalid_addr
);
localparam SEL_WIDTH = $clog2(SLAVE_NUM);
/*******************************************************
地址映射
*******************************************************/
generate
  genvar i;
  logic[SLAVE_NUM-1:0] judge;
  for(i=0;i<SLAVE_NUM;i++) begin:block_0
    assign judge[i]=addr[31-:ADDR_MAP_TAB_FIELD_LEN[i]]==ADDR_MAP_TAB_ADDR_BLOCK[i][31-:ADDR_MAP_TAB_FIELD_LEN[i]];
  end
  assign invalid_addr=judge==1'd0;
endgenerate
always @(*) begin:block_1
  int i;
  sel=0;
  for(i=0;i<SLAVE_NUM;i++) begin
    sel=sel|{SEL_WIDTH{judge[i]}}&i[SEL_WIDTH-1:0];
  end
end

endmodule
