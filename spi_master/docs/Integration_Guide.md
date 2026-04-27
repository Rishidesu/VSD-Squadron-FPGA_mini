# SPI Master IP – Integration Guide

## 1. Overview

This document explains how to integrate the SPI Master IP into a VSDSquadron SoC.

---

## 2. Integration Architecture

SPI is connected as a memory-mapped peripheral.

* CPU accesses SPI via load/store instructions
* Address decoding selects SPI module
* Register offset determines internal register

---

## 3. Required Connections

### Bus Interface

| Signal | Description        |
| ------ | ------------------ |
| sel    | SPI select         |
| w_en   | Write enable       |
| r_en   | Read enable        |
| offset | Register selection |
| wdata  | Write data         |
| rdata  | Read data          |

---

### External SPI Signals

| Signal | Direction | Description            |
| ------ | --------- | ---------------------- |
| sclk   | Output    | SPI clock              |
| mosi   | Output    | Data to slave          |
| miso   | Input     | Data from slave        |
| cs_n   | Output    | Active-low chip select |

---

## 4. Address Mapping

SPI is mapped into memory space using address decoding logic.

* Upper address bits select SPI
* Lower bits determine register offset

---

## 5. Integration Steps

1. Include SPI RTL in project
2. Instantiate SPI module in SoC
3. Connect bus interface signals
4. Add address decoding logic
5. Connect external SPI pins
6. Update constraints file

---

## 6. Clock and Reset

* Uses system clock
* Active-high reset (internally inverted if needed)

---

## 7. Verification Checklist

* SPI responds to correct address
* Registers are readable/writable
* Clock toggles during transfer
* CS signal behaves correctly

---

## 8. Common Integration Mistakes

* Incorrect address decoding
* Writing during BUSY state
* Missing reset connection
* Wrong pin mapping

---
