module avl_bus_n2n #(
  parameter     MASTER_NUM                    = 8,
                SLAVE_NUM                     = 16,
                ARB_METHOD                    = 0,
                BUS_N21_SEL_FIFO_DEPTH        = 2,
                BUS_N21_RES_DATA_FIFO_DEPTH   = 0,
                BUS_12N_SEL_FIFO_DEPTH        = 2,
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
  input logic      clk,
  input logic      rest,
  i_avl_bus.slave  avl_in[MASTER_NUM-1:0],
  i_avl_bus.master avl_out[SLAVE_NUM-1:0]
);
/*接口定义*/
i_avl_bus avl_bus_inst0();
/*n21*/
avl_bus_n21 #(
  .ARB_METHOD         (ARB_METHOD                 ),
  .MASTER_NUM         (MASTER_NUM                 ),
  .ARB_SEL_FIFO_DEPTH (BUS_N21_SEL_FIFO_DEPTH     ),
  .RES_DATA_FIFO_DEPTH(BUS_N21_RES_DATA_FIFO_DEPTH)
)
avl_bus_n21_inst0(
  .clk    (clk          ),
  .rest   (rest         ),
  .avl_in (avl_in       ),
  .avl_out(avl_bus_inst0)
);
/*12n*/
avl_bus_12n #(
  .SLAVE_NUM              (SLAVE_NUM              ),
  .SEL_FIFO_DEPTH         (BUS_12N_SEL_FIFO_DEPTH ),
  .ADDR_MAP_TAB_FIELD_LEN (ADDR_MAP_TAB_FIELD_LEN ),
  .ADDR_MAP_TAB_ADDR_BLOCK(ADDR_MAP_TAB_ADDR_BLOCK)
)
avl_bus_12n_inst0(
  .clk    (clk          ),
  .rest   (rest         ),
  .avl_in (avl_bus_inst0),
  .avl_out(avl_out      )
);

endmodule
