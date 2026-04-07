module spi(
    input clk,
    input rst,

    input sel,
    input w_en,
    input r_en,
    input [31:0] wdata,
    output reg [31:0] rdata,
    input [1:0] offset,

    output reg sclk,
    output reg mosi,
    input miso,
    output reg cs_n,
    output [7:0] debug_tx,
output [7:0] debug_rx
);
assign debug_tx = tx_reg;
assign debug_rx = rxdata;
// ================= REGISTER MAP =================
localparam CTRL   = 2'b00;
localparam TXDATA = 2'b01;
localparam RXDATA = 2'b10;
localparam STATUS = 2'b11;

// ================= REGISTERS =================
reg en;
reg start;
reg [7:0] clkdiv;

reg [7:0] tx_reg;
reg [7:0] rx_reg;
reg [7:0] rxdata;

reg busy;
reg done;

// ================= CLOCK =================
reg [7:0] clk_cnt;
reg sclk_int;
reg sclk_prev;

// ================= SHIFT =================
reg [2:0] bit_cnt;

// ================= FSM =================
localparam IDLE=0, TRANSFER=1, FINISH=2;
reg [1:0] state;

// =================================================
// WRITE LOGIC
// =================================================
always @(posedge clk) begin
    if(rst) begin
        en <= 0;
        start <= 0;
        clkdiv <= 8'd4;
        tx_reg <= 0;
        done <= 0;
    end else begin
        start <= 0; // auto-clear

        if(sel && w_en) begin
            case(offset)

                CTRL: begin
                    en <= wdata[0];
                    clkdiv <= wdata[15:8];

                    if(wdata[1] && !busy)
                        start <= 1;
                    if(wdata[1])
        		done <= 0;
                end

                TXDATA: tx_reg <= wdata[7:0];

                

            endcase
        end
    end
end

// =================================================
// CLOCK GENERATION (toggle every CLKDIV+1)
// =================================================
always @(posedge clk) begin
    if(rst) begin
        clk_cnt <= 0;
        sclk_int <= 0;
    end else if(state == TRANSFER) begin
        if(clk_cnt == clkdiv) begin
            clk_cnt <= 0;
            sclk_int <= ~sclk_int;
        end else begin
            clk_cnt <= clk_cnt + 1;
        end
    end else begin
        clk_cnt <= 0;
        sclk_int <= 0;
    end
end

// =================================================
// EDGE DETECTION (CRITICAL FIX)
// =================================================
always @(posedge clk) begin
    if(rst)
        sclk_prev <= 0;
    else
        sclk_prev <= sclk_int;
end

wire rising_edge  = (sclk_prev == 0 && sclk_int == 1);
wire falling_edge = (sclk_prev == 1 && sclk_int == 0);

// =================================================
// FSM (MODE 0 CORRECT)
// =================================================
always @(posedge clk) begin
    if(rst) begin
        state <= IDLE;
        cs_n <= 1;
        sclk <= 0;
        mosi <= 0;
        busy <= 0;
        done <= 0;
        bit_cnt <= 0;
        rx_reg <= 0;
        rxdata <= 0;
    end else begin
        case(state)

        // ================= IDLE =================
        IDLE: begin
            cs_n <= 1;
            sclk <= 0;
            busy <= 0;

            if(en && start) begin
                cs_n <= 0;
                busy <= 1;
                done <= 0;

                bit_cnt <= 3'd7;
                rx_reg <= 0;

                // preload MSB
                mosi <= tx_reg[7];

                state <= TRANSFER;
            end
        end

        // ================= TRANSFER =================
        TRANSFER: begin
            sclk <= sclk_int;

            // SAMPLE on rising edge
            if(rising_edge) begin
                rx_reg <= {rx_reg[6:0], miso};
            end

            // SHIFT on falling edge
            if(falling_edge) begin
                if(bit_cnt != 0) begin
                    bit_cnt <= bit_cnt - 1;
                    mosi <= tx_reg[bit_cnt - 1];
                end else begin
                    state <= FINISH;
                end
            end
        end

        // ================= FINISH =================
        FINISH: begin
            cs_n <= 1;
            busy <= 0;
            done <= 1;
            rxdata <= rx_reg;
            state <= IDLE;
        end

        endcase
    end
end

// =================================================
// READ LOGIC
// =================================================
always @(posedge clk) begin
    if(sel && r_en) begin
        case(offset)
            CTRL:   rdata <= {16'd0, clkdiv, 7'd0, en};
            TXDATA: rdata <= {24'd0, tx_reg};
            RXDATA: rdata <= {24'd0, rxdata};
            STATUS: rdata <= {29'd0, 1'b1, done, busy}; // TX_READY=1
            default: rdata <= 0;
        endcase
    end else begin
        rdata <= 0;
    end
end

endmodule
