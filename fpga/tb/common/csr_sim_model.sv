module csr_sim_model (
  input              clk,
  input  logic       csr_read,
  input  logic[11:0] csr_read_addr,
  output logic[31:0] csr_read_data,
  input  logic       csr_write,
  input  logic[11:0] csr_write_addr,
  input  logic[31:0] csr_write_data
);

logic[31:0] csr[4095:0];

always @(posedge clk) begin
  if(csr_read) begin
    csr_read_data<=csr[csr_read_addr];
  end
  if(csr_write) begin
    csr[csr_write_addr]<=csr_write_data;
  end
end
  
endmodule
