`timescale 1ns/1ps

module soc_tb;

reg RESET;

wire [4:0] LEDS;

// instantiate SOC (MATCH PORTS EXACTLY)
SOC uut (
    .RESET(RESET),
    .LEDS(LEDS)
);

initial begin
    $dumpfile("soc.vcd");
    $dumpvars(0, soc_tb);

    // init inputs
    RESET = 1;
      // idle UART

    #50;
    RESET = 0; // release reset

    #100000;
    $finish;
end

endmodule
