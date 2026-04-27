# SPI Master IP – Example Usage

## 1. Overview

This document describes how to use the SPI IP from software running on the RISC-V processor.

---

## 2. Initialization Sequence

* Set clock divider
* Enable SPI

---

## 3. Data Transfer Procedure

### Step-by-step

1. Write data to TXDATA
2. Trigger transfer via CTRL
3. Poll STATUS register
4. Wait until DONE = 1
5. Read RXDATA
6. Clear DONE flag

---

## 4. Loopback Test

### Setup

* Connect MOSI to MISO

### Expected Result

* Transmitted data equals received data

---

## 5. External Device Communication

### Steps

* Configure SPI clock based on device
* Send command byte
* Read response

---

## 6. Expected Behavior

* CS goes low during transfer
* Clock toggles based on divider
* Data shifts MSB first

---

## 7. Debug Observations

* BUSY = 1 during transfer
* DONE = 1 after completion
* RXDATA updated after transfer

---

## 8. Failure Symptoms

| Issue           | Likely Cause       |
| --------------- | ------------------ |
| No clock output | SPI not enabled    |
| No response     | MISO not connected |
| Wrong data      | Timing mismatch    |
| Stuck BUSY      | FSM not completing |

---

## 9. Performance Notes

* Each transfer handles 8 bits only
* Throughput limited by software polling
* No pipelining

---
