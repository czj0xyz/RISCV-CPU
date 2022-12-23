// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "def.v"

`ifndef issueMod
`define issueMod

module issue(

    input  wire                 ins_flg,
    input  wire[31:0]           ins,
    input  wire[31:0]           pc,

    output wire                  ret_add,
    output reg                   rs1_hv,
    output reg                   rs2_hv,
    output reg                   rd_hv,

    output reg[4:0]              rs1,
    output reg[4:0]              rs2,
    output reg[4:0]              rd,
    output reg[31:0]             imm,
    output reg[31:0]             ret_pc,
    output reg[3:0]              opcode,
    output reg[3:0]              optype
    
);
    assign ret_add = ins_flg;

    always @(*) begin
        if(~ins_flg);
        else begin
            rs1 = ins[19:15];
            rs2 = ins[24:20];
            rd = ins[11:7];

            rs1_hv = 1;
            rs2_hv = 1;
            rd_hv = 1;

            case(ins[6:0])
                7'b0110011: begin// CAL
                    optype = `CAL;
                    imm = 0;
                    opcode = {ins[30],ins[14:12]};
                end
                7'b0010011: begin
                    rs2_hv = 0;
                    optype = `CALi;
                    if(ins[14:12] == 3'b001 || ins[14:12] == 3'b101) imm = ins[24:20];
                    else imm = {{20{ins[31]}},ins[31:20]};
                    if(ins[14:12] == 3'b001 || ins[14:12] == 3'b101)opcode = {ins[30],ins[14:12]};
                    else opcode = {1'b0,ins[14:12]};
                end
                7'b0100011: begin
                    rd_hv = 0;
                    optype = `STR;
                    imm = {{20{ins[31]}},ins[31:25],ins[11:7]};
                    opcode = {1'b0,ins[14:12]};
                end
                7'b0000011: begin
                    rs2_hv = 0;
                    optype = `LAD;
                    imm = {{20{ins[31]}},ins[31:20]};
                    opcode = {1'b0,ins[14:12]};
                end
                7'b1100011: begin
                    rd_hv = 0;
                    optype = `BRA;
                    imm = {{19{ins[31]}},ins[31],ins[7],ins[30:25],ins[11:8],1'b0};
                    opcode = {1'b0,ins[14:12]};
                end
                7'b1100111: begin
                    rs2_hv = 0;
                    optype = `JUM;
                    opcode = `JALR;
                    imm = {{20{ins[31]}},ins[31:20]};
                end
                7'b1101111: begin
                    rs1_hv = 0;
                    rs2_hv = 0;
                    optype = `JUM;
                    opcode = `JAL;
                    imm = {{11{ins[31]}},ins[31],ins[19:12],ins[20],ins[30:21],1'b0};
                end
                7'b0010111: begin
                    rs1_hv = 0;
                    rs2_hv = 0;
                    optype = `CALi;
                    opcode = `AUIPC;
                    imm = {ins[31:12],12'h0};
                end
                7'b0110111: begin
                    rs1_hv = 0;
                    rs2_hv = 0;
                    optype = `CALi;
                    opcode = `LUI;
                    imm = {ins[31:12],12'h0};
                end
            endcase

            ret_pc = pc;
        end
        
    end

endmodule

`endif