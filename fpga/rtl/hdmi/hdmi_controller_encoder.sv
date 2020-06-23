/********************************************************************************
module:hdmi_controller_encoder
description:T.M.D.S. Encode
********************************************************************************/
module hdmi_controller_encoder(
  input  logic       clk,
  input  logic       rest_n,
  input  logic[7:0]  data,
  input  logic       c0,
  input  logic       c1,
  input  logic       de,
  output logic[9:0]  result
);
localparam CNT_WIDTH = 4;
/***Pipeline 1**************************************************/
logic[7:0] data_q1;
logic c0_q1,c1_q1,de_q1;
/***Pipeline 2**************************************************/
logic[3:0] n1d;
logic decision1;
logic[8:0] qm;
logic[8:0] qm_q2;
logic c0_q2,c1_q2,de_q2;

assign n1d =  data_q1[0]+data_q1[1]+
              data_q1[2]+data_q1[3]+
              data_q1[4]+data_q1[5]+
              data_q1[6]+data_q1[7];

assign decision1 = (n1d>4'd4)||((n1d==4'd4)&&(data_q1[0]==1'd0));

assign qm[0] = data_q1[0];
assign qm[1] = qm[0]^(decision1?~data_q1[1]:data_q1[1]);
assign qm[2] = qm[1]^(decision1?~data_q1[2]:data_q1[2]);
assign qm[3] = qm[2]^(decision1?~data_q1[3]:data_q1[3]);
assign qm[4] = qm[3]^(decision1?~data_q1[4]:data_q1[4]);
assign qm[5] = qm[4]^(decision1?~data_q1[5]:data_q1[5]);
assign qm[6] = qm[5]^(decision1?~data_q1[6]:data_q1[6]);
assign qm[7] = qm[6]^(decision1?~data_q1[7]:data_q1[7]);
assign qm[8] = decision1?1'd0:1'd1;

/***Pipeline 3**************************************************/
logic[3:0] n1qm,n0qm;

logic[3:0] n1qm_q3,n0qm_q3;
logic[8:0] qm_q3;
logic[9:0] qout_de0,qout_de0_q3;
logic de_q3;
logic n1qm_greater_n0qm,n1qm_greater_n0qm_q3;
logic n0qm_greater_n1qm,n0qm_greater_n1qm_q3;

assign n1qm = qm_q2[0]+qm_q2[1]+
              qm_q2[2]+qm_q2[3]+
              qm_q2[4]+qm_q2[5]+
              qm_q2[6]+qm_q2[7];
assign n0qm = !qm_q2[0]+!qm_q2[1]+
              !qm_q2[2]+!qm_q2[3]+
              !qm_q2[4]+!qm_q2[5]+
              !qm_q2[6]+!qm_q2[7];
assign n1qm_greater_n0qm = n1qm > n0qm;
assign n0qm_greater_n1qm = n0qm > n1qm;
always @(*) begin
  case({c1_q2,c0_q2})
    2'd0:qout_de0 = 10'b1101010100;
    2'd1:qout_de0 = 10'b0010101011;
    2'd2:qout_de0 = 10'b0101010100;
    2'd3:qout_de0 = 10'b1010101011;
  endcase
end
/***Pipeline 4**************************************************/
logic signed[CNT_WIDTH-1:0] cnt,cnt_t;
logic[9:0] qout;
logic decision2,decision3,decision4;

assign decision2  = (cnt == 'd0)||(n1qm_q3==n0qm_q3);
assign decision3  = ((!cnt[CNT_WIDTH-1])&&n1qm_greater_n0qm_q3)||
                    ((cnt[CNT_WIDTH-1])&&n0qm_greater_n1qm_q3);
assign decision4  = !qm_q3[8];

always @(*) begin
	if(decision2) begin
    qout = {~qm_q3[8],qm_q3[8],qm_q3[8]?qm_q3[7:0]:~qm_q3[7:0]};
    if(decision4) begin
      cnt_t = cnt+n0qm_q3-n1qm_q3;
    end
    else begin
      cnt_t = cnt+n1qm_q3-n0qm_q3;
    end
  end
  else begin
    if(decision3) begin
      qout = {1'd1,qm_q3[8],~qm_q3[7:0]};
      cnt_t = cnt+{qm_q3[8],1'd0}+n0qm_q3-n1qm_q3;
    end
    else begin
      qout = {1'd0,qm_q3[8],qm_q3[7:0]};
      cnt_t = cnt-{~qm_q3[8],1'd0}+n1qm_q3-n0qm_q3;
    end
  end
end
/***register group**************************************************/
/*other*/
always @(posedge clk) begin
  /*1*/
  data_q1 <= data;
  c0_q1   <= c0;
  c1_q1   <= c1;
  de_q1   <= de;
  /*2*/
  qm_q2   <= qm;
  c0_q2   <= c0_q1;
  c1_q2   <= c1_q1;
  de_q2   <= de_q1;
  /*3*/
  n1qm_greater_n0qm_q3 <= n1qm_greater_n0qm;
  n0qm_greater_n1qm_q3 <= n0qm_greater_n1qm;
  qout_de0_q3          <= qout_de0;
  n1qm_q3 <= n1qm;
  n0qm_q3 <= n0qm;
  qm_q3   <= qm_q2;
  de_q3   <= de_q2;
  /*4*/
  result  <= de_q3?qout:qout_de0_q3;
end
/*cnt*/
always @(posedge clk or negedge rest_n) begin
  if(!rest_n) begin
    cnt <= 'd0;
  end
  else begin
    cnt <= de_q3?cnt_t:1'd0;
  end
end

endmodule
