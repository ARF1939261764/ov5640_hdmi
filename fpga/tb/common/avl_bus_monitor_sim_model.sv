`timescale 1ns/100ps
import avl_bus_type::*;
module avl_bus_monitor_sim_model #(
  parameter     MASTER_NUM                    = 8,
                SLAVE_NUM                     = 16,
                RECORD_SEND_CMD_EN            = 1,
            int ADDR_MAP_TAB_FIELD_LEN[0:31]  = '{32{32'd22}},
            int ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{32{1'd0}}
)(
  input                       clk,
  input                       rest,
  i_avl_bus.monitor           avl_mon[MASTER_NUM-1:0],
  output read_cmd_res_t       read_res[MASTER_NUM-1:0]
);
/********************************************************
变量
********************************************************/
logic[3:0][7:0]           ram[SLAVE_NUM-1:0][];
read_cmd_res_t            read_cmd_res_queue[$];
logic[MASTER_NUM-1:0]     read_data_valid;
virtual i_avl_bus.monitor avl_vmon[MASTER_NUM-1:0];
int master;
int monitor_read_write_info;

generate
  genvar i;
  for(i=0;i<MASTER_NUM;i++) begin:block_init_vi
    assign avl_vmon[i]=avl_mon[i];
  end
endgenerate

initial begin
  monitor_read_write_info=$fopen("monitor_read_write_info.txt","w");
end

/********************************************************
地址映射函数
********************************************************/
function int addr_map(logic[31:0] addr);
  int i;
  logic[31:0] addr0,addr1;
  for(i=0;i<SLAVE_NUM;i++) begin
    addr0=addr/(2**(32-ADDR_MAP_TAB_FIELD_LEN[i]));
    addr1=ADDR_MAP_TAB_ADDR_BLOCK[i]/(2**(32-ADDR_MAP_TAB_FIELD_LEN[i]));
    if(addr0==addr1) begin
      break;
    end
  end
  if(i==SLAVE_NUM) begin
    $error("Invalid address:%h",addr);
    $stop();
  end
  return i;
endfunction
/********************************************************
记录成功发出的命令
********************************************************/
function void record_read_write_info(int read,int write,int master,int addr,int byte_en,int data);
  $fdisplay(monitor_read_write_info,"%s,%2d,%h,%1h,%h,%t",read?"r":"w",master,addr,byte_en,data,$realtime);
endfunction

/********************************************************
监控写操作
********************************************************/
always @(posedge clk or negedge rest) begin:block_0
  int i,j,index;
  if(!rest) begin
    for(i=0;i<SLAVE_NUM;i++) begin
      /*申请内存*/
      if(ram[i].size!=0) begin
        ram[i].delete();/*如果大小不为0,则清空后再申请*/
      end
      ram[i]=new[2**(32-ADDR_MAP_TAB_FIELD_LEN[i])/4];
      for(j=0;j<2**(32-ADDR_MAP_TAB_FIELD_LEN[i])/4;j++) begin
        ram[i][j]=0;
      end
    end
  end
  else begin
    for(i=0;i<MASTER_NUM;i++) begin
      if(avl_vmon[i].write&&avl_vmon[i].request_ready) begin
        /*发送写命令成功*/
        index=addr_map(avl_vmon[i].address);
        if(avl_vmon[i].byte_en[0]) ram[index][(avl_vmon[i].address-ADDR_MAP_TAB_ADDR_BLOCK[index])/4][0]=avl_vmon[i].write_data[ 7: 0];
        if(avl_vmon[i].byte_en[1]) ram[index][(avl_vmon[i].address-ADDR_MAP_TAB_ADDR_BLOCK[index])/4][1]=avl_vmon[i].write_data[15: 8];
        if(avl_vmon[i].byte_en[2]) ram[index][(avl_vmon[i].address-ADDR_MAP_TAB_ADDR_BLOCK[index])/4][2]=avl_vmon[i].write_data[23:16];
        if(avl_vmon[i].byte_en[3]) ram[index][(avl_vmon[i].address-ADDR_MAP_TAB_ADDR_BLOCK[index])/4][3]=avl_vmon[i].write_data[31:24];
      end
    end
  end
end
/********************************************************
监控读操作
********************************************************/
/*监视总线*/
always @(posedge clk or negedge rest) begin:block_1
  int i,index;
  read_cmd_res_t read_cmd_res;
  if(!rest) begin
    i=0;
    master=0;
    read_cmd_res_queue = {};
    read_data_valid=0;
  end
  else begin
    for(i=0;i<MASTER_NUM;i++) begin
      if(avl_vmon[i].read&&avl_vmon[i].request_ready) begin
        /*成功发出一条读指令,压入fifo*/
        index=addr_map(avl_vmon[i].address);
        read_cmd_res.addr   = avl_vmon[i].address;
        read_cmd_res.master = i;
        read_cmd_res.slave  = index;
        read_cmd_res.byte_en= avl_vmon[i].byte_en;
        read_cmd_res.value  = ram[read_cmd_res.slave][(read_cmd_res.addr-ADDR_MAP_TAB_ADDR_BLOCK[read_cmd_res.slave])/4];
        read_cmd_res_queue.push_front(read_cmd_res);
      end
      if(avl_vmon[i].read_data_valid&&avl_vmon[i].resp_ready) begin
        read_data_valid[i]=0;
      end
    end
    if(read_data_valid[master]&&avl_vmon[master].read_data_valid&&avl_vmon[master].resp_ready) begin
      read_data_valid[master]=0;
    end
    if((read_cmd_res_queue.size()>0)&&!read_data_valid[master]) begin
      read_cmd_res=read_cmd_res_queue.pop_back();
      read_cmd_res.fifo_size=read_cmd_res_queue.size();
      read_data_valid[read_cmd_res.master]=1;
      master=read_cmd_res.master;
      read_res[read_cmd_res.master]=read_cmd_res;
    end
  end
end
/*成功发送的命令*/
always @(posedge clk) begin:block_4
  int i;
  for(i=0;i<MASTER_NUM;i++) begin
    if(RECORD_SEND_CMD_EN&&(avl_vmon[i].request_ready&&(avl_vmon[i].write||avl_vmon[i].read))) begin
      record_read_write_info(avl_vmon[i].read,avl_vmon[i].write,i,avl_vmon[i].address,avl_vmon[i].byte_en,avl_vmon[i].write_data);
    end
  end
end

/********************************************************
监控MASTER_NUM个主机接口一次发出了多少个命令
********************************************************/
always @(posedge clk) begin:block_3
  int i,count;
  count=0;
  for(i=0;i<MASTER_NUM;i++) begin
    if((avl_vmon[i].read||avl_vmon[i].write)&&avl_vmon[i].request_ready) begin
      count++;
    end
  end
  if(count>1) begin
    $error("More than one instruction is issued at a time");
    $stop();
  end
end

endmodule
