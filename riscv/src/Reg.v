`include "def.v"
module Reg(
    input  wire                 clk,			// system clock signal
    input  wire                 rst,			// reset signal
    input  wire                 rdy,			// ready signal, pause cpu when low
    
    //add
    input  wire                 run_add,
    input  wire [4:0]           rs1,
    input  wire [4:0]           rs2,
    input  wire [4:0]           rd,
    input  wire [`ROB_SZ_LOG:0]  tail,

    //update
    input  wire                 run_upd,
    input  wire [`REG_SZ_LOG:0]  commit_rd,
    input  wire [31:0]          res,
    input  wire [`ROB_SZ_LOG:0]  head,
    
    //branch
    input  wire                 reset,
    
    //out id
    output reg                  Vj,
    output reg                  Qj,
    output reg                  Vk,
    output reg                  Qk,
);
    reg Busy[`REG_SZ-1];
    reg[`ROB_SZ_LOG:0] Reordered[`REG_SZ-1];
    reg[31:0] data[`REG_SZ-1];
    integer i;
    
    always @(*)begin
        if(run_add)begin
            if(Busy[rs1])begin
                Qj = Reordered[rs1];
            end else begin
                Vj = data[rs1];
                Qj = 0;
            end

            if(Busy[rs2])begin
                Qk = Reordered[rs2];
            end else begin
                Vk = data[rs2];
                Qk = 0;
            end
            
            Busy[rd] = 1;
            Reordered[rd] = tail;
        end
    end

    always @(posedge clk)begin
        if(rst)begin
            for( i=0;i<`REG_SZ;i++)begin
                Busy[i] <= 0;
                Reordered[i] <= 0;
                data[i] <= 0;
            end
        end
        else if(~rdy);
        else if(reset)begin
            for( i=0;i<`REG_SZ;i++)begin
                Busy[i] <= 0;
                Reordered[i] <= 0;
            end
        end else begin
            if(run_upd && Reordered[commit_rd] == head)begin
                Busy[commit_rd] <= 0;
                Reordered[commit_rd] <= 0;
                data[commit_rd] <= res;
            end
        end
    end
endmodule