#  RISC-V SoC GPIO Integration & Simulation

## Overview

This project extends a basic **RV32I RISC-V SoC** by integrating a **memory-mapped GPIO peripheral**, validating it through firmware, and verifying functionality using simulation tools.

The goal is to demonstrate:

* Memory-mapped peripheral design
* SoC-level integration
* Firmware-driven validation
* End-to-end verification

---

##  1. GPIO IP Design

###  Module: `gpio_ip.v`

A simple 32-bit memory-mapped register:

* Write → updates GPIO output
* Read → returns last written value

```verilog
`timescale 1ns/1ps

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

// Write logic
always @(posedge clk) begin
    if (!resetn) begin
        gpio_reg  <= 32'b0;
        gpio_data <= 32'b0;
    end else if (wr_en) begin
        gpio_reg  <= wdata;
        gpio_data <= wdata;
    end
end

// Read logic
always @(posedge clk) begin
    if (!resetn) begin
        rdata <= 32'b0;
    end else if (rd_en) begin
        rdata <= gpio_reg;
    end
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
// -----------------------------------
// GPIO WIRES
// -----------------------------------
wire [31:0] gpio_rdata;
wire [31:0] gpio_data;

gpio_ip GPIO (
    .clk(clk),
    .resetn(resetn),

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

##  4. Firmware Interface

###  Address Definition

```c
#define IO_BASE   0x00400000
#define GPIO_ADDR (IO_BASE + 0x20)

volatile uint32_t *gpio = (uint32_t *)GPIO_ADDR;
```

###  Behavior

* Write value → GPIO register
* Read value → verify correctness
* Print via UART
* Exit using `ecall`

---

##  5. Simulation Results

###  Observed Signals

* `clk`, `resetn`
* `mem_addr`, `mem_wmask`
* `gpio_data`, `rdata`
* `mem_rdata`, `mem_wdata`
* `gpio_sel`, `wr_en`, `rd_en`

###  Execution Flow

1. CPU writes to `0x00400020`
2. GPIO captures value into register
3. CPU performs read operation
4. Stored value returned via `mem_rdata`
5. UART prints result
6. Simulation exits using `ecall`

All behaviors matched expected functionality

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



