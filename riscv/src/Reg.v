`include "def.v"

`ifndef RegMod
`define RegMod

module Reg(
    input  wire                 clk,			// system clock signal
    input  wire                 rst,			// reset signal
    input  wire                 rdy,			// ready signal, pause cpu when low
    
    //add
    input  wire                  run_add,
    input  wire                  rs1_hv,
    input  wire [4:0]            rs1,
    input  wire                  rs2_hv,
    input  wire [4:0]            rs2,
    input  wire                  rd_hv,
    input  wire [4:0]            rd,
    input  wire [`ROB_SZ_LOG:0]  tail,

    //update
    input  wire                  run_upd,
    input  wire [`REG_SZ_LOG:0]  commit_rd,
    input  wire [31:0]           res,
    input  wire [`ROB_SZ_LOG:0]  head,
    
    //branch
    input  wire                 reset,
    
    //out id
    output reg[31:0]                  Vj,
    output reg[`ROB_SZ_LOG:0]         Qj,
    output reg[31:0]                  Vk,
    output reg[`ROB_SZ_LOG:0]         Qk
);
    reg Busy[`REG_SZ-1:0];
    reg[`ROB_SZ_LOG:0] Reordered[`REG_SZ-1:0];
    reg[31:0] data[`REG_SZ-1:0];
    // reg[31:0] pre_data[`REG_SZ-1:0];

    // reg flg_out;
    // reg[31:0] debug_ret;

    integer i;
    // integer fd;
    // initial begin
    //     fd = $fopen("DEBUG.out", "w+"); 
    // end
    always @(*)begin
        // flg_out = 0;
        // for(i=0;i<`REG_SZ;i++)
        //     if(pre_data[i] !=  data[i])flg_out = 1;

        if(run_add)begin
            if(rs1_hv)begin
                if(Busy[rs1])begin
                    Qj = Reordered[rs1];
                end else begin
                    Vj = data[rs1];
                    Qj = 0;
                end
            end else begin
                Vj = 0;
                Qj = 0;
            end
            
            if(rs2_hv)begin
                if(Busy[rs2])begin
                    Qk = Reordered[rs2];
                end else begin
                    Vk = data[rs2];
                    Qk = 0;
                end
            end else begin
                Vk = 0;
                Qk = 0;
            end
        end else begin
            Vj = 0;
            Qj = 0;
            Vk = 0;
            Qk = 0;
        end 
    end

    always @(posedge clk)begin
        // for(i=0;i<`REG_SZ;i++) pre_data[i] <= data[i];

        // if(flg_out)begin
        //     debug_ret = 0;
        //     for( i=0;i<`REG_SZ;i++)
        //         if(data[i] != 0)
        //             // debug_ret ^=  data[i];
        //             $fwrite(fd,"%d-%h",i,data[i]);
        //     // $fdisplay(fd,"%h",debug_ret);
        //     $fdisplay(fd,"");
        // end

        if(rst)begin
            for( i=0;i<`REG_SZ;i++)begin
                Busy[i] <= 0;
                Reordered[i] <= 0;
                data[i] <= 0;
            end
        end
        else if(~rdy);
        else if(reset)begin
            for( i=0;i<`REG_SZ;i = i + 1)begin
                Busy[i] <= 0;
                Reordered[i] <= 0;
            end
        end else begin
            // if(res == 32'h000012cc)$display(commit_rd);
            if(run_add && run_upd && commit_rd == rd)begin
                //data X
                Reordered[rd] = tail;
            end else begin
                if(run_upd && Reordered[commit_rd] == head)begin
                    Busy[commit_rd] <= 0;
                    Reordered[commit_rd] <= 0;
                    if(commit_rd != 0)data[commit_rd] <= res;
                end
                if(run_add && rd_hv) begin
                    Busy[rd] <= 1;
                    Reordered[rd] <= tail;
                end
            end
        end
    end
endmodule
`endif