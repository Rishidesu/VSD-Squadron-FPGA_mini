`timescale 1ns / 1ps
`default_nettype none

// ================= MEMORY =================
module Memory (
   input clk,
   input [31:0] mem_addr,
   output reg [31:0] mem_rdata,
   input mem_rstrb,
   input [31:0] mem_wdata,
   input [3:0] mem_wmask
);

   reg [31:0] MEM [0:1535];

   initial begin
       $readmemh("firmware.hex", MEM);
   end

   wire [29:0] word_addr = mem_addr[31:2];

   always @(posedge clk) begin
      if(mem_rstrb)
         mem_rdata <= MEM[word_addr];

      if(mem_wmask[0]) MEM[word_addr][7:0]   <= mem_wdata[7:0];
      if(mem_wmask[1]) MEM[word_addr][15:8]  <= mem_wdata[15:8];
      if(mem_wmask[2]) MEM[word_addr][23:16] <= mem_wdata[23:16];
      if(mem_wmask[3]) MEM[word_addr][31:24] <= mem_wdata[31:24];
   end
endmodule


// ================= PROCESSOR =================
module Processor(
    input clk,
    input resetn,
    output reg [31:0] mem_addr,
    input  [31:0] mem_rdata,
    output reg mem_rstrb,
    output reg [31:0] mem_wdata,
    output reg [3:0] mem_wmask
);

reg [2:0] state;
reg [31:0] value;

localparam WRITE  = 0;
localparam W_IDLE = 1;
localparam READ   = 2;
localparam R_HOLD = 3;

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        mem_addr  <= 32'h00400020;
        mem_wdata <= 0;
        mem_wmask <= 0;
        mem_rstrb <= 0;
        state     <= WRITE;
        value     <= 0;
    end else begin

        mem_addr <= 32'h00400020;

        case(state)

            WRITE: begin
                mem_wdata <= value;
                mem_wmask <= 4'b1111;
                mem_rstrb <= 0;
                state <= W_IDLE;
            end

            W_IDLE: begin
                mem_wmask <= 0;
                mem_rstrb <= 0;
                state <= READ;
            end

            READ: begin
                mem_rstrb <= 1;
                mem_wmask <= 0;
                state <= R_HOLD;
            end

            R_HOLD: begin
                mem_rstrb <= 0;
                value <= value + 1;
                state <= WRITE;
            end

        endcase
    end
end

endmodule


// ================= SOC =================
module SOC (
    input RESET,
    output reg [4:0] LEDS,
    input RXD,
    output TXD
);

`ifdef BENCH
reg clk;
wire resetn;
`else
wire clk;
wire resetn;
`endif

   wire [31:0] mem_addr;
   wire [31:0] mem_rdata;
   wire mem_rstrb;
   wire [31:0] mem_wdata;
   wire [3:0]  mem_wmask;

   Processor CPU(
      .clk(clk),
      .resetn(resetn),
      .mem_addr(mem_addr),
      .mem_rdata(mem_rdata),
      .mem_rstrb(mem_rstrb),
      .mem_wdata(mem_wdata),
      .mem_wmask(mem_wmask)
   );

   wire [29:0] mem_wordaddr = mem_addr[31:2];
   wire isIO  = mem_addr[22];
   wire isRAM = !isIO;
   wire mem_wstrb = |mem_wmask;

   wire [31:0] RAM_rdata;

   Memory RAM(
      .clk(clk),
      .mem_addr(mem_addr),
      .mem_rdata(RAM_rdata),
      .mem_rstrb(isRAM & mem_rstrb),
      .mem_wdata(mem_wdata),
      .mem_wmask({4{isRAM}} & mem_wmask)
   );

   wire [31:0] gpio_rdata;
   wire [31:0] gpio_data;

   wire gpio_sel   = isIO && (mem_wordaddr == 30'h00100008);
   wire gpio_wr_en = gpio_sel && mem_wstrb;
   wire gpio_rd_en = gpio_sel && mem_rstrb;

   gpio_ip GPIO (
       .clk(clk),
       .resetn(resetn),
       .sel(gpio_sel),
       .wr_en(gpio_wr_en),
       .rd_en(gpio_rd_en),
       .wdata(mem_wdata),
       .rdata(gpio_rdata),
       .gpio_data(gpio_data)
   );

   always @(posedge clk) begin
      if (gpio_wr_en)
         LEDS <= gpio_data[4:0];
   end

   assign TXD = 1'b1;
   assign mem_rdata = isRAM ? RAM_rdata : gpio_rdata;

`ifdef BENCH
initial begin
    $dumpfile("soc.vcd");
    $dumpvars(0, SOC);
end

reg resetn_reg;
assign resetn = resetn_reg;

initial clk = 0;
always #5 clk = ~clk;

initial begin
    resetn_reg = 0;
    #20;
    resetn_reg = 1;
end
`endif

endmodule
