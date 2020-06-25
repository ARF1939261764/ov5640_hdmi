module ov5640(
  input  logic        clk,
  input  logic        rest_n,
  /*ov5640*/
  output logic        ov5640_scl,
  inout  wire         ov5640_sda,
  input  logic        ov5640_vsync,
  input  logic        ov5640_href,
  input  logic        ov5640_pclk,
  output logic        ov5640_xclk,
  input  logic[7:0]   ov5640_data,
  /*SDRAM 芯片接口*/
  output logic        sdram_clk,
  output logic        sdram_cke,
  output logic        sdram_cs_n,
  output logic        sdram_ras_n,
  output logic        sdram_cas_n,
  output logic        sdram_we_n,
  output logic[ 1:0]  sdram_bank,
  output logic[12:0]  sdram_addr,
  inout  wire [15:0]  sdram_data,
  output logic[ 1:0]  sdram_dqm
  /*hdmi控制器*/
  output logic        tmds_red_p,
  output logic        tmds_red_n,
  output logic        tmds_green_p,
  output logic        tmds_green_n,
  output logic        tmds_blue_p,
  output logic        tmds_blue_n,
  output logic        tmds_clk_p,
  output logic        tmds_clk_n
);

logic           write_clk;
logic           write;
logic[15:0]     write_data;
logic           addr_clean;
logic[1:0]      occupy_block_num;
i_avl_bus		 avl_bus_in[3:0]();
i_avl_bus		 avl_bus_out[0:0]();
/********************************************************************************************************
ov5640总线控制器驱动
********************************************************************************************************/
ov5640_controller ov5640_controller_inst0(
  .sccb_clk     (clk          ),
  .rest_n       (rest_n       ),
  .ov5640_scl   (ov5640_scl   ),
  .ov5640_sda   (ov5640_sda   ),
  .ov5640_vsync (ov5640_vsync ),
  .ov5640_href  (ov5640_href  ),
  .ov5640_pclk  (ov5640_pclk  ),
  .ov5640_xclk  (ov5640_xclk  ),
  .ov5640_data  (ov5640_data  ),
  .write_clk    (write_clk    ),
  .write        (write        ),
  .write_data   (write_data   ),
  .addr_clean   (addr_clean   )
);
/********************************************************************************************************
hdmi
********************************************************************************************************/
hdmi_controller (
  .pixe_clk    (),
  .pixe_clk_5x (),
  .rest_n      (),
  .hsync       (),
  .vsync       (),
  .de          (),
  .red         (),
  .green       (),
  .blue        (),
  .tmds_red_p  (),
  .tmds_red_n  (),
  .tmds_green_p(),
  .tmds_green_n(),
  .tmds_blue_p (),
  .tmds_blue_n (),
  .tmds_clk_p  (),
  .tmds_clk_n  ()
);

/********************************************************************************************************
写入到sdram
********************************************************************************************************/
frame_write frame_write_inst0(
  .clk              (clk             ),
  .rest_n           (rest_n          ),
  .fifo_write_clk   (write_clk       ),
  .fifo_write       (write           ),
  .fifo_write_data  (write_data      ),
  .fifo_addr_clean  (addr_clean      ),
  .avl_m0           (avl_bus_in[0]   ),
  .occupy_block_num (occupy_block_num)
);
/********************************************************************************************************
从sdram读取数据
********************************************************************************************************/
frame_read frame_read_inst0(
  .clk            (),
  .rest_n         (),
  .fifo_read_clk  (),
  .fifo_read_resp (),
  .fifo_read_data (),
  .fifo_addr_clean(),
  .avl_s0         (),
  .occupy_block_num_screenshot(),
  .occupy_block_num_write     ()
);

/********************************************************************************************************
4主机,1从机总线控制器
********************************************************************************************************/

avl_bus_default_master avl_bus_default_master_inst0(avl_bus_in[1]);
avl_bus_default_master avl_bus_default_master_inst1(avl_bus_in[2]);
avl_bus_default_master avl_bus_default_master_inst2(avl_bus_in[3]);

avl_bus_n2n #(
  .MASTER_NUM                 (4),
  .SLAVE_NUM                  (1),
  .ARB_METHOD                 (0),
  .BUS_N21_SEL_FIFO_DEPTH     (2),
  .BUS_N21_RES_DATA_FIFO_DEPTH(0),
  .BUS_12N_SEL_FIFO_DEPTH     (2)
)
avl_bus_n2n_inst0(
  .clk    (clk        ),
  .rest   (rest_n     ),
  .avl_in (avl_bus_in ),
  .avl_out(avl_bus_out)
);
/********************************************************************************************************
SDRAM控制器
********************************************************************************************************/
sdram_controller sdram_controller_inst0(
  .clk        (clk           ),
  .rest_n     (rest_n        ),
  .avl_s0     (avl_bus_out[0]),
  .sdram_clk  (sdram_clk     ),
  .sdram_cke  (sdram_cke     ),
  .sdram_cs_n (sdram_cs_n    ),
  .sdram_ras_n(sdram_ras_n   ),
  .sdram_cas_n(sdram_cas_n   ),
  .sdram_we_n (sdram_we_n    ),
  .sdram_bank (sdram_bank    ),
  .sdram_addr (sdram_addr    ),
  .sdram_data (sdram_data    ),
  .sdram_dqm  (sdram_dqm     )
);

endmodule
