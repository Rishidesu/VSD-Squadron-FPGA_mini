# 🚀 RISC-V SoC GPIO Integration & Simulation

## Overview

This project extends a basic **RV32I RISC-V SoC** by integrating a **memory-mapped GPIO peripheral**, validating it through simulation, and verifying correct read/write behavior.

It demonstrates:

- Memory-mapped peripheral design  
- SoC-level integration  
- Bus protocol (read/write timing)  
- Simulation-based verification  

---

# 🧱 1. GPIO IP Design

## Module: `gpio_ip.v`

A simple 32-bit register:

- Write → updates GPIO output  
- Read → returns stored value  

```verilog
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
```

###  Key Design Points

* Fully synchronous design
* Stable registered readback
* Persistent data storage
* Separate read/write control signals

---

##  2. SoC Integration

### Address Mapping

* GPIO Address: `0x00400020`
* Word Address: `0x00100008`

###  Address Decode
GPIO is mapped to IO space where mem_addr[22] = 1.
It is selected using bit-based decoding with mem_wordaddr[3].
The base address can be considered 0x00400020, though the decoding allows multiple mirrored addresses.
```
localparam IO_GPIO_bit = 3;

wire gpio_sel   = isIO && mem_wordaddr[IO_GPIO_bit];
wire gpio_wr_en = gpio_sel && |mem_wmask;
wire gpio_rd_en = gpio_sel && mem_rstrb;
```
###  IP Instantiation

```verilog
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
```

###  Read Data Multiplexing

```verilog
wire [31:0] IO_rdata =
    mem_wordaddr[IO_UART_CNTL_bit] ? {22'b0, !uart_ready, 9'b0} :
    gpio_sel ? gpio_rdata :32'b0;
assign mem_rdata = isRAM ? RAM_rdata : IO_rdata;
```
#### Read Mux
```
assign mem_rdata = isRAM ? RAM_rdata : gpio_rdata;
```
---

## 3. Simulation Setup

### Clock & Reset Generation

```verilog
`ifdef BENCH
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
```

#### Purpose

* Deterministic clock generation
* Clean reset initialization
* Reliable waveform debugging

---

#### ⚙️ 4. Processor (FSM Test CPU)

This project uses a dummy FSM-based CPU for verification.

Behavior
Alternates WRITE → READ → HOLD
Writes incrementing values to GPIO
Reads back (optional)
```
localparam WRITE  = 0;
localparam W_IDLE = 1;
localparam READ   = 2;
localparam R_HOLD = 3;
```
##  5. Firmware Interface

###  Address Definition

```c
#define IO_BASE     0x00400000
#define GPIO_ADDR   (IO_BASE + 0x20)

volatile unsigned int *gpio = (unsigned int *)GPIO_ADDR;
```

###  Behavior

* Write value → GPIO register
* Read value → verify correctness
* Print via UART
* Exit using `ecall`

---
## ▶️ 6. How to Run/Simulation
Step 1 — Clean old files
```
rm -f riscv_tb.vvp soc.vcd
```
Step 2 — Compile
```
iverilog -DBENCH -o riscv_tb.vvp riscv.v gpio_ip.v riscv_tb.v
```
Step 3 — Run simulation
```
vvp riscv_tb.vvp
```
Step 4 — Open waveform
```
gtkwave soc.vcd
```

## 6.Signals Observed

### CPU / Bus Signals
- mem_addr
- mem_wdata
- mem_wmask
- mem_rstrb

### Address Decode
- isIO
- isRAM
- mem_wordaddr
- gpio_sel

### GPIO Control
- gpio_wr_en
- gpio_rd_en

### GPIO Data
- gpio_data
- gpio_rdata

### Output
- LEDS

### Read Path
- mem_rdata



## Signals Observed

### CPU / Bus Signals
- mem_addr
- mem_wdata
- mem_wmask
- mem_rstrb

### Address Decode
- isIO
- isRAM
- mem_wordaddr
- gpio_sel

### GPIO Control
- gpio_wr_en
- gpio_rd_en

### GPIO Data
- gpio_data
- gpio_rdata

### Output
- LEDS

### Read Path
- mem_rdata

### RAM (optional)
- RAM_rdata
---



##  7. Conclusion

This project successfully demonstrates:

* Memory-mapped GPIO design
* SoC-level integration
* Firmware interaction
* Simulation-based validation

✔ Verified write and readback behavior
✔ Confirmed correct address decoding
✔ Achieved end-to-end functional validation

---



