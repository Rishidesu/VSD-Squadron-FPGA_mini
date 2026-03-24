`timescale 1ns/1ps
`define BENCH

module riscv_tb;

    reg RESET;
    wire [4:0] LEDS;
    reg RXD;
    wire TXD;

    SOC uut (
        .RESET(RESET),
        .LEDS(LEDS),
        .RXD(RXD),
        .TXD(TXD)
    );

    initial begin
        $dumpfile("soc.vcd");
        $dumpvars(0, riscv_tb);

        RESET = 1;
        RXD   = 1;

        #50;
        RESET = 0;

        // run long enough for CPU activity
        #5000;

        $finish;
    end

endmodule
