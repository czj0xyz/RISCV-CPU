//start from 1
`include "def.v"

`ifndef ROBMod
`define ROBMod

module ROB(
    input  wire                  clk,			// system clock signal
    input  wire                  rst,			// reset signal
    input  wire                  rdy,			// ready signal, pause cpu when low
    //ins
    input  wire                  run_add,
    input  wire[`REG_SZ_LOG:0]   in_Dest,
    input  wire[3:0]             in_opcode,
    input  wire[3:0]             in_optype,

    //calc
    input  wire                    run_upd_alu,
    input  wire[`ROB_SZ_LOG:0]     alu_rd,
    input  wire[31:0]              alu_res,
    input  wire[31:0]              alu_res2,
    

    //load
    input  wire                    run_upd_lad,
    input  wire[`ROB_SZ_LOG:0]     lad_rd,
    input  wire[31:0]              lad_res,

    //store
    input  wire                     run_upd_str,
    input  wire[`ROB_SZ_LOG:0]      str_rd,

    //jal fail
    input  wire                     reset,

    //reg
    input  wire[`ROB_SZ_LOG:0]      rs1_id,
    input  wire[`ROB_SZ_LOG:0]      rs2_id,

    //to reg 
    output wire                     rs1_ready,
    output wire                     rs2_ready,
    output wire[31:0]               rs1_value,
    output wire[31:0]               rs2_value,

    //commit_info
    output reg                     ret_reg_flg,
    output reg[`REG_SZ_LOG:0]      ret_reg_rd,
    output reg[31:0]               ret_reg_res,

    output reg                     ret_str_flg,  

    output wire                    ret_full,
    output reg                     ret_jal_reset,
    output reg[31:0]               ret_jal_pc,

    output reg[`ROB_SZ_LOG:0]      ret_head,  
    output reg[`ROB_SZ_LOG:0]      ret_tail
);
    reg[31:0] Value[`ROB_SZ-1:0],Value2[`ROB_SZ-1:0];
    reg[3:0] opcode[`ROB_SZ-1:0],optype[`ROB_SZ-1:0];
    reg[`REG_SZ_LOG:0] Dest[`ROB_SZ-1:0];
    reg[1:0] Ready[`ROB_SZ-1:0];
    reg[`ROB_SZ_LOG:0] tail=1,head=1;

    assign rs1_ready = Ready[rs1_id];
    assign rs2_ready = Ready[rs2_id];
    assign rs1_value = Value[rs1_id];
    assign rs2_value = Value[rs2_id];    

    assign ret_full = (tail==`ROB_SZ-1&&head==1) || (tail+1 == head);
    wire pop_flg = head != tail && Ready[head]!=0 && !(optype[head]==`JUM && opcode[head] == `JALR && Ready[head] == 1);

    always @(posedge clk)begin
        if(rst) begin
            tail <= 1;
            head <= 1;
            ret_reg_flg <= 0;
            ret_str_flg <= 0;
            ret_jal_reset <=0;
        end else if(~rdy);
        else if(reset)begin
            tail <= 1;
            head <= 1;
            ret_reg_flg <= 0;
            ret_str_flg <= 0;
            ret_jal_reset <=0;
        end else begin
            ret_head <= head;
            ret_tail <= tail;
            if(head != tail && Ready[head] != 0)begin//commit
                if(optype[head]==`JUM && opcode[head] == `JALR)begin
                    ret_str_flg <= 0;
                    if(Ready[head] == 1)begin
                        ret_reg_flg <= 1;
                        ret_jal_reset <= 0;
                        ret_reg_rd <= Dest[head];
                        ret_reg_res <= Value[head];
                        Ready[head] <= 2;
                    end else begin
                        ret_reg_flg <= 0;
                        ret_jal_reset <= 1;
                        ret_jal_pc <= Value2[head];
                    end
                end else if(optype[head] == `BRA)begin
                    ret_str_flg <= 0;
                    ret_reg_flg <= 0;
                    if( Value2[head] )begin
                        ret_jal_reset <= 1;
                        ret_jal_pc <=Value[head];
                    end else ret_jal_reset <= 0;
                end else if(optype[head] ==`STR)begin
                    ret_str_flg <= 1;
                    ret_reg_flg <= 0;
                    ret_jal_reset <= 0;
                end else begin
                    ret_str_flg <= 0;
                    ret_jal_reset <= 0;
                    ret_reg_flg <= 1;
                    ret_reg_rd <= Dest[head];
                    ret_reg_res <= Value[head];
                end
                if(pop_flg)begin
                    if(head == `ROB_SZ-1) head <= 1;
                    else head <= head+1;
                end
            end else begin
                ret_reg_flg <= 0;
                ret_str_flg <= 0;
                ret_jal_reset <= 0;
            end

            //update
            if(run_add)begin
                opcode[tail] <= in_opcode;
                optype[tail] <= in_optype;
                Ready[tail] <= 0;
                Dest[tail] <= in_Dest;
                if(tail == `ROB_SZ-1)tail <= 1;
                else tail <= tail+1;
            end

            if(run_upd_alu)begin
                Ready[alu_rd] <= 1;
                Value[alu_rd] <= alu_res;
                if(optype[alu_rd] == `BRA || (optype[alu_rd] == `JUM&&opcode[alu_rd] == `JALR))
                    Value2[alu_rd] <= alu_res2;
            end

            if(run_upd_lad)begin
                Ready[lad_rd] <= 1;
                Value[lad_rd] <= lad_res;
            end

            if(run_upd_str)begin
                Ready[str_rd] <= 1;
            end
            

        end
    end



endmodule

`endif