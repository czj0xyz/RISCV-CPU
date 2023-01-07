`include "def.v"

`ifndef LSBMod
`define LSBMod

module LSB(
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
    input  wire [3:0]            in_type, 
    input  wire [`ROB_SZ_LOG:0]  in_Dest, 
    input  wire [31:0]           in_imm,

    //update ALU
    input  wire                  run_upd_alu,
    input  wire [`ROB_SZ_LOG:0]  alu_rd,
    input  wire [31:0]           alu_res,

    //update LAD
    input  wire                  run_upd_lad,
    input  wire [`REG_SZ_LOG:0]  lad_rd,
    input  wire [31:0]           lad_res,

    //for mem
    input  wire                  mem_flg,
    input  wire [31:0]           mem_res,
    input  wire                  mem_commit,

    //update ROB
    input  wire                  str_modi,
    input  wire[`ROB_SZ_LOG:0]   rob_head,

    //branch
    input  wire                 reset,
    
    //output
    output wire                 ret_full,
    output reg                  ret_lad_flg,
    output reg[31:0]            ret_lad_res,
    output reg[`ROB_SZ_LOG:0]   ret_dest,
    output reg                  ret_str_done,
    
    output reg                  mem_nd,
    output reg                  mem_out,
    output reg[5:0]             mem_len,
    output reg[31:0]            mem_st,
    output reg[31:0]            mem_x
);
    reg[`ROB_SZ_LOG:0] Qj[`LSB_SZ-1:0],Qk[`LSB_SZ-1:0],Dest[`LSB_SZ-1:0];
    reg[31:0]          Vj[`LSB_SZ-1:0],Vk[`LSB_SZ-1:0],imm[`LSB_SZ-1:0];
    reg[3:0]           opcode[`LSB_SZ-1:0],optype[`LSB_SZ-1:0];
    reg                Busy[`LSB_SZ-1:0];
    reg[`LSB_SZ_LOG:0] tail = 1,head = 1;
    integer i;
    assign ret_full = (tail==`ROB_SZ-1&&head==1) || (tail+1 == head);

    reg[5:0] len = 0;

    always @(*)begin
        len = 0;
        if(optype[head] == `LAD)
            case(opcode[head])
                `LB: len = 8;
                `LH: len = 16;
                `LW: len = 32;
                `LBU: len = 8;
                `LHU: len = 16;
                default:;
            endcase
        
        if(optype[head] == `STR)
            case(opcode[head])
                `SB: len = 8;
                `SH: len = 16;
                `SW: len = 32;
                default:;
            endcase
    end

    wire[31:0] load_addr = imm[head] + Vj[head];

    always @(posedge clk)begin
        if(rst)begin
            head <= 1;
            tail <= 1;
            mem_nd <= 0;
            mem_out <= 0;
            ret_lad_flg <= 0;
        end else if(~rdy);
        else if(reset)begin
            head <= 1;
            tail <= 1;
            mem_nd <= 0;
            mem_out <= 0;
            ret_lad_flg <= 0;
        end else begin
            //calc
            if(head != tail && !Qj[head] && !Qk[head])begin//calc
                if(optype[head] == `STR)begin//store
                    ret_lad_flg <= 0;
                    mem_nd <= 0;
                    if(str_modi)begin
                        ret_str_done <= 0;
                        mem_out <= 1;
                        mem_st <= Vj[head] + imm[head];
                        mem_len <= len;
                        mem_x <= Vk[head];
                        Dest[head] <= 0;
                    end else if(Dest[head])begin
                        ret_str_done <= 1;
                        ret_dest <= Dest[head];
                        mem_out <= 0;
                    end else begin
                        ret_str_done <= 0;
                        mem_out <= 0;
                    end

                    if(~Dest[head] && mem_commit)begin
                       if(head == `LSB_SZ-1) head <=1;
                       else head <= head+1;
                    end

                end else begin//load
                    ret_str_done <= 0;
                    mem_out <= 0;
                    if(load_addr[17:16] == 2'b11 && rob_head != Dest[head])begin
                        ret_lad_flg <= 0;
                        mem_nd <= 0;
                    end else begin
                        if(mem_flg)begin
                            ret_lad_flg <= 1;
                            ret_dest <= Dest[head];
                            if(opcode[head] == `LB)
                                ret_lad_res <= {{16{mem_res[7]}},mem_res[7:0]};
                            else if(opcode[head] == `LH)
                                ret_lad_res <= {{16{mem_res[15]}},mem_res[15:0]};
                            else ret_lad_res <= mem_res;
                            mem_nd <= 0;
                            if(head == `LSB_SZ-1) head <=1;
                            else head <= head+1;
                        end else begin
                            mem_nd <= 1;
                            mem_len <= len;
                            mem_st <= load_addr;
                            ret_lad_flg <= 0;
                        end
                    end
                end
            end else begin
                ret_lad_flg <= 0;
                ret_str_done <= 0;
                mem_nd <= 0;
                mem_out <= 0;
            end

            //update
            if(run_upd_lad)begin
                for(i = 0; i < `LSB_SZ ; i = i + 1)begin
                    if(Qj[i] == lad_rd)begin
                        Qj[i] <= 0;
                        Vj[i] <= lad_res;
                    end
                    if(Qk[i] == lad_rd)begin
                        Qk[i] <= 0;
                        Vk[i] <= lad_res;
                    end
                end
            end

            if(run_upd_alu)begin
                for(i = 0; i < `LSB_SZ ; i = i + 1)begin
                    if(Qj[i] == alu_rd)begin
                        Qj[i] <= 0;
                        Vj[i] <= alu_res;
                    end
                    if(Qk[i] == alu_rd)begin
                        Qk[i] <= 0;
                        Vk[i] <= alu_res;
                    end
                end
            end

            if(run_add && (in_type == `LAD || in_type == `STR))begin
                if(run_upd_lad && lad_rd == in_Qj) begin
                    Qj[tail] <= 0;
                    Vj[tail] <= lad_res;
                end else if(run_upd_alu && alu_rd == in_Qj)begin    
                    Qj[tail] <= 0;
                    Vj[tail] <= alu_res;
                end else begin
                    Qj[tail] <= in_Qj;
                    Vj[tail] <= in_Vj;
                end
                
                if(run_upd_lad && lad_rd == in_Qk) begin
                    Qk[tail] <= 0;
                    Vk[tail] <= lad_res;
                end else if(run_upd_alu && alu_rd == in_Qk)begin    
                    Qk[tail] <= 0;
                    Vk[tail] <= alu_res;
                end else begin
                    Qk[tail] <= in_Qk;
                    Vk[tail] <= in_Vk;
                end

                Dest[tail] <= in_Dest;
                imm[tail] <= in_imm;
                opcode[tail] <= in_opcode;
                optype[tail] <= in_type;

                if(tail == `LSB_SZ-1)tail <= 1;
                else tail <= tail+1;
            end
        end
    end
endmodule

`endif