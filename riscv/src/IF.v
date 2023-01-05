// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "def.v"

`ifndef IFMod
`define IFMod

module IF(
    input  wire                 clk,			// system clock signal
    input  wire                 rst,			// reset signal
    input  wire                 rdy,			// ready signal, pause cpu when low

    //mem
    input  wire                 flg_get,
    input  wire [31:0]          ins_in,

    //stall
    input  wire                 stall,

    //jal
    input  wire                 jal_reset,
    input  wire[31:0]           jal_pc,

    //for mem
    output  wire                nd_ins,
    output  wire[31:0]          pc_fetch,

    //for core
    output  reg                 ins_flg,
    output  reg[31:0]           ret_ins,
    output  reg[31:0]           ret_pc

    
);
    reg [31:0] pc = 0;

    assign nd_ins = (~rst) & (rdy) & (~jal_reset) & (~flg_get);
    assign pc_fetch = pc;


    always @(posedge clk) begin
        if(rst)begin
            pc <= 0;
            ins_flg <= 0;
        end else if(~rdy);
        else if(jal_reset)begin
            pc <= jal_pc;
            ins_flg <= 0;
        end else if(stall || !flg_get)begin
            ins_flg <= 0;
        end else begin

            ret_ins <= ins_in;
            ret_pc <= pc;
            ins_flg <= 1;
            
            if(ins_in[6:0] == 7'b1101111)
                pc <= pc+{{11{ins_in[31]}},ins_in[31],ins_in[19:12],ins_in[20],ins_in[30:21],1'b0};
            else pc <= pc + 4;
            
        end
        
    end

endmodule

`endif