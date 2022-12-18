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
    output  reg                 nd_ins,
    output  reg [31:0]          pc_fetch,

    //for core
    output  reg                 ins_flg,
    output  reg[31:0]           ret_ins,
    output  reg[31:0]           ret_pc

    
);
    reg [31:0] pc = 0;
    reg hv_ins = 0;
    reg [31:0] ins = 0;

    always @(*)begin
        if(flg_get) begin
            hv_ins = 1;
            ins = ins_in;
        end
        
        if(hv_ins) begin
            nd_ins = `LOW;
            pc_fetch = 32'h0;
        end else begin
            nd_ins = `HIGH;
            pc_fetch = pc;
        end
    end

    always @(posedge clk) begin
        if(rst)begin
            pc <= 0;
        end
        else if(~rdy);
        else if(jal_reset)begin
            pc <= pc_fetch;
            hv_ins <= 0;
            ins <= 0;
        end else if(stall || ~hv_ins);
        else begin
            ins_flg <= `HIGH;
            hv_ins <= 0;
            ret_ins <= ins;
            
            if(ins[6:0] == 7'b1101111)
                pc <= pc+{{11{ins[31]}},ins[31],ins[19:12],ins[20],ins[30:21],1'b0};
            else pc <= pc + 4;

            ret_pc <= pc;
        end
        
    end

endmodule

`endif