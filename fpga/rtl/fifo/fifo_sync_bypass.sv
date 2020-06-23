/**************************************************************************
带旁路的同步fifo
**************************************************************************/
module fifo_sync_bypass #(
  parameter DEPTH=2,  /*允许为0,2,4,8,16*/
            WIDTH=32
)(
  input  logic              clk,
  input  logic              rest,
  input  logic              flush,
  output logic              full,
  output logic              empty,
  output logic              half,
  input  logic              write,
  input  logic              read,
  input  logic [WIDTH-1:0]  writeData,
  output logic [WIDTH-1:0]  readData,
  output logic [WIDTH-1:0]  allData[(DEPTH==0?1:DEPTH)-1:0]
);
generate
  if(DEPTH==0) begin
    assign full       = !read&&write;
    assign empty      = read||!write;
    assign half       = !read&&write;
    assign readData   = writeData;
    assign allData[0] = 0;
  end
  else begin
    /***************************************************************************
    fif缓存区地址宽度
    ***************************************************************************/
    localparam ADDR_WIDTH=$clog2(DEPTH)+1;

    /***************************************************************************
    寄存器，线网
    ***************************************************************************/
    reg   [WIDTH-1:0]        array[DEPTH-1:0];
    reg   [ADDR_WIDTH-1:0]   front,rear;
    wire  [ADDR_WIDTH-1:0]   count;

    /***************************************************************************
    连线
    ***************************************************************************/
    assign count  =  rear-front;
    assign full   =  ((front[ADDR_WIDTH-1]^rear[ADDR_WIDTH-1])&&(front[ADDR_WIDTH-2:0]==rear[ADDR_WIDTH-2:0]))&&!read;
    assign empty  =   front==rear;
    assign half   =  count>=DEPTH/2;

    /***************************************************************************
    选择器，选择读哪一个数据
    ***************************************************************************/
    always @(*) begin
      case(count)
        0:begin
          readData=writeData;
        end
        default:begin
          readData=array[front[ADDR_WIDTH-2:0]];
        end
      endcase
    end

    /***************************************************************************
    fifo读写控制
    ***************************************************************************/
    always @(posedge clk or negedge rest) begin:fifo_rw_block
      if(!rest) begin:fifo_rw_rest_block
        int i;
        front<=0;
        rear<=0;
        for(i=0;i<DEPTH;i++) begin
          array[i]<=0;
        end
      end
      else begin
        if(flush) begin
          rear  <=1'd0;
          front <=1'd0;
        end
        else begin
          if(write&&!full&&((count!=0)||!read)) begin
            array[rear[ADDR_WIDTH-2:0]]<=writeData;
            rear=rear+1'd1;
          end
          if(read&&!empty) begin
            front=front+1'd1;
          end
        end
      end
    end
    /***************************************************************************
    引出所有数据
    ***************************************************************************/
    always @(*) begin:block_1
      int i;
      for(i=0;i<DEPTH;i++) begin
        allData[i]=array[i];
      end
    end
  end
endgenerate
endmodule

