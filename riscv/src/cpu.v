// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "ALU.v"
`include "def.v"
`include "IF.v"
`include "issue.v"
`include "LSB.v"
`include "MemCtl.v"
`include "Reg.v"
`include "ROB.v"
`include "RS.v"

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
  input  wire				  rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)


	wire lsb_mem_in_flg;
	wire lsb_mem_out_flg;
	wire[5:0] lsb_mem_len;
	wire[31:0] lsb_mem_addr;
	wire[31:0] lsb_mem_num;

	wire IF_mem_flg;
	wire[31:0] IF_mem_addr;

	wire mem_IF_flg;
	wire[31:0] mem_res;
	wire mem_lsb_flg;
	
	wire IF_issue_flg;
	wire[31:0] IF_issue_inst,IF_issue_pc;
	
	wire issue_add_flg,issue_RS_rs1_hv,issue_RS_rs2_hv,issue_RS_rd_hv;
	wire[4:0] issue_RS_rs1,issue_RS_rs2,issue_rd;
	wire[31:0] issue_imm,issue_pc;
	wire[3:0] issue_optype,issue_opcode;

	wire[`ROB_SZ_LOG:0] ROB_head,ROB_tail;
	wire ROB_com_reg_flg,ROB_com_str_flg;
	wire[`REG_SZ_LOG:0] ROB_com_reg_rd;
	wire[31:0] ROB_com_reg_res,ROB_jal_pc;
	wire ROB_full,ROB_jal_reset;

	wire RS_full;

	wire lsb_full,lsb_lad_flg;
	wire[31:0] lsb_lad_res;
	wire[`ROB_SZ_LOG:0] lsb_rd;
	wire lsb_str_done;

	wire RS_ALU_run_flg;
	wire[`ROB_SZ_LOG:0] RS_ALU_rd;
	wire[31:0] RS_ALU_Vj,RS_ALU_Vk,RS_ALU_imm,RS_ALU_pc;
	wire[3:0] RS_ALU_opcode,RS_ALU_optype;

	wire ALU_res_flg;
	wire[31:0] ALU_res,ALU_res2;
	wire[`ROB_SZ_LOG:0] ALU_rd_to;

	wire[31:0] Reg_RS_Vj,Reg_RS_Vk;
	wire[`ROB_SZ_LOG:0] Reg_RS_Qj,Reg_RS_Qk;

	wire STALL = lsb_full | RS_full | ROB_full;

	wire[`ROB_SZ_LOG:0] reg_rob_rs1_id,reg_rob_rs2_id;
	wire rob_reg_rs1_ready,rob_reg_rs2_ready;
	wire[31:0] rob_reg_rs1_value,rob_reg_rs2_value;
	wire mem_lsb_commit_flg;

	MemCtl memctl(
		.clk(clk_in),
		.rst(rst_in),
		.rdy(rdy_in),
		.io_buffer_full(io_buffer_full),

		.lsb_in_flg(lsb_mem_in_flg),
		.lsb_out_flg(lsb_mem_out_flg),
		.lsb_len(lsb_mem_len),
		.lsb_addr(lsb_mem_addr),
		.lsb_num(lsb_mem_num),

		.inst_in_flg(IF_mem_flg),
		.inst_addr(IF_mem_addr),
		.reset(ROB_jal_reset),

		.mem_din_(mem_din),
		.mem_dout_(mem_dout),
		.mem_a_(mem_a),
		.mem_wr_(mem_wr),

		.ret_lsb_in_flg(mem_lsb_flg),
		.ret_inst_in_flg(mem_IF_flg),
		.ret_res(mem_res),
		.ret_str_commit(mem_lsb_commit_flg)
	);

	ALU alu(
        .run_flg(RS_ALU_run_flg),
		.rd_fr(RS_ALU_rd),
		.Vj(RS_ALU_Vj),
		.Vk(RS_ALU_Vk),
		.imm(RS_ALU_imm),
		.pc(RS_ALU_pc),
		.opcode(RS_ALU_opcode),
		.optype(RS_ALU_optype),
    
		.res_flg(ALU_res_flg),
		.res(ALU_res),
		.res2(ALU_res2),
		.rd_to(ALU_rd_to)
	);

	IF if_(
		.clk(clk_in),
		.rst(rst_in),
		.rdy(rdy_in),

		.flg_get(mem_IF_flg),
		.ins_in(mem_res),

		.stall(STALL),

		.jal_reset(ROB_jal_reset),
		.jal_pc(ROB_jal_pc),

		.nd_ins(IF_mem_flg),
		.pc_fetch(IF_mem_addr),

		.ins_flg(IF_issue_flg),
		.ret_ins(IF_issue_inst),
		.ret_pc(IF_issue_pc)
	);

	issue iss(
		.ins_flg(IF_issue_flg),
		.ins(IF_issue_inst),
		.pc(IF_issue_pc),

		.ret_add(issue_add_flg),
		.rs1_hv(issue_RS_rs1_hv),
		.rs2_hv(issue_RS_rs2_hv),
		.rd_hv(issue_RS_rd_hv),

		.rs1(issue_RS_rs1),
		.rs2(issue_RS_rs2),
		.rd(issue_rd),
		.imm(issue_imm),
		.ret_pc(issue_pc),
		.opcode(issue_opcode),
		.optype(issue_optype)
	);

	Reg reg_(
		.clk(clk_in),
		.rst(rst_in),
		.rdy(rdy_in),
		
		.run_add(issue_add_flg),
		.rs1_hv(issue_RS_rs1_hv),
		.rs1(issue_RS_rs1),
		.rs2_hv(issue_RS_rs2_hv),
		.rs2(issue_RS_rs2),
		.rd_hv(issue_RS_rd_hv),
		.rd(issue_rd),
		.tail(ROB_tail),

		.rob_rs1_ready(rob_reg_rs1_ready),
		.rob_rs2_ready(rob_reg_rs2_ready),
		.rob_rs1_value(rob_reg_rs1_value),
		.rob_rs2_value(rob_reg_rs2_value),

		.run_upd(ROB_com_reg_flg),
		.commit_rd(ROB_com_reg_rd),
		.res(ROB_com_reg_res),
		.head(ROB_head),
	
		.reset(ROB_jal_reset),
		
		.Vj(Reg_RS_Vj),
		.Qj(Reg_RS_Qj),
		.Vk(Reg_RS_Vk),
		.Qk(Reg_RS_Qk),

		.rs1_id(reg_rob_rs1_id),
		.rs2_id(reg_rob_rs2_id)
	);

	RS rs(
    	.clk(clk_in),
    	.rst(rst_in),
    	.rdy(rdy_in),

    	.run_add(issue_add_flg),
    	.in_Vj(Reg_RS_Vj),
    	.in_Qj(Reg_RS_Qj),
    	.in_Vk(Reg_RS_Vk),
    	.in_Qk(Reg_RS_Qk), 
    	.in_opcode(issue_opcode), 
    	.in_optype(issue_optype), 
    	.in_Dest(ROB_tail), 
    	.in_pc(issue_pc),
    	.in_imm(issue_imm),

    	.run_upd_alu(ALU_res_flg),
    	.alu_rd(ALU_rd_to),
    	.alu_res(ALU_res),

    	.run_upd_lad(lsb_lad_flg),
    	.lad_rd(lsb_rd),
    	.lad_res(lsb_lad_res),

    	.reset(ROB_jal_reset),
	
    	.ret_cal_flg(RS_ALU_run_flg),
    	.ret_full(RS_full),
    	.ret_Vj(RS_ALU_Vj),
    	.ret_Vk(RS_ALU_Vk),
    	.ret_imm(RS_ALU_imm),
    	.ret_pc(RS_ALU_pc),
    	.ret_opcode(RS_ALU_opcode),
    	.ret_optype(RS_ALU_optype),
    	.ret_dest(RS_ALU_rd)
	);

	ROB rob(
		.clk(clk_in),
    	.rst(rst_in),
    	.rdy(rdy_in),
	
    	.run_add(issue_add_flg),
    	.in_Dest(issue_rd),
    	.in_opcode(issue_opcode),
    	.in_optype(issue_optype),

    	.run_upd_alu(ALU_res_flg),
    	.alu_rd(ALU_rd_to),
    	.alu_res(ALU_res),
    	.alu_res2(ALU_res2),
	
    	.run_upd_lad(lsb_lad_flg),
    	.lad_rd(lsb_rd),
    	.lad_res(lsb_lad_res),

  		.run_upd_str(lsb_str_done),
  		.str_rd(lsb_rd),
		.mem_commit(mem_lsb_commit_flg),

  		.reset(ROB_jal_reset),

		.rs1_id(reg_rob_rs1_id),
		.rs2_id(reg_rob_rs2_id),

		.rs1_ready(rob_reg_rs1_ready),
		.rs2_ready(rob_reg_rs2_ready),
		.rs1_value(rob_reg_rs1_value),
		.rs2_value(rob_reg_rs2_value),

  		.ret_reg_flg(ROB_com_reg_flg),
  		.ret_reg_rd(ROB_com_reg_rd),
  		.ret_reg_res(ROB_com_reg_res),

  		.ret_str_flg(ROB_com_str_flg),  

  		.ret_full(ROB_full),
  		.ret_jal_reset(ROB_jal_reset),
  		.ret_jal_pc(ROB_jal_pc),

        .ret_head(ROB_head), 
        .ret_tail(ROB_tail)
	);
	
	LSB lsb(
		.clk(clk_in),
    	.rst(rst_in),
    	.rdy(rdy_in),

    	.run_add(issue_add_flg),
    	.in_Vj(Reg_RS_Vj),
    	.in_Qj(Reg_RS_Qj),
    	.in_Vk(Reg_RS_Vk),
    	.in_Qk(Reg_RS_Qk), 
    	.in_opcode(issue_opcode), 
    	.in_type(issue_optype), 
    	.in_Dest(ROB_tail), 
    	.in_imm(issue_imm),

    	.run_upd_alu(ALU_res_flg),
    	.alu_rd(ALU_rd_to),
    	.alu_res(ALU_res),

    	.run_upd_lad(lsb_lad_flg),
    	.lad_rd(lsb_rd),
    	.lad_res(lsb_lad_res),

    	.mem_flg(mem_lsb_flg),
    	.mem_res(mem_res),

    	.str_modi(ROB_com_str_flg),
		.rob_head(ROB_head),

		.reset(ROB_jal_reset),

		.ret_full(lsb_full),
		.ret_lad_flg(lsb_lad_flg),
		.ret_lad_res(lsb_lad_res),
		.ret_dest(lsb_rd),
		.ret_str_done(lsb_str_done),

		.mem_nd(lsb_mem_in_flg),
		.mem_out(lsb_mem_out_flg),
		.mem_len(lsb_mem_len),
		.mem_st(lsb_mem_addr),
		.mem_x(lsb_mem_num)
	);

endmodule