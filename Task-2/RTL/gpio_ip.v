module gpio_ip (
    input clk,
    input resetn,

    input        sel,
    input        wr_en,
    input        rd_en,
    input [3:0]  addr,

    input [31:0] wdata,
    output reg [31:0] rdata,

    output reg [31:0] gpio_data
);

    reg [31:0] gpio_reg;

    localparam ADDR_DATA = 4'h0;

   always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        gpio_reg <= 0;
        gpio_data <= 0;
    end
    else if (sel && wr_en) begin   
        gpio_reg <= wdata;
        gpio_data <= wdata;
    end
end
   always @(*) begin
    if (sel && rd_en)
        rdata = gpio_reg;
    else
        rdata = 32'b0;
	end

endmodule
