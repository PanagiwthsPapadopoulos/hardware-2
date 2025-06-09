# Floating-Point Multiplier — SystemVerilog Coursework (AUTH 2025)

This repository contains the full implementation, verification, and simulation artifacts for a **pipelined single-precision floating-point multiplier**, developed as part of the **Low-Level Hardware Digital Systems II** course at the Aristotle University of Thessaloniki (AUTH), ECE Department. The design follows a modified IEEE 754 specification and is organized to reflect all required deliverables outlined in the official [Coursework Document](./lab_coursework_2025.pdf).

---

## 📘 Project Description

The primary objective of this coursework was to implement a **hardware-level multiplier** for IEEE 754 single-precision (32-bit) floating-point numbers using **SystemVerilog**. The design incorporates custom handling of denormal numbers and special cases like zero and infinity, as required by the professor. A fully-pipelined architecture with three stages is used to improve throughput.

The project consists of the following stages:

1. **Floating-point decomposition and preprocessing**
2. **Normalization of the mantissa**
3. **Rounding according to one of six rounding modes**
4. **Exception handling and special-case corrections**
5. **Status flag generation and assertion-based formal verification**
6. **Testbench-driven simulation and validation**

---

## 📁 Directory Structure

```text
├── exercise1/                      # Floating-point multiplier modules
│   ├── fp_mult.sv                 # Main pipelined datapath
│   ├── normalize_mult.sv         # Normalization of mantissa & exponent
│   ├── round_mult.sv             # Rounding logic for all 6 modes
│   ├── exception_mult.sv         # Special case and corner case handling
│   └── round_defs.sv             # Enumeration of rounding modes
│
├── exercise2/                      # Testbench for validation
│   ├── fp_mult_tb.sv             # Random + corner case testing
│   └── multiplication.sv        # Golden reference function (provided)
│
├── exercise3/                      # Assertion-based verification
│   ├── test_status_bits.sv       # Immediate assertions on status bits
│   └── test_status_z_combinations.sv # Temporal assertions on result correctness
│
├── fp_mult_top.sv                 # Top-level wrapper module (provided)
├── report.pdf                     # Full technical report with simulation screenshots
├── lab_coursework_2025.pdf        # Coursework assignment PDF
└── README.md                      # This documentation file
```
## 🔧 Implementation Details

### 📐 Data Format

- **Precision**: IEEE 754 single precision (32-bit)
- **Structure**:
  - **Sign**: 1 bit
  - **Exponent**: 8 bits (bias = 127)
  - **Mantissa**: 23 bits (with implicit leading 1)

### 🔁 Pipeline Architecture

This design follows a **three-stage pipeline**, as required:

| Pipeline Stage | Description |
|----------------|-------------|
| Stage 1 | Sign computation, exponent addition and bias subtraction, mantissa multiplication |
| Stage 2 | Normalization and pipelining (register insertion) |
| Stage 3 | Rounding, exception handling, and final output generation |

- All pipeline registers are triggered on the **positive clock edge (`posedge clk`)**
- The **reset signal (`rst`) is active-low** and initializes all pipeline registers to zero.

---

### 🎯 Rounding Modes

Declared via an `enum` in `round_defs.sv`, the supported rounding modes include:

- `IEEE_near`: Round to nearest (even on tie)
- `IEEE_zero`: Round toward zero
- `IEEE_pinf`: Round toward positive infinity
- `IEEE_ninf`: Round toward negative infinity
- `away_zero`: Round away from zero
- `odd_even`: Round to odd on tie

> **Note**: If an **invalid mode** is supplied, the rounding defaults to `IEEE_near`.

---

### ⚠️ Modified IEEE 754 Behavior

To comply with the coursework specification, the multiplier **does not follow strict IEEE 754** in all cases:

- **Denormalized numbers** are treated as **zero**
- **Multiplying zero with infinity** (e.g., `±0 × ±∞`) always yields **+∞**
- **NaNs** are interpreted internally as infinities
- **Mantissa overflow** can produce a 25-bit result to support post-rounding normalization
- **Overflow/Underflow** is handled using custom rules based on the result's sign and rounding mode

---

## 🧪 Testbench Overview

Implemented in `exercise2/fp_mult_tb.sv`, the testbench contains two phases:

### 1️⃣ Randomized Testing

- Uses `$urandom()` to generate values for `a` and `b`
- Applies all six rounding modes
- Compares outputs with the golden model from `multiplication.sv` (provided)
- Accounts for the **3-cycle pipeline delay** between input and valid output

### 2️⃣ Corner Case Validation

Tests all **144 combinations (12 × 12)** of the following values:

- Positive and negative **zero**
- Positive and negative **infinity**
- Positive and negative **quiet/signaling NaNs**
- Positive and negative **denormal** and **normal** values

Each combination is compared with the output of the reference model. If mismatches occur, detailed errors are printed.

---

## ✔️ Assertion-Based Verification

SystemVerilog Assertions (SVA) are implemented in `exercise3/`, using two modules:

- `test_status_bits.sv`: **Immediate assertions** check that illegal status flag combinations do not occur (e.g., `zero_f` and `inf_f` should not be asserted together).
- `test_status_z_combinations.sv`: **Concurrent assertions** check the correctness of the result `z` depending on the value of `status` bits.

### Example Assertions

- If `zero_f == 1`, then all bits of `z[30:23]` (exponent) must be `0`
- If `inf_f == 1`, then all bits of `z[30:23]` must be `1`
- If `huge_f == 1`, then `z` must represent either `+∞`, `-∞`, or `maxNorm`
- If `nan_f == 1`, then two inputs (2–3 cycles prior) must match the quiet/signaling NaN pattern
- If `tiny_f == 1`, then the result must be either `0` or `minNorm`

These modules are **bound** to `fp_mult_top` using the `bind` directive during simulation. Assertion pass/fail messages appear in the **simulator transcript**.

---

## ▶️ How to Simulate

### ✅ Supported Simulators

- [Questa – Intel FPGA Edition](https://www.intel.com/content/www/us/en/software-kit/684216/intel-quartus-prime-lite-edition-design-software-version-21-1-for-windows.html)
- [Cadence Xcelium](https://www.cadence.com)

### 🖥️ Basic Commands (example using Xcelium)

```sh
xrun -sv fp_mult_tb.sv fp_mult_top.sv exercise1/*.sv exercise2/*.sv exercise3/*.sv +access+r
```
### 📈 Waveform Dump (VCD)

To visualize signal activity during simulation using a waveform viewer such as **GTKWave**, insert the following code block into the `initial` section of your `fp_mult_tb.sv` testbench:

```systemverilog
initial begin
  $dumpfile("dump.vcd");
  $dumpvars(0, fp_mult_tb);
end
```
⚠️ Note: For simulators like Questa or Xcelium, additional flags may be required to ensure full visibility of signals. For example, when using Xcelium, include:

```systemverilog
+access+r
```
This enables read access to all hierarchical signals for waveform dumping.

After running the simulation, open the generated dump.vcd file with GTKWave or a compatible viewer to examine signal propagation and pipeline register behavior cycle-by-cycle.

### 👨‍🎓 Author

**Name**: Panagiotis Papadopoulos  
**Student ID**: 10697  
**Program**: Electrical & Computer Engineering  
**Institution**: Aristotle University of Thessaloniki (AUTH)  
**Academic Year**: 2024–2025  
**Course**: Low-Level Hardware Digital Systems II  
**Instructor**: Assoc. Prof. Vasilis F. Pavlidis  
**Teaching Assistant**: Evangelos Tzouvaras (PhD Student)

---

### 📚 References

- 📘 **Course Specification**: [lab_coursework_2025.pdf](./lab_coursework_2025.pdf)  
  Official assignment brief detailing design requirements, test methodology, and submission format.

- 🧰 **Intel Quartus & Questa FPGA Edition**  
  [https://www.intel.com/content/www/us/en/software-kit/684216](https://www.intel.com/content/www/us/en/software-kit/684216)  
  Recommended RTL simulation environment.

- 📖 **IEEE 754 Floating-Point Arithmetic Standard**  
  [https://en.wikipedia.org/wiki/IEEE_754](https://en.wikipedia.org/wiki/IEEE_754)  
  General background reference for binary floating-point operations.

- 🛠️ **GTKWave VCD Viewer**  
  [http://gtkwave.sourceforge.net](http://gtkwave.sourceforge.net)  
  Tool used for waveform inspection of VCD dumps during testbench simulation.

- 🔬 **SystemVerilog Language Reference Manual (IEEE 1800)**  
  Recommended for understanding SVA, binding, and `enum` definitions used in the project.