# SPI Master IP for VSDSquadron FPGA

---

## 1. Overview

This IP implements a **memory-mapped SPI Master controller** integrated into a RISC-V SoC for the VSDSquadron FPGA platform.

The SPI controller is controlled entirely through register writes and reads over the processor memory bus, enabling software-driven SPI communication with external peripherals.

This IP is designed for:

* Simplicity
* Deterministic behavior
* Easy integration into lightweight SoCs

---

## 2. Key Characteristics (Reality, Not Marketing)

* **SPI Mode Supported**: Mode 0 only (CPOL = 0, CPHA = 0)
* **Data Width**: 8-bit transfers only
* **Operation Type**: Polling-based (no interrupts)
* **Clocking**: Programmable clock divider
* **Transfer Type**: Single-byte transactions
* **Chip Select**: Automatically managed per transaction

---

## 3. System Context

This SPI IP is integrated into a RISC-V SoC using a **memory-mapped interface**.

* Address decoding is handled at SoC level
* SPI is selected when address matches a fixed region
* CPU interacts via load/store instructions

From the SoC:

* SPI is mapped using address match logic 
* Communication occurs via standard memory signals (read/write strobes, data bus)

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

1. Software configures SPI (enable + clock divider)
2. Software writes transmit data
3. Software triggers transfer
4. SPI hardware:

   * Asserts chip select
   * Generates SPI clock
   * Shifts data out (MOSI)
   * Samples data in (MISO)
5. Transfer completes
6. Status flag is set
7. Received data becomes available

---

### 5.2 Internal Behavior

* Transfer is controlled by a **finite state machine**
* Clock is generated internally using a divider
* Data is:

  * **Shifted out on falling edge**
  * **Sampled on rising edge**

This confirms **SPI Mode 0 behavior** 

---

## 6. Register Map

| Offset | Register | Access | Description               |
| ------ | -------- | ------ | ------------------------- |
| 0x00   | CTRL     | R/W    | Control and configuration |
| 0x01   | TXDATA   | R/W    | Transmit data             |
| 0x02   | RXDATA   | R      | Received data             |
| 0x03   | STATUS   | R/W    | Status flags              |

---

### 6.1 CTRL Register

**Fields:**

* Enable bit → Enables SPI operation
* Start bit → Initiates a transfer (auto-clears)
* Clock Divider → Controls SPI clock speed

**Behavior:**

* Transfer starts only if SPI is enabled and not busy
* Start is ignored during active transfer

---

### 6.2 TXDATA Register

* Holds the byte to be transmitted
* Write is ignored if SPI is busy

---

### 6.3 RXDATA Register

* Contains last received byte after transfer completion

---

### 6.4 STATUS Register

**Flags:**

* Busy → SPI is currently transferring
* Done → Transfer completed

**Special Behavior:**

* Done flag is **write-one-to-clear (W1C)**

---

## 7. Software Programming Model

### 7.1 Initialization

* Enable SPI
* Configure clock divider

### 7.2 Data Transfer Sequence

1. Write transmit data
2. Trigger transfer
3. Poll status register until transfer completes
4. Read received data

### 7.3 Important Notes

* No queuing: one transfer at a time
* Software must ensure SPI is idle before starting next transfer
* Done flag must be cleared manually

---

## 8. Integration Guide (VSDSquadron SoC)

### 8.1 Required Files

* SPI module (RTL)
* SoC integration module

---

### 8.2 Address Mapping

SPI is selected when:

* Address falls within a predefined region
* Offset determines register access

Example behavior:

* Offset derived from lower address bits
* Upper bits used for peripheral selection

---

### 8.3 Bus Interface Signals

* Select signal (chip enable for SPI block)
* Write enable
* Read enable
* Address offset
* Write data
* Read data

---

### 8.4 External Signals

| Signal | Direction | Description            |
| ------ | --------- | ---------------------- |
| sclk   | Output    | SPI clock              |
| mosi   | Output    | Master data output     |
| miso   | Input     | Slave data input       |
| cs_n   | Output    | Active-low chip select |

---

## 9. Board-Level Usage (VSDSquadron FPGA)

### 9.1 Connections

* Connect MOSI, MISO, SCLK, and CS to external SPI device
* Ensure correct voltage compatibility
* Optional: debug signals can be observed internally

### 9.2 Example Use Cases

* Loopback test (MOSI connected to MISO)
* Sensor interfacing
* External SPI peripheral testing

---

## 10. Validation & Expected Behavior

### 10.1 Expected Observations

* CS goes low during transfer
* SCLK toggles based on divider
* MOSI outputs MSB-first data
* MISO data captured correctly

---

### 10.2 Debug Indicators

* Busy = 1 during transfer
* Done = 1 after completion
* RXDATA updates after transfer

---

### 10.3 SoC-Level Indicator

* LED is driven from received SPI data bit (debug path) 

---

## 11. Known Limitations 

* Only SPI Mode 0 supported
* No CPOL/CPHA configurability
* Single-byte transfer only
* No FIFO or buffering
* No interrupt support
* No multi-slave handling
* Software-driven only (no automation)

---

## 12. Folder Structure

```text
/ip/spi_master/
  rtl/
  software/
  docs/
    IP_User_Guide.md
    Register_Map.md
    Integration_Guide.md
    Example_Usage.md
  README.md
```

---

## 13. Quick Start (30-Second Integration)

1. Add SPI RTL to SoC
2. Map SPI into memory space
3. Connect SPI pins to external device
4. Enable SPI via control register
5. Write data and trigger transfer
6. Poll status and read result

---

## 14. Documentation Index

* Register details → docs/Register_Map.md
* Integration steps → docs/Integration_Guide.md
* Usage examples → docs/Example_Usage.md

---
