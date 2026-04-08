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

## 🛠️ Build Flow

### 1. Firmware Compilation

```bash
riscv64-unknown-elf-gcc -Os \
  -march=rv32i -mabi=ilp32 \
  -ffreestanding -nostdlib \
  start.S main.c \
  -Wl,-T,link.ld \
  -o firmware.elf

riscv64-unknown-elf-objcopy -O ihex firmware.elf firmware.hex
```

---

### 2. RTL Synthesis

```bash
yosys -p "
read_verilog riscv.v spi.v
synth_ice40 -top SOC -json soc.json
"
```

---

### 3. Place & Route

```bash
nextpnr-ice40 \
  --hx8k \
  --package cb132 \
  --pcf VSDSquadronFM.pcf \
  --pcf-allow-unconstrained \
  --json soc.json \
  --asc soc.asc
```

---

### 4. Bitstream Generation

```bash
icepack soc.asc soc.bin
```

---

### 5. FPGA Programming

```bash
iceprog soc.bin
```

---

## 🚧 Limitations

* Single-byte transfers only
* No FIFO
* No interrupt support
* No multi-slave support

---

## ✅ Conclusion

This SPI Master IP provides:

* A **minimal and functional SPI implementation**
* Clean **memory-mapped interface**
* Correct **Mode 0 timing behavior**

It is suitable for:

* Basic SPI communication
* Learning SoC peripheral design
* Further extension (multi-byte, FIFO, interrupts)

---

## ⚡ Final Reality Check

If your SPI:

* Doesn’t align MOSI/MISO with correct edges
* Doesn’t hold CS_N properly
* Doesn’t enforce BUSY

Then this README is just decoration.

Fix your RTL before you feel proud of this.
