# SPI Master IP for VSDSquadron FPGA

---

## 1. Overview

This IP implements a **memory-mapped SPI Master controller** integrated into a RISC-V SoC for the VSDSquadron FPGA platform.

The SPI controller is controlled entirely through register reads and writes over the processor memory bus, enabling software-driven communication with external SPI peripherals.

This IP is designed for:

* Simplicity
* Deterministic operation
* Easy integration without modifying RTL

---

## 2. Key Characteristics

* **SPI Mode Supported**: Mode 0 (CPOL = 0, CPHA = 0)
* **Data Width**: 8-bit transfers (MSB-first)
* **Operation Type**: Polling-based
* **Clocking**: Programmable clock divider
* **Transfer Type**: Single-byte transactions
* **Chip Select**: Automatically controlled per transfer

---

## 3. System Context

The SPI IP is integrated as a **memory-mapped peripheral** in the RISC-V SoC.

### Address Mapping

* **Base Address**: `0x00401000`
* **Register Offset**: Derived from `mem_addr[3:2]`

### Selection Logic

* SPI is selected when upper address bits match the SPI region
* CPU interacts via standard load/store instructions

---

## 4. Block-Level Architecture

```text
RISC-V CPU
   |
Memory Bus
   |
Address Decode (SPI Select)
   |
-------------------------
|   Register Interface   |
-------------------------
           |
     Control Logic (FSM)
           |
     Clock Generator
           |
     Shift Register
      |        |
    MOSI     MISO
           |
          SCLK
           |
          CS_N
```

---

## 5. Functional Description

### 5.1 Operation Flow

1. Configure SPI (enable + clock divider)
2. Write transmit data
3. Trigger transfer
4. SPI hardware:

   * Drives CS low
   * Generates clock
   * Shifts data out (MOSI)
   * Samples data in (MISO)
5. Transfer completes
6. DONE flag is set
7. Received data is available

---

### 5.2 Timing Behavior

* Clock idle state: LOW
* Data sampled on **rising edge**
* Data shifted on **falling edge**

→ This corresponds to **SPI Mode 0**

---

### 5.3 Clock Generation

SPI clock is derived from system clock:

SPI_CLK = SYS_CLK / (2 × CLKDIV)

---

## 6. Register Map

| Offset | Register | Access | Description               |
| ------ | -------- | ------ | ------------------------- |
| 0x00   | CTRL     | R/W    | Control and configuration |
| 0x01   | TXDATA   | R/W    | Transmit data             |
| 0x02   | RXDATA   | R      | Received data             |
| 0x03   | STATUS   | R/W    | Status flags              |

---

### 6.1 CTRL Register (0x00)

| Bit  | Name   | Description                  |
| ---- | ------ | ---------------------------- |
| 0    | ENABLE | Enable SPI                   |
| 1    | START  | Start transfer (auto-clears) |
| 15:8 | CLKDIV | Clock divider                |

**Reset Value:** 0x0000

**Behavior:**

* START is ignored if BUSY = 1
* START auto-clears after one cycle

---

### 6.2 TXDATA Register (0x01)

| Bit Range | Description   |
| --------- | ------------- |
| [7:0]     | Transmit data |

**Reset Value:** 0x00

**Behavior:**

* Write ignored if BUSY = 1
* Data transmitted MSB-first

---

### 6.3 RXDATA Register (0x02)

| Bit Range | Description   |
| --------- | ------------- |
| [7:0]     | Received data |

**Reset Value:** Undefined

**Behavior:**

* Updated after transfer completion

---

### 6.4 STATUS Register (0x03)

| Bit | Name | Description                |
| --- | ---- | -------------------------- |
| 0   | BUSY | Transfer in progress       |
| 1   | DONE | Transfer completed         |
| 2   | IDLE | SPI idle (inverse of BUSY) |

**Reset Value:** 0x0

**Behavior:**

* DONE is **Write-One-To-Clear (W1C)**
* BUSY is controlled by hardware

---

## 7. Software Programming Model

### 7.1 Initialization

* Set CLKDIV
* Enable SPI

---

### 7.2 Transfer Sequence

1. Write data to TXDATA
2. Set START bit
3. Poll STATUS until DONE = 1
4. Read RXDATA
5. Clear DONE

---

### 7.3 Important Behavior Rules

* START auto-clears
* DONE must be cleared manually
* TXDATA writes ignored during BUSY
* Only one transfer allowed at a time

---

## 8. Integration Guide (VSDSquadron SoC)

### 8.1 Required Components

* SPI RTL module
* SoC integration wrapper

---

### 8.2 Bus Interface Signals

* `sel` → SPI select
* `w_en` → write enable
* `r_en` → read enable
* `offset` → register select (`mem_addr[3:2]`)
* `wdata` → write data
* `rdata` → read data

---

### 8.3 External Signals

| Signal | Direction | Description            |
| ------ | --------- | ---------------------- |
| sclk   | Output    | SPI clock              |
| mosi   | Output    | Data to slave          |
| miso   | Input     | Data from slave        |
| cs_n   | Output    | Active-low chip select |

---

## 9. Board-Level Usage (VSDSquadron FPGA)

### Connections

* Connect MOSI, MISO, SCLK, CS to SPI device
* Ensure voltage compatibility

### Debug

* Received SPI data can be observed via internal debug signals
* LED may reflect received data (SoC-level mapping)

---

## 10. Validation & Expected Behavior

### Loopback Test

* Connect MOSI → MISO
* Write any byte to TXDATA
* Expected: RXDATA = transmitted value

Example:
TXDATA = 0xA5 → RXDATA = 0xA5

Example(used to hardware testing):
TXDATA= 0x01 → RXDATA = 0x01

---

### Expected Signals

* CS goes LOW during transfer
* SCLK toggles according to CLKDIV
* MOSI shifts MSB-first
* DONE asserted after transfer

---

## 11. Known Limitations

* Only SPI Mode 0 supported
* No CPOL/CPHA configurability
* Single-byte transfers only
* No FIFO or buffering
* No interrupt support
* No DMA support
* Single slave only
* Software-driven operation

---

## 12. Folder Structure

```text
/spi_master/
  rtl/
  software/
  docs/
    IP_User_Guide.md
    Register_Map.md
    Integration_Guide.md
    Example_Usage.md
  Readme.md
```

---

## 13. Quick Start (30 Seconds)

1. Add SPI RTL to SoC
2. Map base address to `0x00401000`
3. Connect SPI pins
4. Enable SPI
5. Write TXDATA and trigger START
6. Poll DONE and read RXDATA

---

## 14. Documentation Index

* Register details → docs/Register_Map.md
* Integration → docs/Integration_Guide.md
* Usage → docs/Example_Usage.md

---
## 15. Demonstration

- Waveform screenshots → docs/media/
- Hardware demo video → <https://drive.google.com/file/d/1d5xRnOXUBnHz3TlQ7JbTWyJ9_1YxGVs8/view?usp=sharing>
