`timescale 1ns/1ps

module soc_tb;

    reg clk;
    reg reset;

    wire sclk, mosi, cs_n;
    wire miso;
    wire TXD;

    // 🔥 SPI LOOPBACK
    assign miso = mosi;

    SOC uut (
        .RESET(reset),
        .TXD(TXD),

        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
    $dumpfile("soc_tb.vcd");
    $dumpvars(0, soc_tb);
    $dumpvars(0, soc_tb.uut.CPU);

    reset = 1;
    #100;
    reset = 0;

    #200000;

    
   
    $finish;
end
endmodule
