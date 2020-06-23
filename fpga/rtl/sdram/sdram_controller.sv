`include "../bus/avl_bus_define.sv"
import avl_bus_type::*;

module sdram_controller #(
  /*clk=100MHZ*/
  parameter T_PowerUp   =  32'd20000,/*上电时间*/
            T_RP        =  8'd2,    /*预充电时间*/
            T_RFC       =  8'd7,    /*自动刷新时间*/
            T_MRD       =  8'd2,    /*设置模式寄存器时间*/
            T_CL        =  8'd3,    /*潜伏期*/
            T_RCD       =  8'd3,    /*行激活到列读写延迟*/
            T_ReadNum   =  8'd2,    /*读出数据的数量*/
            T_WR        =  8'd2,    /*写完后等待的时间*/
            T_REFPERIOD =  200      /*刷新周期*/
  )(
  input  logic        clk,
  input  logic        rest_n,
  i_avl_bus.slave     avl_s0,
  /*SDRAM 芯片接口*/
  output logic        sdram_clk,
  output logic        sdram_cke,
  output logic        sdram_cs_n,
  output logic        sdram_ras_n,
  output logic        sdram_cas_n,
  output logic        sdram_we_n,
  output logic[ 1:0]  sdram_bank,
  output logic[12:0]  sdram_addr,
  inout   wire [15:0] sdram_data,
  output logic[ 1:0]  sdram_dqm
);

logic[31:0] sdram_read_data;
logic       sdram_read_data_valid;
logic       fifo_empty;
logic       fifo_full;
logic       sdram_write;
logic       sdram_read;

assign sdram_read             = avl_s0.read  && (fifo_empty||(!avl_s0.begin_burst_transfer&&!fifo_full));
assign sdram_write            = avl_s0.write;
assign avl_s0.read_data_valid = !fifo_empty;

fifo_sync_ram #(
  .DEPTH(512),
  .WIDTH(32)
)
fifo_sync_ram_inst0(
  .clk        (clk                  ),
  .rest       (rest_n               ),
  .flush      (1'd0                 ),
  .full       (fifo_full            ),
  .empty      (fifo_empty           ),
  .half       (/*none*/             ),
  .write      (sdram_read_data_valid),
  .read       (avl_s0.resp_ready    ),
  .write_data (sdram_read_data      ),
  .read_data  (avl_s0.read_data     )
);

sdram_controller_core #(
  .T_PowerUp  (T_PowerUp  ),
  .T_RP       (T_RP       ),
  .T_RFC      (T_RFC      ),
  .T_MRD      (T_MRD      ),
  .T_CL       (T_CL       ),
  .T_RCD      (T_RCD      ),
  .T_ReadNum  (T_ReadNum  ),
  .T_WR       (T_WR       ),
  .T_REFPERIOD(T_REFPERIOD)
)
sdram_controller_core_inst0(
  .clk                  (clk                         ),
  .rest_n               (rest_n                      ),
  .address              (avl_s0.address              ),
  .byte_en              (avl_s0.byte_en              ),
  .read                 (sdram_read                  ),
  .write                (sdram_write                 ),
  .write_data           (avl_s0.write_data           ),
  .begin_burst_transfer (avl_s0.begin_burst_transfer ),
  .burst_count          (avl_s0.burst_count          ),
  .request_ready        (avl_s0.request_ready        ),
  .read_data            (sdram_read_data             ),
  .read_data_valid      (sdram_read_data_valid       ),
  .sdram_clk            (sdram_clk                   ),
  .sdram_cke            (sdram_cke                   ),
  .sdram_cs_n           (sdram_cs_n                  ),
  .sdram_ras_n          (sdram_ras_n                 ),
  .sdram_cas_n          (sdram_cas_n                 ),
  .sdram_we_n           (sdram_we_n                  ),
  .sdram_bank           (sdram_bank                  ),
  .sdram_addr           (sdram_addr                  ),
  .sdram_data           (sdram_data                  ),
  .sdram_dqm            (sdram_dqm                   )
);

endmodule

module sdram_controller_core #(
  /*clk=100MHZ*/
  parameter T_PowerUp   =  32'd20000,/*上电时间*/
            T_RP        =  8'd2,    /*预充电时间*/
            T_RFC       =  8'd7,    /*自动刷新时间*/
            T_MRD       =  8'd2,    /*设置模式寄存器时间*/
            T_CL        =  8'd3,    /*潜伏期*/
            T_RCD       =  8'd2,    /*行激活到列读写延迟*/
            T_ReadNum   =  8'd2,    /*读出数据的数量*/
            T_WR        =  8'd2,    /*写完后等待的时间*/
            T_REFPERIOD =  200      /*刷新周期*/
  )(
  input  logic         clk,
  input  logic         rest_n,
  input  logic[31:0]   address,
  input  logic[3:0]    byte_en,
  input  logic         read,
  input  logic         write,
  input  logic[31:0]   write_data,
  input  logic         begin_burst_transfer,
  input  logic[7:0]    burst_count,
  output logic         request_ready,
  output logic[31:0]   read_data,
  output logic         read_data_valid,
  /*SDRAM 芯片接口*/
  output logic         sdram_clk,
  output logic         sdram_cke,
  output logic         sdram_cs_n,
  output logic         sdram_ras_n,
  output logic         sdram_cas_n,
  output logic         sdram_we_n,
  output logic[ 1:0]   sdram_bank,
  output logic[12:0]   sdram_addr,
  inout   logic[15:0]  sdram_data,
  output logic[ 1:0]   sdram_dqm
);
/********************************************************************************************************
宏定义
********************************************************************************************************/
/*SDRAM控制信号命令*/
`define    CMD_INIT         5'b01111    /* INITIATE*/
`define    CMD_NOP          5'b10111    /* NOP COMMAND*/
`define    CMD_ACTIVE      5'b10011    /* ACTIVE COMMAND*/
`define    CMD_READ        5'b10101    /* READ COMMADN*/
`define    CMD_WRITE        5'b10100    /* WRITE COMMAND*/
`define    CMD_B_STOP      5'b10110    /* BURST STOP*/
`define    CMD_PRGE        5'b10010    /* PRECHARGE*/
`define    CMD_A_REF        5'b10001    /* AOTO REFRESH*/
`define    CMD_LMR          5'b10000    /* LODE MODE REGISTER*/
`define   CMD_TERMINATE   5'b10110    /*BURST TERMINATE*/

`define end_i_power_up              (power_up_count == T_PowerUp-32'd1)
`define end_i_precharge_all_banks   (count == T_RP-32'd1              )
`define end_i_auto_ref              (count == 2*T_RFC-32'd1           )
`define end_i_set_mode_reg          (count == T_MRD-32'd1             )
`define end_w_auto_ref              (count == T_RFC-32'd1             )
`define end_w_active_row            (count == T_RCD-32'd1             )
`define end_w_read_cmd              (count == T_CL-32'd1              )
`define end_w_read_data             (count == rw_num_t1               )
`define end_w_write_data            (count == rw_num_t2               )/*写完后等两个时钟周期*/
`define end_w_percharge             (count == T_RP-32'd1              )
`define flag_r_send_term            (count == rw_num_t3               )
`define flag_w_send_term            (count == rw_num_t4               )

localparam ModeRegValue={
  3'b000,/*保留*/
  1'b0,/*突发读/写*/
  2'b00,/*保留*/
  {1'd0,T_CL},/*潜伏期为2*/
  1'b0,/*顺序模式*/
  3'b111
};

/********************************************************************************************************
寄存器
********************************************************************************************************/
logic                         sdram_data_dir;
logic[15:0]                   sdram_data_o;
logic[15:0]                   sdram_data_i;
logic[15:0]                   sdram_data_i_buff;
logic[4:0]                    sdram_cmd=`CMD_INIT;
logic                         start_ref=0;
wire                          is_need_ref;
logic[15:0]                   count=0;
logic[31:0]                   power_up_count = 0;
logic[15:0]                   rw_num_t1;
logic[15:0]                   rw_num_t2;
logic[15:0]                   rw_num_t3;
logic[15:0]                   rw_num_t4;
logic[$clog2(`ALV_BURST_MAX_COUNT)+1:0] rw_num;
logic[$clog2(`ALV_BURST_MAX_COUNT)+1:0] rw_count;

/********************************************************************************************************
端口数据
********************************************************************************************************/
assign sdram_data      =  sdram_data_dir?sdram_data_o:16'hzzzz;
assign sdram_data_i   = sdram_data;
assign sdram_clk      =  ~clk;
assign sdram_data_dir = write?1'd1:1'd0;
assign {sdram_cke,sdram_cs_n,sdram_ras_n,sdram_cas_n,sdram_we_n}=sdram_cmd;

/********************************************************************************************************
上电等待
********************************************************************************************************/
always @(posedge clk) begin
  if(!rest_n) begin
    power_up_count=0;
  end
  else begin
    if(power_up_count!=T_PowerUp) begin
      power_up_count++;
    end
  end
end

always @(posedge clk) begin
  rw_num_t1 <= rw_num-1'd1;
  rw_num_t2 <= rw_num-1'd1+T_WR;
  rw_num_t3 <= rw_num-2'd2;
  rw_num_t4 <= rw_num;
end

/********************************************************************************************************
状态机
********************************************************************************************************/
localparam i_power_up             =8'd0,/*等待上电稳定*/
          i_precharge_all_banks   =8'd1,/*给所有的Bank预充电*/
          i_auto_ref              =8'd2,/*自动刷新2次*/
          i_set_mode_reg          =8'd3,/*设置模式寄存器*/
          w_idle                  =8'd4,/*空闲状态*/
          w_auto_ref              =8'd5,/*定时自动刷新*/
          w_active_row            =8'd6,/*激活行*/
          w_read_cmd              =8'd7,/*发出读命令,同时给出数据的列地址*/
          w_read_data             =8'd8,/*读出数据*/
          w_write_data            =8'd9,/*写入数据并等待数据写完*/
          w_percharge             =8'd10;/*预充电(不使用自动预充电)*/

reg[7:0] state;
/*第一段:计算下一个clock的状态*/
always @(posedge clk or negedge rest_n) begin
  if(!rest_n) begin
    state=i_power_up;
  end
  else begin
    case(state)
      i_power_up:begin
          state<=`end_i_power_up?i_precharge_all_banks:i_power_up;/*等一段时间后进入下一个状态*/
        end
      i_precharge_all_banks:begin
          state<=`end_i_precharge_all_banks?i_auto_ref:i_precharge_all_banks;
        end
      i_auto_ref:begin
          state<=`end_i_auto_ref?i_set_mode_reg:i_auto_ref;
        end
      i_set_mode_reg:begin
          state<=`end_i_set_mode_reg?w_idle:i_set_mode_reg;
        end
      w_idle:begin
          if(is_need_ref) begin
            state<=w_auto_ref;
          end
          else begin
            state<=(read|write)?w_active_row:w_idle;
          end
        end
      w_auto_ref:begin
          state<=`end_w_auto_ref?w_idle:w_auto_ref;
        end
      w_active_row:begin
          if(`end_w_active_row) begin
            case({read,write})
              2'b01:state<=w_write_data;
              2'b10:state<=w_read_cmd;
              default:begin
                state<=w_idle;
              end
            endcase
          end
          else begin
            state<=w_active_row;
          end
        end
      w_read_cmd:begin
          state<=`end_w_read_cmd?w_read_data:w_read_cmd;
        end
      w_read_data:begin
          state<=`end_w_read_data?w_percharge:w_read_data;
        end
      w_write_data:begin
          state<=`end_w_write_data?w_percharge:w_write_data;
        end
      default:begin
          state<=i_power_up;
        end
      w_percharge:begin
        state <= `end_w_percharge?w_idle:w_percharge;
      end
    endcase
  end
end
/*第二段:信号输出*/
always @(posedge clk) begin
  case(state)
    i_power_up:begin
        sdram_cmd<=`end_i_power_up?`CMD_NOP:`CMD_INIT;
        /*count自加1*/
        count<=`end_i_power_up?16'd0:(count+16'd1);
      end
    i_precharge_all_banks:begin
        sdram_cmd<=(count==0)?`CMD_PRGE:`CMD_NOP;
        sdram_addr[10]<=1'd1;/*所有Bank预充电*/
        /*count自加1*/
        count<=`end_i_precharge_all_banks?16'd0:(count+16'd1);
      end
    i_auto_ref:begin
        sdram_cmd<=((count==32'd0)||(count==T_RFC))?`CMD_A_REF:`CMD_NOP;
        /*count自加1*/
        count<=`end_i_auto_ref?16'd0:(count+16'd1);
      end
    i_set_mode_reg:begin
        sdram_cmd<=(count==32'd0)?`CMD_LMR:`CMD_NOP;
        sdram_addr=ModeRegValue;
        sdram_bank<=2'd0;
        /*count自加1*/
        count<=`end_i_set_mode_reg?16'd0:(count+16'd1);
      end
    w_idle:begin
        sdram_cmd<=`CMD_NOP;
        count<=16'd0;
        start_ref<=1'd0;
        request_ready<=1'd0;
        rw_num   <= begin_burst_transfer?2'd2*(burst_count+1'd1):2'd2;
        rw_count <= 1'd0;
      end
    w_auto_ref:begin
        start_ref<=(count==32'd0)?1'd1:1'd0;
        sdram_cmd<=(count==32'd0)?`CMD_A_REF:`CMD_NOP;
        /*count自加1*/
        count<=`end_w_auto_ref?16'd0:(count+16'd1);
      end
    w_active_row:begin
        sdram_cmd<=(count==32'd0)?`CMD_ACTIVE:`CMD_NOP;
        sdram_bank<=address[24:23];
        sdram_addr<=address[22:10];
        /*count自加1*/
        count<=`end_w_active_row?16'd0:(count+16'd1);
      end
    w_read_cmd:begin
        sdram_cmd<=(count==32'd0)?`CMD_READ:`CMD_NOP;
        sdram_bank<=address[24:23];
        sdram_addr<={2'd0,1'b1,1'b0,address[9:2],1'b0};/*使能自动预充电*/
        sdram_dqm<=2'b00;
        /*count自加1*/
        count<=`end_w_read_cmd?16'd0:(count+16'd1);
      end
    w_read_data:begin
        read_data        <=  {read_data[15:0],sdram_data_i_buff};
        read_data_valid <=   count[0]?1'd1:1'd0;
        request_ready   <=  count[0]?1'd0:1'd1;
        sdram_dqm        <=  2'b00;
        sdram_cmd       <=  `flag_r_send_term?`CMD_TERMINATE:`CMD_NOP;
        /*count自加1*/
        count            <=  `end_w_read_data?16'd0:(count+16'd1);
      end
    w_write_data:begin
        sdram_bank<=address[24:23];
        sdram_addr<={2'd0,1'b1,1'b0,address[7:0],1'b0};/*使能自动预充电*/
        case(count[0])
          32'd0:begin
              sdram_data_o<=write_data[31:16];
              sdram_dqm<=~byte_en[3:2];
            end
          32'd1:begin
              sdram_data_o<=write_data[15:0];
              sdram_dqm<=~byte_en[1:0];
            end
        endcase
        request_ready   <=  count[0]?1'd0:1'd1;
        if(count==32'd0) begin
          sdram_cmd <= `CMD_WRITE;
        end
        else begin
          sdram_cmd <= `flag_w_send_term?`CMD_TERMINATE:`CMD_NOP;
        end
        /*count自加1*/
        count<=`end_w_write_data?16'd0:(count+16'd1);
      end
    w_percharge:begin
        read_data_valid<=1'd0;
        sdram_cmd<=(count==32'd0)?`CMD_PRGE:`CMD_NOP;
        sdram_addr[10]<=1'd1;
        /*count自加1*/
        count<=`end_w_percharge?16'd0:(count+16'd1);
      end
    default:begin
      end
  endcase
end

/********************************************************************************************************
刷新计数器
********************************************************************************************************/
reg[31:0] ref_count=32'd0;
assign is_need_ref=ref_count==32'd0;
always @(posedge clk or negedge rest_n) begin
  if(!rest_n) begin
    ref_count<=32'd0;
  end
  else begin
    if(start_ref) begin
      ref_count<=T_REFPERIOD;
    end
    else begin
      ref_count<=is_need_ref?ref_count:(ref_count-32'd1);
    end
  end
end

always @(negedge clk) begin
  sdram_data_i_buff<=sdram_data_i;
end

endmodule
