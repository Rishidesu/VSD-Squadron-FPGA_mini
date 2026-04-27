`timescale 1ns/1ps

module spi_tb;

    reg clk;
    reg resetn;

    reg [31:0] addr;
    reg [31:0] wdata;
    reg we;
    reg re;
    wire [31:0] rdata;

    wire sclk, mosi, cs_n;
    wire miso;

    spi uut (
        .clk(clk),
        .resetn(resetn),
        .addr(addr),
        .wdata(wdata),
        .we(we),
        .re(re),
        .rdata(rdata),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );

    always #5 clk = ~clk;

    assign miso = mosi;

    // -------------------------
    // WRITE TASK (safe)
    // -------------------------
    task write_reg(input [31:0] a, input [31:0] d);
    begin
        @(posedge clk);
        addr  <= a;
        wdata <= d;
        we    <= 1;
        re    <= 0;

        @(posedge clk);
        we <= 0;
    end
    endtask

    // -------------------------
    // ADDR MAP
    // -------------------------
    localparam BASE   = 32'h00401000;
    localparam CTRL   = BASE + 0;
    localparam TXDATA = BASE + 4;
    localparam RXDATA = BASE + 8;
    localparam STATUS = BASE + 12;

    // -------------------------
    // TEST
    // -------------------------
    initial begin
        $dumpfile("spi_tb.vcd");
        $dumpvars(0, spi_tb);

        clk = 0;
        resetn = 0;
        addr = 0;
        wdata = 0;
        we = 0;
        re = 0;

        #20;
        resetn = 1;

        #20;

        // Enable SPI
        write_reg(CTRL, (8 << 8) | 1);

        // ===================================================
        // TEST SEQUENCE (FIXED TIMING)
        // ===================================================

        // -------- SEND 55 --------
        write_reg(TXDATA, 32'h55);
        write_reg(CTRL, (8 << 8) | (1<<1) | 1);

        wait (uut.done == 1);

        // 🔥 CRITICAL: READ WITHOUT WAITING CLOCK
        addr = RXDATA;
        re   = 1;
        #1;
        $display("RX1 = %h (expected 55)", rdata[7:0]);
        re = 0;

        write_reg(STATUS, (1<<1)); // clear done
        #100;


        // -------- SEND A5 --------
        write_reg(TXDATA, 32'hA5);
        write_reg(CTRL, (8 << 8) | (1<<1) | 1);

        wait (uut.done == 1);

        addr = RXDATA;
        re   = 1;
        #1;
        $display("RX2 = %h (expected A5)", rdata[7:0]);
        re = 0;

        write_reg(STATUS, (1<<1));
        #100;


        // -------- SEND 3C --------
        write_reg(TXDATA, 32'h3C);
        write_reg(CTRL, (8 << 8) | (1<<1) | 1);

        wait (uut.done == 1);

        addr = RXDATA;
        re   = 1;
        #1;
        $display("RX3 = %h (expected 3C)", rdata[7:0]);
        re = 0;

        write_reg(STATUS, (1<<1));
        #100;


        $display("=== TEST COMPLETE ===");
        $finish;
    end

endmodule
