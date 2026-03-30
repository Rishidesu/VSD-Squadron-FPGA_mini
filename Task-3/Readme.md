## 🎯 Objective

The goal of this project was to design and integrate a **multi-register GPIO Control IP** into a RISC-V SoC, enabling software-driven control using memory-mapped I/O.

This task focuses on:
- Designing a structured **register map**
- Supporting **multiple registers within a single IP**
- Implementing **direction control (input/output)**
- Enabling **software-controlled read/write operations**
- Validating the complete flow from **C program → CPU → GPIO → waveform**

The GPIO IP includes:
- `GPIO_DATA` → controls output values  
- `GPIO_DIR` → configures direction (1 = output, 0 = input)  
- `GPIO_READ` → returns real-time pin state  

---

## ⚙️ System Architecture

- **CPU**: Custom RV32I RISC-V core (minimal instruction support)
- **Memory**: 6KB BRAM loaded using `firmware.hex`
- **Peripheral**: GPIO Control IP
- **Output**: LEDs connected to GPIO outputs

Data flow:
C Program → ELF → HEX → BRAM → CPU → GPIO → LEDS




## 🧠 Address Map

```
IO Base Address = 0x00400000
```
```

| Offset | Register     | Address       | Description |
|--------|--------------|--------------|-------------|
| 0x00   | GPIO_DATA    | 0x00400020   | Output data |
| 0x04   | GPIO_DIR     | 0x00400024   | Direction   |
| 0x08   | GPIO_READ    | 0x00400028   | Pin state   |
```
### Address Decoding (RTL)
```verilog
wire gpio_sel = isIO &&
               (mem_wordaddr >= 30'h00100008) &&
               (mem_wordaddr <= 30'h0010000A);
```
## 🧩 GPIO Control IP Design
Registers:
- gpio_data → stores last written value
- gpio_dir → controls direction per bit
- gpio_out → driven output
- gpio_in → input pins (constant in simulation)

##✏️ Write Logic
```verilog
if (sel && wr_en) begin
    case (addr)
        2'b00: gpio_data <= wdata;
        2'b01: gpio_dir  <= wdata;
    endcase
end
gpio_out <= gpio_data & gpio_dir;
```
## 📥 Read Logic (Important Fix)

Initially implemented as synchronous, causing read failures.

### ❌ Problem
- CPU did not hold read signals long enough
gpio_rdata remained zero
### ✅ Fix (Combinational Read)
``` verilog
always @(*) begin
    if (sel && rd_en) begin
        case (addr)
            2'b00: rdata = gpio_data;
            2'b01: rdata = gpio_dir;
            2'b10: rdata = gpio_out | (gpio_in & ~gpio_dir);
            default: rdata = 32'b0;
        endcase
    end else begin
        rdata = 32'b0;
    end
end
```
## 💻 Firmware (C Code)
``` C
#define GPIO_BASE 0x00400020

#define GPIO_DATA (*(volatile unsigned int*)(GPIO_BASE))
#define GPIO_DIR  (*(volatile unsigned int*)(GPIO_BASE + 4))

int main() {

    // Configure lower 5 bits as output
    GPIO_DIR = 0x1F;

    // Write value (01010)
    GPIO_DATA = 0x0A;

    // Infinite loop
    while(1);

    return 0;
}
```
## 🧪 Simulation Results
✔ Write Behavior
- mem_wmask = 1111
- mem_addr = 0x00400020
- gpio_data = 0x0000000A
- gpio_out = 0x0000000A
- LEDS = 01010
✔ Read Behavior
- gpio_rdata correctly reflects register values
- Read logic fixed using combinational approach
