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
  /*hdmi*/
  output logic        tmds_red_p,
  output logic        tmds_red_n,
  output logic        tmds_green_p,
  output logic        tmds_green_n,
  output logic        tmds_blue_p,
  output logic        tmds_blue_n,
  output logic        tmds_clk_p,
  output logic        tmds_clk_n,
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
);
logic           ov5640_clk;
logic           sccb_clk;
logic           video_pixe_clk;
logic           video_pixe_clk_5x;
logic           sys_clk;
logic           write_clk;
logic           write;
logic[15:0]     write_data;
logic           addr_clean;
logic[1:0]      occupy_block_num;
i_avl_bus       avl_bus_in[1:0]();
i_avl_bus       avl_bus_out[0:0]();

logic[15:0]     fifo_read_data;

logic           vsycn;
logic           hsync;
logic           de;

assign sccb_clk = clk;
pll_0 pll_0_inst0(
  .inclk0 (clk       ),
  .c0     (ov5640_clk),
  .c1     (sys_clk   )
);
pll_1 pll_1_inst0(
  .inclk0 (clk              ),
  .c0     (video_pixe_clk   ),
  .c1     (video_pixe_clk_5x)
);

/********************************************************************************************************
ov5640总线控制器驱动
********************************************************************************************************/
ov5640_controller ov5640_controller_inst0(
  .ov5640_clk   (ov5640_clk   ),
  .sccb_clk     (sccb_clk     ),
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
写入到sdram
********************************************************************************************************/
frame_write frame_write_inst0(
  .clk              (sys_clk         ),
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
  .clk            (sys_clk          ),
  .rest_n         (rest_n           ),
  .fifo_read_clk  (video_pixe_clk   ),
  .fifo_read_resp (de               ),
  .fifo_read_data (fifo_read_data   ),
  .fifo_addr_clean(!vsycn           ),
  .avl_m0         (avl_bus_in[1]    ),
  .occupy_block_num_screenshot(2'd3 ),
  .occupy_block_num_write     (occupy_block_num)
);

/********************************************************************************************************
hdmi
********************************************************************************************************/
hdmi_controller hdmi_controller_inst0(
  .pixe_clk    (video_pixe_clk       ),
  .pixe_clk_5x (video_pixe_clk_5x    ),
  .rest_n      (rest_n               ),
  .hsync       (hsync                ),
  .vsync       (vsycn                ),
  .de          (de                   ),
  .red         (fifo_read_data[15:11]),
  .green       (fifo_read_data[10:5] ),
  .blue        (fifo_read_data[4:0]  ),
  .tmds_red_p  (tmds_red_p           ),
  .tmds_red_n  (tmds_red_n           ),
  .tmds_green_p(tmds_green_p         ),
  .tmds_green_n(tmds_green_n         ),
  .tmds_blue_p (tmds_blue_p          ),
  .tmds_blue_n (tmds_blue_n          ),
  .tmds_clk_p  (tmds_clk_p           ),
  .tmds_clk_n  (tmds_clk_n           )
);

/********************************************************************************************************
dmt时序生成
********************************************************************************************************/
dmt_timing_generate dmt_timing_generate_inst0(
  .pixe_clk(video_pixe_clk),
  .rest_n  (rest_n        ),
  .vsycn   (vsycn         ),
  .hsync   (hsync         ),
  .de      (de            )
);

/********************************************************************************************************
4主机,1从机总线控制器
********************************************************************************************************/

//avl_bus_default_master avl_bus_default_master_inst1(avl_bus_in[2]);
//avl_bus_default_master avl_bus_default_master_inst2(avl_bus_in[3]);

avl_bus_n2n #(
  .MASTER_NUM                 (2),
  .SLAVE_NUM                  (1),
  .ARB_METHOD                 (0),
  .BUS_N21_SEL_FIFO_DEPTH     (2),
  .BUS_N21_RES_DATA_FIFO_DEPTH(0),
  .BUS_12N_SEL_FIFO_DEPTH     (2)
)
avl_bus_n2n_inst0(
  .clk    (sys_clk    ),
  .rest   (rest_n     ),
  .avl_in ( ),
  .avl_out(avl_bus_out)
);
/********************************************************************************************************
SDRAM控制器
********************************************************************************************************/
sdram_controller sdram_controller_inst0(
  .clk        (sys_clk       ),
  .rest_n     (rest_n        ),
  .avl_s0     (avl_bus_in[1]),
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
