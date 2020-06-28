`include "hdmi_controller_define.sv"
module dmt_timing_generate(
  input  logic pixe_clk,
  input  logic rest_n,
  output logic vsycn,
  output logic hsync,
  output logic de
);

`ifdef  VIDEO_1280_720
  parameter int H_ACTIVE  = 16'd1280;
  parameter int H_FP      = 16'd110; 
  parameter int H_SYNC    = 16'd40;  
  parameter int H_BP      = 16'd220; 
  parameter int V_ACTIVE  = 16'd720; 
  parameter int V_FP      = 16'd5;   
  parameter int V_SYNC    = 16'd5;   
  parameter int V_BP      = 16'd20;  
  parameter 	 HS_POL    = 1'b1;    
  parameter 	 VS_POL    = 1'b1;    
`endif

/*1024x768 65Mhz*/
`ifdef  VIDEO_1024_768
  parameter int H_ACTIVE  = 16'd1024;
  parameter int H_FP      = 16'd24;      
  parameter int H_SYNC    = 16'd136;   
  parameter int H_BP      = 16'd160;     
  parameter int H_TT      = H_SYNC+H_BP+H_ACTIVE+H_FP;
  parameter int V_ACTIVE  = 16'd768; 
  parameter int V_FP      = 16'd3;      
  parameter int V_SYNC    = 16'd6;    
  parameter int V_BP      = 16'd29;
  parameter int V_TT      = (V_SYNC+V_BP+V_ACTIVE+V_FP)*H_TT;  
  parameter 	 HS_POL    = 1'b0;
  parameter 	 VS_POL    = 1'b0;
`endif

logic       vde;
logic       hde_t;
logic[31:0] vcount;
logic[15:0] hcount;

assign vde      = (vcount>=(V_SYNC+V_BP)*H_TT)&(vcount<(V_SYNC+V_BP+V_ACTIVE)*H_TT);
assign vsycn_t  = (vcount<(V_SYNC*H_TT-1'd1))?VS_POL:~VS_POL;
assign hde_t    = vde&&(hcount>=H_SYNC+H_BP)&(hcount<H_SYNC+H_BP+H_ACTIVE);
assign hsync_t  = (hcount<H_SYNC)?HS_POL:~HS_POL;

always @(posedge pixe_clk) begin
  hsync <= hsync_t;
  vsycn <= vsycn_t;
  de    <= hde_t;
end

always @(posedge pixe_clk or negedge rest_n) begin
  if(!rest_n) begin
    vcount <= 1'd0;
    hcount <= 1'd0;
  end
  else begin
    /*场同步计数器*/
    if(vcount == V_TT-1'd1) begin
      vcount <= 1'd0;
    end
    else begin
      vcount <= vcount + 1'd1;
    end
    /*行同步计数器*/
    if((hcount == H_TT-1'd1)||(vcount == V_TT-1'd1)) begin
      hcount <= 1'd0;
    end
    else begin
      hcount <= hcount + 1'd1;
    end
  end
end

initial begin
  $display("VTT=%d",V_TT);
end

endmodule