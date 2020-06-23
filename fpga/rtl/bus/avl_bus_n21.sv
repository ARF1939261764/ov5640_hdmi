`include "avl_bus_define.sv"
import avl_bus_type::*;

module avl_bus_n21 #(
  parameter ARB_METHOD          = 0,
            MASTER_NUM          = 4,
            ARB_SEL_FIFO_DEPTH  = 8,
            RES_DATA_FIFO_DEPTH = 0
)(
  input  logic     clk,
  input  logic     rest,
  i_avl_bus.slave  avl_in[MASTER_NUM-1:0],  /*外面的主接口会接到这里，所以这里应该为从接口*/
  i_avl_bus.master avl_out
);
generate
  if(MASTER_NUM==1) begin
    avl_bus_adapter avl_bus_adapter_inst0(.avl_in(avl_in[0]),.avl_out(avl_out));
  end
  else begin
    /************************************************
    参数
    ************************************************/
    localparam SEL_WIDTH  = $clog2(MASTER_NUM);
    /************************************************
    变量
    ************************************************/
    genvar i;
    avl_cmd_t             avl_s_cmd[MASTER_NUM-1:0];
    avl_cmd_t             avl_out_cmd,avl_out_cmd_r;
    logic[MASTER_NUM-1:0] avl_s_request;
    logic[SEL_WIDTH-1:0]  sel;

    logic                 cmd_sel_fifo_full;
    logic                 cmd_sel_fifo_empty;
    logic                 cmd_sel_fifo_half;
    logic                 cmd_sel_fifo_write;
    logic                 cmd_sel_fifo_read;
    logic[SEL_WIDTH-1:0]  cmd_sel_fifo_write_data;
    logic[SEL_WIDTH-1:0]  cmd_sel_fifo_read_data;

    logic                 resp_data_fifo_full;
    logic                 resp_data_fifo_empty;
    logic                 resp_data_fifo_half;
    logic                 resp_data_fifo_write;
    logic                 resp_data_fifo_read;
    logic[31:0]           resp_data_fifo_writeData;
    logic[31:0]           resp_data_fifo_readData;

    logic[MASTER_NUM-1:0] resp_ready;
    logic[MASTER_NUM-1:0] read_data_valid;

    /************************************************
    连线
    ************************************************/
    for(i=0;i<MASTER_NUM;i++) begin:block_0
      /*从机指令*/
      assign avl_s_cmd[i].address             = avl_in[i].address;
      assign avl_s_cmd[i].byte_en             = avl_in[i].byte_en;
      assign avl_s_cmd[i].read                = avl_in[i].read;
      assign avl_s_cmd[i].write               = avl_in[i].write;
      assign avl_s_cmd[i].write_data          = avl_in[i].write_data;
      assign avl_s_cmd[i].begin_burst_transfer= avl_in[i].begin_burst_transfer;
      assign avl_s_cmd[i].burst_count         = avl_in[i].burst_count;
      /*各个从机的请求*/
      assign avl_s_request[i]                 = avl_in[i].read|avl_in[i].write;
      /*请求完成*/
      assign avl_in[i].request_ready          = (i[SEL_WIDTH-1:0]==sel)&&avl_out.request_ready&&!cmd_sel_fifo_full;
      /*反馈通道*/
      assign avl_in[i].read_data              = resp_data_fifo_readData;
      assign avl_in[i].read_data_valid        = ((i[SEL_WIDTH-1:0]==cmd_sel_fifo_read_data)&&
                                                (resp_data_fifo_write||!resp_data_fifo_empty));
      /*外部主机是否接受了数据*/
      assign resp_ready[i]                    = avl_in[i].resp_ready;
      assign read_data_valid[i]               = avl_in[i].read_data_valid;
    end
    /*将对应的通道的命令连接到主机接口*/
    assign avl_out.address                    = avl_out_cmd.address;
    assign avl_out.byte_en                    = avl_out_cmd.byte_en;
    assign avl_out.read                       = avl_out_cmd.read&&!cmd_sel_fifo_full;
    assign avl_out.write                      = avl_out_cmd.write&&!cmd_sel_fifo_full;
    assign avl_out.write_data                 = avl_out_cmd.write_data;
    assign avl_out.begin_burst_transfer       = avl_out_cmd.begin_burst_transfer&&!cmd_sel_fifo_full;
    assign avl_out.burst_count                = avl_out_cmd.burst_count;

    assign avl_out_cmd_r.address              = avl_out_cmd.address;  
    assign avl_out_cmd_r.byte_en              = avl_out_cmd.byte_en;  
    assign avl_out_cmd_r.read                 = avl_out_cmd.read&&!cmd_sel_fifo_full;  
    assign avl_out_cmd_r.write                = avl_out_cmd.write&&!cmd_sel_fifo_full;  
    assign avl_out_cmd_r.write_data           = avl_out_cmd.write_data;  
    assign avl_out_cmd_r.begin_burst_transfer = avl_out_cmd.begin_burst_transfer&&!cmd_sel_fifo_full;  
    assign avl_out_cmd_r.burst_count          = avl_out_cmd.burst_count;  

    /*命令发送完成后,将sel信号压入fifo*/
    assign cmd_sel_fifo_write_data            = sel;
    assign cmd_sel_fifo_write                 = avl_out.request_ready&&avl_out.read;
    /*读出cmd_sel*/
    assign cmd_sel_fifo_read                  = read_data_valid[cmd_sel_fifo_read_data]&&resp_ready[cmd_sel_fifo_read_data];
    /*反馈数据压入fifo*/
    assign resp_data_fifo_write               = avl_out.read_data_valid;
    assign resp_data_fifo_writeData           = avl_out.read_data;
    assign resp_data_fifo_read                = resp_ready[cmd_sel_fifo_read_data];
    assign avl_out.resp_ready                 = !resp_data_fifo_full;
    /************************************************
    module实例化
    ************************************************/
    avl_cmd_t_mux #(
      .NUM(MASTER_NUM)
    )
    avl_cmd_t_mux_inst0(
      .in (avl_s_cmd  ),
      .sel(sel        ),
      .out(avl_out_cmd)
    );
    /*仲裁器*/
    avl_bus_n21_arb #(
      .ARB_METHOD(ARB_METHOD),
      .MASTER_NUM(MASTER_NUM)
    )
    avl_bus_n21_arb_inst0(
      .clk                  (clk                  ),
      .rest                 (rest                 ),
      .request              (avl_s_request        ),
      .avl_out_cmd          (avl_out_cmd_r        ),
      .avl_out_request_ready(avl_out.request_ready),
      .sel                  (sel                  )
    );

    fifo_sync #(
      .DEPTH(ARB_SEL_FIFO_DEPTH),
      .WIDTH(SEL_WIDTH)
    )
    fifo_sync_inst0_cmd_sel_fifo(
      .clk        (clk                     ),
      .rest       (rest                    ),
      .flush      (1'd0                    ),
      .full       (cmd_sel_fifo_full       ),
      .empty      (cmd_sel_fifo_empty      ),
      .half       (cmd_sel_fifo_half       ),
      .write      (cmd_sel_fifo_write      ),
      .read       (cmd_sel_fifo_read       ),
      .write_data (cmd_sel_fifo_write_data ),
      .read_data  (cmd_sel_fifo_read_data  )
    );

    fifo_sync_bypass #(
      .DEPTH(RES_DATA_FIFO_DEPTH), /*允许为0,2,4,8,16*/
      .WIDTH(32)
    )
    fifo_sync_bypass_inst0_res_data_fifo(
      .clk       (clk                      ),
      .rest      (rest                     ),
      .flush     (1'd0                     ),
      .full      (resp_data_fifo_full      ),
      .empty     (resp_data_fifo_empty     ),
      .half      (resp_data_fifo_half      ),
      .write     (resp_data_fifo_write     ),
      .read      (resp_data_fifo_read      ),
      .writeData (resp_data_fifo_writeData ),
      .readData  (resp_data_fifo_readData  )
    );
  end
endgenerate

endmodule

