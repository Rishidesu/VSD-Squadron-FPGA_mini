
module gpio_ip (
    input clk,
    input resetn,

    input wr_en,
    input rd_en,

    input [31:0] wdata,
    output reg [31:0] rdata,

    output reg [31:0] gpio_data
);

    reg [31:0] gpio_reg;

    // Write logic (synchronous)
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            gpio_reg  <= 32'b0;
            gpio_data <= 32'b0;
        end else if (wr_en) begin
            gpio_reg  <= wdata;
            gpio_data <= wdata;
        end
    end

    // Read logic (combinational)
    always @(*) begin
        if (rd_en)
            rdata = gpio_reg;
        else
            rdata = 32'b0;
    end

endmodule
