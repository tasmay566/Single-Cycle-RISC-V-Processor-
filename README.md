# Single-Cycle RISC-V Processor in Verilog

## Project Overview
This project is a custom implementation of a 32-bit single-cycle RISC-V processor written in Verilog[cite: 4]. The architecture supports a robust set of base instructions alongside extended control flow mechanisms, including advanced conditional branches and jump instructions[cite: 4, 5]. The design is highly modular, featuring custom-built internal components integrated via a central hardware datapath[cite: 4].

## Architecture and Core Modules
* **ALU (Arithmetic Logic Unit):** Performs core arithmetic and logical operations such as addition, subtraction, AND, OR, and XOR based on internal control signals[cite: 4].
* **ALU Controller:** Generates the specific `ALUCtl` operation signal by evaluating the instruction's opcode, `funct3`, and `funct7` fields[cite: 4].
* **Control Unit:** Acts as a combinational logic center that decodes the instruction opcode to assert the necessary datapath control signals[cite: 4].
* **Immediate Generator:** Extracts and sign-extends 12-bit immediate values into 32-bit formats[cite: 4]. It handles various instruction formats (such as I-type and J-type) by concatenating bits in specific orders based on the instruction type[cite: 4, 5].
* **Main Datapath:** Integrates all instantiated modules and routes data signals appropriately to execute full instructions within a single clock cycle[cite: 4].

## Extended Instruction Support
The base processor has been optimized and expanded to support complex control flow instructions without requiring significant additional arithmetic hardware[cite: 5].

### Branch Instructions (`bne`, `blt`, `bge`)
* The ALU Controller distinguishes between branch conditions using the instruction's `funct3` field[cite: 5].
* For equality branches (`beq` and `bne`), the controller evaluates the ALU's zero flag[cite: 5].
* For magnitude branches (`blt` and `bge`), the processor utilizes a signed `slt` (Set Less Than) comparison and evaluates the least significant bit of the ALU result to determine if the branch should be taken[cite: 5].
* A dedicated combinational logic block processes these flags and controls the Program Counter (PC) multiplexer accordingly[cite: 5].

### Jump Instructions (`jal`, `jalr`)
* The Immediate Generator includes support for the J-type format for `jal` and the I-type format for `jalr`[cite: 5].
* To save the function return address, the `memtoReg` control signal was expanded to 2 bits to support storing the `PC + 4` address directly into a register[cite: 5].
* The datapath architecture utilizes cascaded multiplexers for PC routing: the PC multiplexer dynamically selects between `PC+4`, `PC+imm`, or the exact ALU output (for `jalr`)[cite: 5].
* A secondary set of cascaded multiplexers routes either the ALU result, memory read data, or the `PC+4` return address into the register file's write data port[cite: 5].

## Simulation and Verification
The processor logic and extended instructions were rigorously tested and validated using Icarus Verilog and GTKWave[cite: 5].
* **Data Processing Validation:** Verified by tracking accurate register states through iterative computational loops and targeted bit-extraction sequences[cite: 4, 5].
* **Control Flow Validation:** Evaluated using custom assembly testbenches specifically designed to trigger complex nested jumps and conditional branch pathways[cite: 5].
* **Result Verification:** Confirmed accurate state changes across the processor, verifying that branches resolved correctly and jumps successfully saved correct return addresses to destination registers[cite: 5].
