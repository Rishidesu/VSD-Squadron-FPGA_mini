# SPI Master IP – User Guide

## 1. Introduction

This document describes how to use the SPI Master IP integrated into the VSDSquadron RISC-V SoC.

The IP provides a simple, memory-mapped interface for communicating with SPI slave devices using software control.

---

## 2. Intended Users

This guide is for:

* Firmware developers
* FPGA integrators
* Embedded system designers

---

## 3. What This IP Does

The SPI Master IP allows the processor to:

* Send 8-bit data to SPI devices
* Receive 8-bit data from SPI devices
* Control SPI clock speed
* Monitor transfer completion

---

## 4. What This IP Does NOT Do

* No interrupt-based operation
* No DMA support
* No multi-byte automatic transfer
* No multi-slave management
* Only SPI Mode 0 supported

---

## 5. Basic Operation

### Step-by-step flow:

1. Enable SPI
2. Set clock divider
3. Write transmit data
4. Trigger transfer
5. Wait until transfer completes
6. Read received data

---

## 6. SPI Timing Behavior

* Clock idle state: LOW
* Data sampled on rising edge
* Data shifted on falling edge

This corresponds to **SPI Mode 0**.

---

## 7. Internal Operation Summary

* Uses FSM with states: IDLE → TRANSFER → FINISH
* Generates clock using programmable divider
* Performs MSB-first shifting
* Automatically controls chip select

---

## 8. Typical Use Case

Example scenarios:

* Reading sensor data
* Writing configuration to SPI devices
* Loopback testing

---

## 9. Debug Support

* Transmit and receive registers exposed internally
* Status flags indicate transfer state

---

## 10. Best Practices

* Always check BUSY before writing
* Clear DONE flag after each transfer
* Do not start transfer while BUSY is active

---
