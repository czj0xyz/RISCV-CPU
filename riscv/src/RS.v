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
    input  wire [31:0]           in_imm,

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
    output reg                   ret_cal_flg,
    output reg                   ret_full,
    output reg[31:0]             ret_Vj,
    output reg[31:0]             ret_Vk,
    output reg[31:0]             ret_imm,
    output reg[31:0]             ret_pc,
    output reg[31:0]             ret_opcode,
    output reg[`ROB_SZ_LOG:0]    ret_dest

);
    reg[`ROB_SZ_LOG:0] Qj[`RS_SZ-1:0],Qk[`RS_SZ-1:0];
    reg[31:0]          Vj[`RS_SZ-1:0],Vk[`RS_SZ-1:0],imm[`RS_SZ-1:0];
    reg[`ROB_SZ_LOG:0] Dest[`RS_SZ-1:0];
    reg[3:0]           opcode[`RS_SZ-1:0];
    reg                Busy[`RS_SZ-1:0];
    reg[31:0]          pc[`RS_SZ-1:0];

    reg[`RS_SZ_LOG:0] ins_pl,cal_pl;
    reg full,cal_flg;
    integer i;

    always @(*)begin
        //find calc & reset
        full = 1;
        cal_flg = 0;
        for(i = 0;i < `RS_SZ; i++)
            if(Busy[i]==0)begin
                full = 0;
                ins_pl = i;
            end else if(Qj[i]==0 && Qk[i]==0)begin
                cal_flg = 1;
                cal_pl = i;
            end
        ret_full = full;
    end

    always @(posedge clk)begin
        if(rst)begin
            for(i = 0; i < `RS_SZ; i++)begin
                Busy[i] <= 0;
            end
        end else if(~rdy);
        else if(reset)begin
            for(i = 0; i < `RS_SZ; i++)begin
                Busy[i] <= 0;
            end
        end else begin
            if(cal_flg) begin
                ret_cal_flg <= `HIGH;
                ret_Vj <= Vj[cal_pl];
                ret_Vk <= Vk[cal_pl];
                ret_imm <= imm[cal_pl];
                ret_pc <= pc[cal_pl];
                ret_opcode <= opcode[cal_pl];
                ret_dest <= Dest[cal_pl];
                Busy[cal_pl] <= 0;
            end else ret_cal_flg <= `LOW;

            if(run_add)begin
                Busy[ins_pl] <= 1;
                Dest[ins_pl] <= in_Dest;
                opcode[ins_pl] <= in_opcode;
                pc[ins_pl] <= in_pc;
                imm[ins_pl] <= in_imm;

                if(run_upd_alu && alu_rd == in_Qj)begin
                    Qj[ins_pl] <= 0;
                    Vj[ins_pl] <= alu_res;
                end else if(run_upd_lad && lad_rd == in_Qj)begin
                    Qj[ins_pl] <= 0;
                    Vj[ins_pl] <= lad_res;
                end else begin
                    Qj[ins_pl] <= in_Qj;
                    Vj[ins_pl] <= in_Vj;
                end

                if(run_upd_alu && alu_rd == in_Qk)begin
                    Qk[ins_pl] <= 0;
                    Vk[ins_pl] <= alu_res;
                end else if(run_upd_lad && lad_rd == in_Qk)begin
                    Qk[ins_pl] <= 0;
                    Vk[ins_pl] <= lad_res;
                end else begin
                    Qk[ins_pl] <= in_Qk;
                    Vk[ins_pl] <= in_Vk;
                end
            end

            if(run_upd_alu)begin
                for(i = 0;i < `RS_SZ;i++)if(Busy[i])begin
                    if(Qj[i] == alu_rd) begin
                        Qj[i] <= 0;
                        Vj[i] <= alu_res;
                    end
                    if(Qk[i] == alu_rd) begin
                        Qk[i] <= 0;
                        Vk[i] <= alu_res;
                    end
                end
            end

            if(run_upd_lad)begin
                for(i = 0;i < `RS_SZ;i++)if(Busy[i])begin
                    if(Qj[i] == lad_rd) begin
                        Qj[i] <= 0;
                        Vj[i] <= lad_res;
                    end
                    if(Qk[i] == lad_rd) begin
                        Qk[i] <= 0;
                        Vk[i] <= lad_res;
                    end
                end
            end

        end
    end

endmodule