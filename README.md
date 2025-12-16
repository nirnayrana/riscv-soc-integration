# Single-Cycle RISC-V System-on-Chip (SoC)

## 🚀 Overview
This project implements a fully functional **System-on-Chip (SoC)** based on the RISC-V architecture. It integrates a custom **Single-Cycle Processor**, an **AMBA APB v3.0 Bridge**, and a **UART Transmitter** into a unified system.

The design focuses on **Hardware/Software Co-design**, demonstrating how a processor interacts with peripherals using memory-mapped I/O and hardware-level flow control.

## 🔑 Key Features
* **Core Architecture:** RV32I Single-Cycle CPU (Executes 1 instruction per clock).
* **Instruction Set:** Supports Integer (I), Register (R), Store (S), Branch (B), and Upper (U) types.
* **Bus Protocol:** AMBA APB v3.0 Master Bridge implementing FSM-based communication.
* **Peripheral:** UART Transmitter with "Busy" signal feedback.
* **Flow Control:** Automatic CPU stalling mechanism that freezes the Program Counter (PC) when the UART buffer is full.

## 🛠️ Tech Stack
* **Language:** Verilog / SystemVerilog
* **Simulation:** Icarus Verilog & GTKWave
* **Architecture:** RISC-V (RV32I Base Integer Set)

## 📊 Verification
The system was verified using a C-to-Assembly driver that transmits strings over UART.
* **Result:** Successful transmission of data ("HI") with 1000ns hardware stalls verified via waveform analysis.
<img width="1858" height="435" alt="soc_wave" src="https://github.com/user-attachments/assets/920c9e8e-c982-4506-a724-509c3ee80bf5" />

GTKWave capture showing Hardware Flow Control. At marker 105ns, the UART begins transmission. The APB Bridge asserts the Stall signal, causing the Program Counter (PC) to freeze (flat line) until the transaction completes, preventing data loss.
* **Testbench:** `tb/riscv_soc_tb.sv` monitors the APB handshake and serial output.

## 📂 Directory Structure
* `rtl/` - Source code (CPU, Bridge, UART)
* `tb/` - Testbenches and Simulation scripts
* `docs/` - Waveforms and Architecture Diagrams
