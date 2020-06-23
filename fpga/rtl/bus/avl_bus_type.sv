package avl_bus_type;

typedef struct
{
  logic[31:0] address;
  logic[3:0]  byte_en;
  logic       read;
  logic       write;
  logic[31:0] write_data;
  logic       begin_burst_transfer;
  logic[7:0]  burst_count;
}avl_cmd_t;

typedef struct
{
  logic[31:0] addr;
  int master;
  int slave;
  logic[31:0] value;
  logic[3:0] byte_en;
  int fifo_size;
}read_cmd_res_t;

endpackage
/*******************************************************
这里定义一组地址映射表Demo,供仿真和后续自定义地址映射表时参考使用
note:
  这里参数数组的下标,是从0->31
*******************************************************/
parameter int AVL_BUS_DEMO_ADDR_MAP_TAB_FIELD_LEN[0:31]  = '{
              1,16,16,16,16,16,16,16,
              0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0
            };
parameter int AVL_BUS_DEMO_ADDR_MAP_TAB_ADDR_BLOCK[0:31] = '{
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000,
              32'h00000000,32'h80000000,32'h80010000,32'h80020000,32'h80030000,32'h80040000,32'h80050000,32'h80060000
            };
