`include "def.v"

module ALU(
    input wire       run_flg,
    input wire[`ROB_SZ_LOG:0]  rd_fr,
    input wire[31:0]  Vj,
    input wire[31:0]  Vk,
    input wire[31:0]  imm,
    input wire[31:0]  pc,
    input wire[3:0]   opcode,
    
    output wire res_flg,
    output reg[31:0] res,
    output reg[31:0] res2,
    output wire[`ROB_SZ_LOG:0] rd_to
);
    assign res_flg = run_flg;
    assign rd_to = rd_fr;
    always @(*)begin
        if(run_flg)begin
            case(opcode)
                `ADD : res = Vj + Vk;
                `SUB : res = Vj - Vk;
                `SLL : res = Vj << (Vk[4:0]);
                `SLT : res = $signed(Vj) < $signed(Vk);
                `SLTU: res = Vj < Vk;
                `XOR : res = Vj ^ Vk;
                `SRL : res = Vj >> (Vk[4:0]);
                `SRA : res = $signed(Vj) >> (Vk[4:0]);
                `OR  : res = Vj | Vk;
                `AND : res = Vj & Vk;

                `ADDI : res = Vj + imm;
                `SLTI : res = $signed(Vj) < $signed(imm);
                `SLTIU: res = Vj < imm;
                `XORI : res = Vj ^ imm;
                `ORI  : res = Vj | imm;
                `ANDI : res = Vj & imm;
                `SLLI : res = Vj << imm;
                `SRLI : res = Vj >> imm;
                `SRAI : res = $signed(Vj) >> imm;
                `AUIPC: res = imm + pc;
                `LUI  : res = imm;

                `BEQ : begin
                    res2 = Vj == Vk;
                    res = imm + pc;
                end
                `BNE : begin
                    res2 = Vj != Vk;
                    res = imm + pc;
                end
                `BLT : begin
                    res2 = $signed(Vj) < $signed(Vk);
                    res = imm + pc;
                end
                `BGE : begin
                    res2 = $signed(Vj) >= $signed(Vk);
                    res = imm + pc;
                end
                `BLTU: begin
                    res2 = Vj < Vk;
                    res = imm + pc;
                end
                `BGEU: begin
                    res2 = Vj >= Vk;
                    res = imm + pc;
                end

                `JAL : res = pc + 4;
                `JALR: begin 
                    res2 = (Vj + imm)&(~(32'h00000001)); 
                    res = pc + 4;
                end
            endcase
        end
    end
endmodule