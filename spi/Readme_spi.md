# 🔷 RISC-V SoC SPI Master IP – Design, Integration, and Testing

## 📌 Overview

This project implements a **minimal SPI Master IP** integrated into a **RV32I RISC-V SoC**.

The SPI module supports:

* **Single-byte (8-bit) transfers**
* **SPI Mode 0 (CPOL = 0, CPHA = 0)**
* **Memory-mapped CPU interface**

### 🎯 Objectives

* Design a **clean and synthesizable SPI master**
* Enable **CPU-controlled SPI communication**
* Ensure **correct timing and protocol compliance**

---

## 🧠 SPI Master IP – Design Explanation

### 📊 Register Map

| Offset | Name   | Access | Description            |
| -----: | ------ | ------ | ---------------------- |
|   0x00 | CTRL   | R/W    | Control register       |
|   0x04 | TXDATA | W      | Transmit data register |
|   0x08 | RXDATA | R      | Received data register |
|   0x0C | STATUS | R/W1C  | Status flags           |

---

### ⚙️ CTRL Register (0x00)

| Bit(s) | Name   | Description                             |
| -----: | ------ | --------------------------------------- |
|      0 | EN     | Enable SPI module                       |
|      1 | START  | Start transfer (auto-clears internally) |
|   15:8 | CLKDIV | Clock divider                           |

* `START` must **not be level-sensitive**
* Transfer begins only if `BUSY = 0`

---

### 📤 TXDATA Register (0x04)

| Bit(s) | Description      |
| -----: | ---------------- |
|    7:0 | Data to transmit |

* Writing loads the **transmit shift register**
* Writing during `BUSY = 1` must be ignored

---

### 📥 RXDATA Register (0x08)

| Bit(s) | Description   |
| -----: | ------------- |
|    7:0 | Received byte |

* Updated only **after full 8-bit transfer completes**

---

### 📡 STATUS Register (0x0C)

| Bit | Name     | Description                |
| --: | -------- | -------------------------- |
|   0 | BUSY     | Transfer in progress       |
|   1 | DONE     | Transfer completed         |
|   2 | TX_READY | Ready for new transmission |

* `DONE` is **Write-1-to-Clear (W1C)**
* `TX_READY = !BUSY`

---

## 🔁 SPI Transfer Behavior (Mode 0)

### Mode Configuration

* **CPOL = 0 → Clock idle LOW**
* **CPHA = 0 → Sample on rising edge**

---

### ⏱️ Transfer Sequence

| Step | Action                      |
| ---- | --------------------------- |
| 1    | CPU writes TXDATA           |
| 2    | CPU sets START              |
| 3    | CS_N goes LOW               |
| 4    | 8 clock cycles generated    |
| 5    | MOSI shifts on falling edge |
| 6    | MISO sampled on rising edge |
| 7    | CS_N goes HIGH              |
| 8    | DONE = 1, BUSY = 0          |

---

## 🧩 Internal Architecture

### Core Components

* Clock Divider
* Shift Registers (TX & RX)
* Bit Counter (0–7)
* Control FSM

---

### 🔄 FSM States

| State    | Description                     |
| -------- | ------------------------------- |
| IDLE     | Wait for START                  |
| LOAD     | Load TXDATA into shift register |
| TRANSFER | Shift 8 bits                    |
| DONE     | Set DONE flag                   |

---

### 🔁 Data Flow

* TXDATA → Shift Register → MOSI
* MISO → Shift Register → RXDATA

---

## 🔌 SoC Integration

### 📍 Address Mapping

```
SPI_BASE = 0x0040_0080
```

---

### 🔍 Address Decode

* `mem_addr[22]` → IO region select
* `mem_wordaddr[1:0]` → register selection

---

### 🔗 Signal Connections

| Signal | Direction | Description            |
| ------ | --------- | ---------------------- |
| SCLK   | Output    | SPI clock              |
| MOSI   | Output    | Master Out Slave In    |
| MISO   | Input     | Master In Slave Out    |
| CS_N   | Output    | Active low chip select |

---
## 💻 Firmware Usage

This example demonstrates a **single SPI transfer** along with a **double START condition test**.

---

### 🔧 Register Definitions

```c
#define SPI_BASE   0x00401000

#define SPI_CTRL   (*(volatile unsigned int*)(SPI_BASE + 0))
#define SPI_TXDATA (*(volatile unsigned int*)(SPI_BASE + 4))
#define SPI_RXDATA (*(volatile unsigned int*)(SPI_BASE + 8))
#define SPI_STATUS (*(volatile unsigned int*)(SPI_BASE + 12))
```

---

### 🧪 Example: Single Transfer with Double START

```c
void _start() {

    // Initialize stack pointer
    asm volatile("li sp, 0x00001800");

    // Load transmit data
    SPI_TXDATA = 0x01;

    // Start first transfer
    SPI_CTRL = (1<<0) | (1<<1) | (4<<8);

    // Attempt second START immediately (while BUSY = 1)
    SPI_CTRL = (1<<0) | (1<<1) | (4<<8);

    // Wait for DONE flag
    while((SPI_STATUS & (1<<1)) == 0);

    // Read received data
    volatile unsigned int data = SPI_RXDATA;

    // Halt execution
    while(1);
}
```

---

### 🔍 Expected Behavior

| Step         | Description                       |
| ------------ | --------------------------------- |
| TXDATA write | Loads transmit byte (0x01)        |
| First START  | Begins SPI transfer               |
| Second START | Ignored while BUSY = 1            |
| Transfer     | 8-bit data shifted over MOSI/MISO |
| DONE         | Set after transfer completes      |
| RXDATA       | Contains received byte            |

---

### ⚠️ Notes

* Only one transfer occurs despite two START writes
* Transfer size is fixed to **8 bits**
* `DONE` indicates completion of transfer
* `CLKDIV` controls SPI clock speed

---


## ⏱️ Clock Behavior

* SCLK toggles every `(CLKDIV + 1)` system clock cycles
* Full SCLK period = `2 × (CLKDIV + 1)`

---

## 🧠 Debug Tip

If SPI is not working:

* Check `SPI_BUSY` → stuck = FSM issue
* Check `SPI_DONE` → never set = transfer not completing
* Check `CS_N` → must stay LOW during transfer
* Verify MOSI/MISO timing using waveform

---



---

## 🧪 Expected Behavior

* Only **one transfer at a time**
* START ignored when BUSY = 1
* Transfer always **8 bits**
* CS_N active only during transfer
* DONE asserted after completion
* RXDATA is updated ONLY after full 8-bit transfer completes
* Intermediate bits are not visible to CPU
  

---

## ⚠️ Common Design Pitfalls

### ❌ Incorrect Clock Edge Usage

* Mixing edges causes invalid data sampling

### ❌ START Not Auto-Clearing

* Leads to repeated unintended transfers

### ❌ No BUSY Protection

* Causes corrupted transfers

### ❌ Early RXDATA Update

* Must update only after full transfer

### ❌ CS_N Misuse

* Must stay LOW for entire 8-bit transfer

---
## 🚧 Challenges Faced & Fixes

| Challenge                      | Description                                                                          | Fix                                                                                                                |
| ------------------------------ | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| DONE flag (W1C) implementation | DONE was initially cleared when START was written, causing incorrect status behavior | Implemented proper **Write-1-to-Clear (W1C)** logic in STATUS register                                             |
| TX_READY logic                 | TX_READY was incorrectly hardcoded and not reflecting BUSY state                     | Corrected to `TX_READY = !BUSY` for accurate readiness indication                                                  |
| BUSY handling                  | START and TXDATA were not fully protected during active transfer                     | Added conditions to ignore START and TXDATA writes when `BUSY = 1`                                                 |
| SPI–CPU Integration            | Difficulty in mapping SPI into RISC-V memory space and handling read/write strobes   | Implemented proper **address decoding** and connected SPI through `mem_addr`, `mem_wmask`, and `mem_rstrb` signals |
| Address Mapping Confusion      | Initial mismatch between firmware base address and RTL decode logic                  | Aligned firmware (`0x00401000`) with RTL decode condition (`mem_addr[31:12]`)                                      |
| PCF File Issues                | FPGA pin constraints failed due to incorrect package/variant selection               | Corrected FPGA **device variant and package (e.g., hx8k, cb132)** to match board                                   |
| Pin Mapping Errors             | PCF file used incompatible or symbolic pin names                                     | Updated PCF to use **valid numerical pin assignments** supported by the target FPGA                                |
| Toolchain Errors               | Synthesis / PnR failures due to mismatched constraints                               | Ensured consistency between **PCF, nextpnr arguments, and actual FPGA hardware**                                   |

---

## ⚙️ Toolchain Setup (Ubuntu)

The following tools are required to build and program the SPI SoC on FPGA.

---

### 🔧 1. Install Dependencies

```bash
sudo apt update

sudo apt install -y \
  build-essential \
  git \
  yosys \
  nextpnr-ice40 \
  icestorm 
```

---

### ⚡ 2. RISC-V Toolchain

Install RISC-V GCC:

```bash
sudo apt install -y gcc-riscv64-unknown-elf
```

Verify installation:

```bash
riscv64-unknown-elf-gcc --version
```

---

### ❄️ 3. Icestorm Tools (icepack, iceprog)

These are typically included in the `icestorm` package.

Verify:

```bash
which icepack
which iceprog
```

If not found, install manually:

```bash
sudo apt install -y fpga-icestorm
```

---

### 🔍 4. Verify All Tools

```bash
yosys -V
nextpnr-ice40 --version
iceprog -h
iverilog -V
```

---

### ⚠️ USB Permissions (Important for iceprog)

If `iceprog` fails to detect FPGA:

```bash
sudo usermod -aG plugdev $USER
```

Then logout and login again.

---

### 🧠 Notes

* FPGA target used: **Lattice iCE40 UP5K (SG48 package)**
* Ensure PCF file matches your board pinout
* Use `make` to build and `make flash` to program

---





## 🛠️ Build Flow (Using Makefile)

The project uses a **Makefile-based flow** to automate firmware generation, synthesis, place & route, and programming.

---

### 🔧 1. Complete Build

```bash
make
```

This performs:

* Firmware compilation (`firmware.c → firmware.hex`)
* RTL synthesis using Yosys
* Place & Route using nextpnr
* Bitstream generation using icepack

---

### ⚡ 2. FPGA Programming

```bash
make flash
```

* Programs the generated bitstream (`SOC.bin`) onto FPGA using `iceprog`

---

### 🧪 3. Simulation

```bash
make sim
```

* Compiles testbench using `iverilog`
* Runs simulation using `vvp`
* Uses `firmware.hex` for program execution

---

### 🧹 4. Clean Build Files

```bash
make clean
```

* Removes all generated files:

  * `.elf`, `.bin`, `.hex`
  * `.json`, `.asc`
  * simulation outputs (`.vvp`, `.vcd`)

---

## 🔍 Internal Flow Breakdown

### Firmware Generation

```bash
riscv64-unknown-elf-gcc -O0 -march=rv32i -mabi=ilp32 \
  -nostdlib -ffreestanding \
  -T link.ld -Wl,-e,_start \
  firmware.c -o firmware.elf

riscv64-unknown-elf-objcopy -O binary firmware.elf firmware.bin

hexdump -v -e '1/4 "%08x\n"' firmware.bin > firmware.hex
```

---

### RTL Synthesis

```bash
yosys -p "synth_ice40 -top SOC -json SOC.json" riscv.v spi.v
```

---

### Place & Route

```bash
nextpnr-ice40 \
  --json SOC.json \
  --pcf VSDSquadronFM.pcf \
  --asc SOC.asc \
  --up5k \
  --package sg48 \
  --pcf-allow-unconstrained
```

---

### Bitstream Generation

```bash
icepack SOC.asc SOC.bin
```

---

## ⚠️ Important Notes

* FPGA target: **UP5K (SG48 package)**
* Ensure PCF file matches selected package
* Firmware is automatically embedded via `firmware.hex`

---

---

## 🚧 Limitations

* Single-byte (8-bit) transfers only
* No FIFO buffering (CPU must manage every transfer)
* No interrupt support (polling required)
* No multi-slave support (single CS_N only)
* No back-to-back/pipelined transfers
* Limited error handling (no timeout or fault detection)

---

## ✅ Conclusion

This SPI Master IP provides:

* A **minimal and functional SPI implementation**
* Clean **memory-mapped interface with proper control/status handling**
* Correct **Mode 0 timing (CPOL=0, CPHA=0)**
* Improved **status handling with BUSY protection and DONE W1C behavior**

It is suitable for:

* Basic SPI communication
* Learning **SoC peripheral design and integration**
* Understanding **hardware–software interaction via memory-mapped IO**
* Future extensions (multi-byte, FIFO, interrupts)

---


---


