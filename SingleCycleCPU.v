module SingleCycleCPU (
    input clk,
    input start
    
);

// When input start is zero, cpu should reset
// When input start is high, cpu start running

// TODO: connect wire to realize SingleCycleCPU
// The following provides simple template,



wire [31:0] pc_input,pc_output;  //wire for input and output of program counter
wire [31:0] adder1_output;    //wire for the ouput of the adder1 which is PC+4
wire[31:0] instruction;      //wire for 32 bit instruction
wire memRead_ctl,branch_ctl,memWrite_ctl,ALUSrc_ctl,regWrite_ctl;   //wires for control signals
wire [1:0] memtoReg_ctl;//changing to 2 bits for PC+4 return address to be loaded in a register for jal,jalr.
wire [1:0] ALUOp_ctl; //wire for control signal ALUOp.
wire[31:0] imm_output; //output of immediate generator
wire [31:0] ShiftLeftOne_output;  //output of the left shifter by 1 unit
wire [31:0] adder2_output;   //output of the adder2
wire zero;  //zero flag of the ALU

//updated logic for branch instructions
wire mux_pc_sel;  
reg branch_taken;   //since branch_taken is to be used in case statement under always blok, defining it as reg
always@(*) begin
    branch_taken=1'b0; //intitiate by assuming that branch is not taken, to avoid any latch.

    if(branch_ctl) begin
        case(instruction[14:12]) //look up the funct3 field
        3'b000: branch_taken= zero;  //if zero flag is high and beq is given, it would be taken
        3'b001: branch_taken= ~zero;  //if zero flag is low and bne is given, it would be taken
        3'b100: branch_taken= ALU_output[0]; //if lsb of ALU output is high and blt is given, it would be taken
        3'b101: branch_taken= ~ALU_output[0]; //if lsb of ALU output is low and bge is given, it would be taken
        default: branch_taken=1'b0;    //default case is that branch wont be taken
        endcase
         end
end
assign mux_pc_sel= branch_taken;  //branch_taken will decide which line would be selected in Mux_PC

wire jump_ctl, jalr_ctl; //wires for jump and jalr control signals
wire [31:0] readData1_register, readData2_register;   //the readData lines goinf out of the registers.
wire [31:0] mux_alu_output;   //output of the mux_ALU
wire [3:0] alu_ctl;     //wire for ALUCtl signal 
wire [31:0] ALU_output;  //output of the ALU
wire [31:0] mux_memtoreg_output;    //output of the memtoReg mux
wire [31:0] memreadData;   //ReadData port of the data memory.



PC m_PC(
    .clk(clk),
    .rst(start),
    .pc_i(pc_input),
    .pc_o(pc_output)
);

Adder m_Adder_1(
    .a(pc_output),
    .b(32'd4),
    .sum(adder1_output)
);

InstructionMemory m_InstMem(
    .readAddr(pc_output),
    .inst(instruction)
);

Control m_Control(
    .opcode(instruction[6:0]),
    .branch(branch_ctl),
    .memRead(memRead_ctl),
    .memtoReg(memtoReg_ctl),
    .ALUOp(ALUOp_ctl),
    .memWrite(memWrite_ctl),
    .ALUSrc(ALUSrc_ctl),
    .regWrite(regWrite_ctl),
    .jump(jump_ctl),         //instantiating the new jump and jalr control siggnals
    .jalr(jalr_ctl)
);


Register m_Register(
    .clk(clk),
    .rst(start),
    .regWrite(regWrite_ctl),
    .readReg1(instruction[19:15]),
    .readReg2(instruction[24:20]),
    .writeReg(instruction[11:7]),
    .writeData(mux_memtoreg_output),
    .readData1(readData1_register),
    .readData2(readData2_register)
);


ImmGen #(.Width(32)) m_ImmGen(
    .inst(instruction),
    .imm(imm_output)
);

ShiftLeftOne m_ShiftLeftOne(
    .i(imm_output),
    .o(ShiftLeftOne_output)
);

Adder m_Adder_2(
    .a(pc_output),
    .b(ShiftLeftOne_output),
    .sum(adder2_output)
);


wire [31:0] branch_jump_pc;
//selects between PC+4 and PC+imm
Mux2to1 #(.size(32)) m_Mux_PC_Branch(
    .sel(mux_pc_sel | jump_ctl), //this line is the reason why we dont need to expand the select line to 2 bits
    .s0(adder1_output),
    .s1(adder2_output),
    .out(branch_jump_pc)
);

//selects between the above result and the ALU output (for JALR)
Mux2to1 #(.size(32)) m_Mux_PC_Jalr(  //this is the extra mux to account for jalr instruction
    .sel(jalr_ctl),
    .s0(branch_jump_pc),
    .s1(ALU_output), 
    .out(pc_input)
);

Mux2to1 #(.size(32)) m_Mux_ALU(
    .sel(ALUSrc_ctl),
    .s0(readData2_register),
    .s1(imm_output),
    .out(mux_alu_output)
);

ALUCtrl m_ALUCtrl(
    .ALUOp(ALUOp_ctl),
    .funct7(instruction[30]),
    .funct3(instruction[14:12]),
    .ALUCtl(alu_ctl)
);

ALU m_ALU(
    .ALUCtl(alu_ctl),
    .A(readData1_register),
    .B(mux_alu_output),
    .ALUOut(ALU_output),
    .zero(zero)
);

DataMemory m_DataMemory(
    .rst(start),
    .clk(clk),
    .memWrite(memWrite_ctl),
    .memRead(memRead_ctl),
    .address(ALU_output),
    .writeData(readData2_register),
    .readData(memreadData)
);

wire [31:0] mem_alu_result;
//selects between ALU and Memory (standard)
Mux2to1 #(.size(32)) m_Mux_WriteData_Mem(
    .sel(memtoReg_ctl[0]),
    .s0(ALU_output),
    .s1(memreadData),
    .out(mem_alu_result)
);

//selects between ALU/Mem and PC+4 (for jal/jalr)
Mux2to1 #(.size(32)) m_Mux_WriteData_PC( //this is the extra 2 to 1 mux to account for jal/jalr
    .sel(memtoReg_ctl[1]),
    .s0(mem_alu_result),
    .s1(adder1_output), //PC + 4 from adder1
    .out(mux_memtoreg_output)
);

endmodule
