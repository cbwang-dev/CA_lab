//Module: CPU
//Function: CPU is the top design of the processor
//Inputs:
//	clk: main clock
//	arst_n: reset 
// 	enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// 	ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// 	ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory
//Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[31:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[31:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [31:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[31:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      31:0] branch_pc,updated_pc,current_pc,jump_pc,
                  instruction;
wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      31:0] regfile_wdata, dram_data,alu_out,
                  regfile_data_1,regfile_data_2,
                  alu_operand_2;

wire signed [31:0] immediate_extended;

reg  enable_reg = 1'b1;

// IF/ID: input instruction, output instruction_pipe_IF_ID
reg_arstn reg_instruction_pipe_IF_ID(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (instruction),
   .dout   (instruction_pipe_IF_ID)
);


wire [31:0] bbbb = instruction_pipe_IF_ID;
assign immediate_extended = $signed(bbbb[15:0]);


pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc_pipe_EX_ME ),
   .jump_pc   (jump_pc_pipe_EX_ME   ),
   .zero_flag (zero_flag ),
   .branch    (branch_pipe_EX_ME    ),
   .jump      (jump_pipe_EX_ME      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);

// IF/ID: input updated_pc, output updated_pc_pipe_IF_ID
reg_arstn reg_updated_pc_pipe_IF_ID(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (updated_pc),
   .dout   (updated_pc_pipe_IF_ID)
);

sram #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

control_unit control_unit(
   .opcode   (bbbb[31:26]),
   .reg_dst  (reg_dst           ), // ID_EX (in doc, but I think it is consumed during ID)
   .branch   (branch            ), // ME_WB
   .mem_read (mem_read          ), // EX_ME
   .mem_2_reg(mem_2_reg         ), // EX_ME
   .alu_op   (alu_op            ), // ID_EX
   .mem_write(mem_write         ), // EX_ME
   .alu_src  (alu_src           ), // ID_EX
   .reg_write(reg_write         ), // ID_EX (in doc, but I think it is consumed during ID)
   .jump     (jump              )  // ME_WB
);

// ID/EX: input branch, output branch_pipe_ID_EX

reg_arstn reg_reg_dst_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (reg_dst),
   .dout   (reg_dst_pipe_ID_EX)
);

reg_arstn reg_branch_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (branch),
   .dout   (branch_pipe_ID_EX)
);

reg_arstn reg_branch_pipe_EX_ME(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (branch_pipe_ID_EX),
   .dout   (branch_pipe_EX_ME)
);

// ID/EX: input mem_read, output mem_read_pipe_ID_EX
reg_arstn reg_mem_read_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (mem_read),
   .dout   (mem_read_pipe_ID_EX)
);

// ID/EX: input mem_2_reg, output mem_2_reg_pipe_ID_EX
reg_arstn reg_mem_2_reg_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (mem_2_reg),
   .dout   (mem_2_reg_pipe_ID_EX)
);

// ID/EX: input alu_op, output alu_op_pipe_ID_EX
reg_arstn reg_alu_op_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (alu_op),
   .dout   (alu_op_pipe_ID_EX)
);

// ID/EX: input mem_write, output mem_write_pipe_ID_EX
reg_arstn reg_mem_write_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (mem_write),
   .dout   (mem_write_pipe_ID_EX)
);

// ID/EX: input alu_src, output alu_src_pipe_ID_EX
reg_arstn reg_alu_src_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (alu_src),
   .dout   (alu_src_pipe_ID_EX)
);

reg_arstn reg_reg_write_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (reg_write),
   .dout   (reg_write_pipe_ID_EX)
);

reg_arstn reg_reg_write_pipe_EX_ME(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (reg_write_pipe_ID_EX),
   .dout   (reg_write_pipe_EX_ME)
);

reg_arstn reg_reg_write_pipe_ME_WB(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (reg_write_pipe_EX_ME),
   .dout   (reg_write_pipe_ME_WB)
);

// ID/EX: input jump, output jump_pipe_ID_EX
reg_arstn reg_jump_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (jump),
   .dout   (jump_pipe_ID_EX)
);

// ID/EX: input jump, output jump_pipe_ID_EX
reg_arstn reg_jump_pipe_EX_ME(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (jump_pipe_ID_EX),
   .dout   (jump_pipe_EX_ME)
);

// ID/EX: input instruction_pipe_IF_ID, output instruction_pipe_ID_EX
reg_arstn reg_instruction_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (bbbb),
   .dout   (instruction_pipe_ID_EX)
);


wire [31:0] aaaa = instruction_pipe_ID_EX;

mux_2 #(
   .DATA_W(5)
) regfile_dest_mux (
   .input_a (aaaa[15:11]),
   .input_b (aaaa[20:16]),
   .select_a(reg_dst_pipe_ID_EX          ),
   .mux_out (regfile_waddr     )
);

reg_arstn reg_regfile_waddr_EX_ME(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (regfile_waddr),
   .dout   (regfile_waddr_EX_ME)
);

reg_arstn reg_regfile_waddr_ME_WB(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (regfile_waddr_EX_ME),
   .dout   (regfile_waddr_ME_WB)
);


register_file #(
   .DATA_W(32)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(reg_write_pipe_ME_WB         ),
   .raddr_1  (bbbb[25:21]),
   .raddr_2  (bbbb[20:16]),
   .waddr    (regfile_waddr_ME_WB     ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_data_1    ),
   .rdata_2  (regfile_data_2    )
);

// ID/EX: input updated_pc_pipe_IF_ID, output updated_pc_pipe_ID_EX
reg_arstn reg_updated_pc_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (updated_pc_pipe_IF_ID),
   .dout   (updated_pc_pipe_ID_EX)
);

// ID/EX: input regfile_data_1, output regfile_data_1_pipe_ID_EX
reg_arstn reg_regfile_data_1_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (regfile_data_1),
   .dout   (regfile_data_1_pipe_ID_EX)
);

// ID/EX: input regfile_data_2, output regfile_data_2_pipe_ID_EX
reg_arstn reg_regfile_data_2_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (regfile_data_2),
   .dout   (regfile_data_2_pipe_ID_EX)
);



alu_control alu_ctrl(
   .function_field (aaaa[5:0]),
   .alu_op         (alu_op_pipe_ID_EX          ),
   .alu_control    (alu_control     )
);

// ID/EX: input instruction_pipe_IF_ID, output instruction_pipe_ID_EX
reg_arstn reg_immediate_extended_pipe_ID_EX(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (immediate_extended),
   .dout   (immediate_extended_pipe_ID_EX)
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux (
   .input_a (immediate_extended_pipe_ID_EX), // is this needed to be registered?
   .input_b (regfile_data_2_pipe_ID_EX    ),
   .select_a(alu_src_pipe_ID_EX           ),
   .mux_out (alu_operand_2     )
);


alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (regfile_data_1_pipe_ID_EX),
   .alu_in_1 (alu_operand_2 ),
   .alu_ctrl (alu_control   ),
   .alu_out  (alu_out       ),
   .shft_amnt(aaaa[10:6]),
   .zero_flag(zero_flag     ),
   .overflow (              )
);

// EX/ME: input alu_out, output alu_out_pipe_EX_ME
reg_arstn reg_alu_out_pipe_EX_ME(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (alu_out),
   .dout   (alu_out_pipe_EX_ME)
);

// EX/ME: input mem_write_pipe_ID_EX, output mem_write_pipe_EX_ME
reg_arstn reg_mem_write_pipe_EX_ME(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (mem_write_pipe_ID_EX),
   .dout   (mem_write_pipe_EX_ME)
);

// EX/ME: input mem_read_pipe_ID_EX, output mem_read_pipe_EX_ME
reg_arstn reg_mem_read_pipe_EX_ME(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (mem_read_pipe_ID_EX),
   .dout   (mem_read_pipe_EX_ME)
);

// EX/ME: input regfile_data_2_pipe_ID_EX, output regfile_data_2_pipe_EX_ME
reg_arstn reg_regfile_data_2_pipe_EX_ME(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (regfile_data_2_pipe_ID_EX),
   .dout   (regfile_data_2_pipe_EX_ME)
);

// EX/ME: input mem_2_reg_pipe_ID_EX, output mem_2_reg_pipe_EX_ME
reg_arstn reg_mem_2_reg_pipe_EX_ME(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (mem_2_reg_pipe_ID_EX),
   .dout   (mem_2_reg_pipe_EX_ME)
);

reg_arstn reg_mem_2_reg_pipe_ME_WB(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (mem_2_reg_pipe_EX_ME),
   .dout   (mem_2_reg_pipe_ME_WB)
);

sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk           ),
   .addr     (alu_out_pipe_EX_ME       ),
   .wen      (mem_write_pipe_EX_ME     ),
   .ren      (mem_read_pipe_EX_ME      ),
   .wdata    (regfile_data_2_pipe_EX_ME),
   .rdata    (dram_data     ),   
   .addr_ext (addr_ext_2    ),
   .wen_ext  (wen_ext_2     ),
   .ren_ext  (ren_ext_2     ),
   .wdata_ext(wdata_ext_2   ),
   .rdata_ext(rdata_ext_2   )
);

reg_arstn reg_dram_data_pipe_ME_WB(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (dram_data),
   .dout   (dram_data_pipe_ME_WB)
);

reg_arstn reg_alu_out_pipe_ME_WB(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (alu_out_pipe_EX_ME),
   .dout   (alu_out_pipe_ME_WB)
);


mux_2 #(
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (dram_data_pipe_ME_WB    ),
   .input_b  (alu_out_pipe_ME_WB      ),
   .select_a (mem_2_reg_pipe_ME_WB     ),
   .mux_out  (regfile_wdata)
);



branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (updated_pc_pipe_ID_EX ),
   .instruction  (instruction_pipe_ID_EX       ),
   .branch_offset(immediate_extended_pipe_ID_EX),
   .branch_pc    (branch_pc         ),
   .jump_pc      (jump_pc         )
);



// EX/ME: input updated_pc_pipe_IF_ID, output updated_pc_pipe_ID_EX
reg_arstn reg_branch_pc_pipe_EX_ME(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (branch_pc),
   .dout   (branch_pc_pipe_EX_ME)
);

// EX/ME: input updated_pc_pipe_IF_ID, output updated_pc_pipe_ID_EX
reg_arstn reg_jump_pc_pipe_EX_ME(
   .clk    (clk),
   .arst_n (arst_n),
//   .en     (enable_reg),
   .din    (jump_pc),
   .dout   (jump_pc_pipe_EX_ME)
);

endmodule


