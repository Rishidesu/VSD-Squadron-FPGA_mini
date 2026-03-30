`timescale 1ns / 1ps
`default_nettype none

////////////////////////////////////////////////////////////
// MEMORY
////////////////////////////////////////////////////////////
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
      $display("MEM[0] = %h", MEM[0]);
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


////////////////////////////////////////////////////////////
// SIMPLE CPU (FIXED)
////////////////////////////////////////////////////////////
module Processor (
    input clk,
    input resetn,
    output reg [31:0] mem_addr,
    input [31:0] mem_rdata,
    output reg mem_rstrb,
    output reg [31:0] mem_wdata,
    output reg [3:0] mem_wmask
);

   reg [31:0] PC = 0;
   reg [31:0] instr;

   reg [31:0] regfile [0:31];

   wire [4:0] rs1 = instr[19:15];
   wire [4:0] rs2 = instr[24:20];
   wire [4:0] rd  = instr[11:7];

   wire [31:0] rs1_val = (rs1==0)?0:regfile[rs1];
   wire [31:0] rs2_val = (rs2==0)?0:regfile[rs2];

   wire [31:0] Iimm = {{21{instr[31]}}, instr[30:20]};
   wire [31:0] Simm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
   wire [31:0] Uimm = {instr[31:12], 12'b0};

   wire isLUI  = (instr[6:0] == 7'b0110111);
   wire isADDI = (instr[6:0] == 7'b0010011);
   wire isSW   = (instr[6:0] == 7'b0100011);

   reg [1:0] state;
   localparam FETCH=0, EXEC=1;

   always @(posedge clk) begin
      if(!resetn) begin
         PC <= 0;
         state <= FETCH;
         mem_rstrb <= 0;
         mem_wmask <= 0;
      end else begin
         case(state)

         FETCH: begin
            mem_addr <= PC;
            mem_rstrb <= 1;
            mem_wmask <= 0;
            state <= EXEC;
         end

         EXEC: begin
            instr <= mem_rdata;
            mem_rstrb <= 0;

            // LUI
            if(isLUI) begin
               regfile[rd] <= Uimm;
            end

            // ADDI
            else if(isADDI) begin
               regfile[rd] <= rs1_val + Iimm;
            end

            // STORE
            else if(isSW) begin
               mem_addr  <= rs1_val + Simm;
               mem_wdata <= rs2_val;
               mem_wmask <= 4'b1111;
            end

            PC <= PC + 4;
            state <= FETCH;
         end

         endcase
      end
   end
endmodule


////////////////////////////////////////////////////////////
// SOC
////////////////////////////////////////////////////////////
module SOC (
    input RESET,
    output reg [4:0] LEDS
);

reg clk;
reg resetn;

wire [31:0] mem_addr;
wire [31:0] mem_rdata;
wire mem_rstrb;
wire [31:0] mem_wdata;
wire [3:0] mem_wmask;

Processor CPU(
   .clk(clk),
   .resetn(resetn),
   .mem_addr(mem_addr),
   .mem_rdata(mem_rdata),
   .mem_rstrb(mem_rstrb),
   .mem_wdata(mem_wdata),
   .mem_wmask(mem_wmask)
);

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

wire [29:0] mem_wordaddr = mem_addr[31:2];

// GPIO
wire [31:0] gpio_rdata;
wire [31:0] gpio_out;
wire [31:0] gpio_in = 32'hAA;

wire gpio_sel   = isIO && (mem_wordaddr >= 30'h00100008) && (mem_wordaddr <= 30'h0010000A);
wire gpio_wr_en = gpio_sel && mem_wstrb;

wire [1:0] gpio_addr = mem_wordaddr - 30'h00100008;

gpio_ip_ctrl GPIO(
   .clk(clk),
   .resetn(resetn),
   .sel(gpio_sel),
   .wr_en(gpio_wr_en),
   .rd_en(gpio_sel),
   .addr(gpio_addr),
   .wdata(mem_wdata),
   .rdata(gpio_rdata),
   .gpio_out(gpio_out),
   .gpio_in(gpio_in)
);

always @(posedge clk) begin
   if(!resetn) LEDS <= 0;
   else LEDS <= gpio_out[4:0];
end

assign mem_rdata = isRAM ? RAM_rdata : gpio_rdata;


// CLOCK + RESET
initial clk = 0;
always #5 clk = ~clk;

initial begin
   resetn = 0;
   #100;
   resetn = 1;
end

endmodule
