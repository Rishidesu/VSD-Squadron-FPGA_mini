`timescale 1ns / 1ps

module gpio_ip_tb;

    reg clk;
    reg resetn;
    reg wr_en;
    reg rd_en;
    reg [31:0] wdata;

    wire [31:0] rdata;
    wire [31:0] gpio_data;

    // DUT instantiation
    gpio_ip dut (
        .clk(clk),
        .resetn(resetn),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wdata(wdata),
        .rdata(rdata),
        .gpio_data(gpio_data)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("gpio.vcd");
        $dumpvars(0, gpio_ip_tb);

        clk    = 0;
        resetn = 0;
        wr_en  = 0;
        rd_en  = 0;
        wdata  = 32'b0;

        // Reset
        #20;
        resetn = 1;

        // Write
        @(negedge clk);
        wr_en = 1;
        wdata = 32'h00000005;

        @(negedge clk);
        wr_en = 0;

        // Check write
        #1;
        if (gpio_data !== 32'h00000005)
            $display("WRITE FAILED: %h", gpio_data);

        // Read
        @(negedge clk);
        rd_en = 1;

        @(negedge clk);
        rd_en = 0;

        // Check read
        #1;
        if (rdata !== 32'h00000005)
            $display("READ FAILED: %h", rdata);

        #20;
        $finish;
    end

endmodule
