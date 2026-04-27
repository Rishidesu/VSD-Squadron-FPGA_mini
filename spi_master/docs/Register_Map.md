# SPI Master IP – Register Map

## 1. Register Overview

| Offset | Name   | Access | Description               |
| ------ | ------ | ------ | ------------------------- |
| 0x00   | CTRL   | R/W    | Control and configuration |
| 0x01   | TXDATA | R/W    | Transmit data             |
| 0x02   | RXDATA | R      | Received data             |
| 0x03   | STATUS | R/W    | Status flags              |

---

## 2. CTRL Register (0x00)

### Description

Controls SPI enable, clock configuration, and transfer initiation.

### Fields

| Bit Range | Name   | Description                   |
| --------- | ------ | ----------------------------- |
| [0]       | ENABLE | Enables SPI module            |
| [1]       | START  | Starts transfer (auto-clears) |
| [15:8]    | CLKDIV | Clock divider value           |

### Behavior

* START is ignored if BUSY = 1
* START auto-clears after being set
* CLKDIV defines SPI clock speed

---

## 3. TXDATA Register (0x01)

### Description

Holds data to be transmitted.

### Fields

| Bit Range | Description   |
| --------- | ------------- |
| [7:0]     | Transmit data |

### Behavior

* Write ignored if BUSY = 1
* Data sent MSB first

---

## 4. RXDATA Register (0x02)

### Description

Stores received data from SPI slave.

### Fields

| Bit Range | Description   |
| --------- | ------------- |
| [7:0]     | Received data |

### Behavior

* Updated after transfer completes

---

## 5. STATUS Register (0x03)

### Description

Indicates SPI status.

### Fields

| Bit | Name | Description          |
| --- | ---- | -------------------- |
| [0] | BUSY | Transfer in progress |
| [1] | DONE | Transfer completed   |
| [2] | IDLE | SPI is idle          |

### Behavior

* DONE is **Write-One-To-Clear (W1C)**
* BUSY is automatically managed by hardware

---

## 6. Clock Formula

SPI clock frequency is derived from system clock:

SPI_CLK = SYSTEM_CLK / (2 × CLKDIV)

---

## 7. Access Rules

* CTRL and TXDATA must not be written during BUSY
* RXDATA should be read after DONE is set
* STATUS must be cleared manually

---
