`include "def.v"
module RS(
    input  wire                 clk,			// system clock signal
    input  wire                 rst,			// reset signal
    input  wire                 rdy,			// ready signal, pause cpu when low
    
    //add
    input  wire                  run_add,
    input  wire [31:0]           in_Vj,
    input  wire [`ROB_SZ_LOG:0]  in_Qj,
    input  wire [31:0]           in_Vk,
    input  wire [`ROB_SZ_LOG:0]  in_Qk, 
    input  wire [3:0]            in_opcode, 
    input  wire [`ROB_SZ_LOG:0]  in_Dest, 
    input  wire [31:0]           in_pc,

    //update ALU
    input  wire                  run_upd_alu,
    input  wire [`ROB_SZ_LOG:0]  alu_rd,
    input  wire [31:0]           alu_res,

    //update LAD
    input  wire                  run_upd_lad,
    input  wire [`REG_SZ_LOG:0]  lad_rd,
    input  wire [31:0]           lad_res,

    //branch
    input  wire                 reset,
    
    //output
    output reg                   cal_flg,
    output reg                   full,
    output reg[31:0]             ret_Vj,
    output reg[31:0]             ret_Vk,
    output reg[31:0]             ret_imm,
    output reg[31:0]             ret_opcode,
    output reg[`ROB_SZ_LOG:0]    ret_dest

);
    reg[`ROB_SZ_LOG:0] Qj[`RS_SZ-1],Qk[`RS_SZ-1];
    reg[31:0]          Vj[`RS_SZ-1],Vk[`RS_SZ-1],imm[`RS_SZ-1];
    reg[`ROB_SZ_LOG:0] Dest[`RS_SZ-1];
    reg[3:0]           opcode[`RS_SZ-1];
    reg                Busy[`RS_SZ-1];
    reg[31:0]          pc[`RS_SZ-1];

    always @(posedge clk)begin
    end

endmodule