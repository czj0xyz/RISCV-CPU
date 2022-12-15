// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "def.v"

module IF(
    input  wire                 clk,			// system clock signal
    input  wire                 rst,			// reset signal
    input  wire                 rdy,			// ready signal, pause cpu when low
    input  wire                 flg_get,
    input  wire [31:0]          ins_in,
    input  wire                 stall,

    //for mem
    output  reg         nd_ins,
    output  reg [31:0]  pc_fetch,

    //for core
    output  reg  ins_core,
    output  reg[20:0] imm,
    output  reg[31:0] pc_ret,
    
    output  reg[3:0] opcode,
    output  reg[3:0] optype,

    output  reg[4:0] rs1,
    output  reg[4:0] rs2,
    output  reg[4:0] rd
    

);
    reg [31:0] pc = 0;
    reg hv_ins = 0;
    reg [31:0] ins = 0;

    always @(*)begin
        if(flg_get) begin
            hv_ins = `HIGH;
            ins = ins_in;
        end
        
        if(hv_ins) begin
            nd_ins = `LOW;
            pc_fetch = 32'h0;
        end 
        else begin
            nd_ins = `LOW;
            pc_fetch = pc;
        end
    end

    always @(posedge clk) begin
        if(rst)begin
            pc <= 0;
        end
        else if(rdy || stall || ~hv_ins)begin
            ins_core <= `LOW;
        end
        else begin
            ins_core <= `HIGH;
            hv_ins <= `LOW;
            
            rs1 <= ins[19:15];
            rs2 <= ins[24:20];
            rd <= ins[11:7];
            case(ins[6:0])
                7'b0110011: begin// CAL
                    optype <= `CAL;
                    imm <= 0;
                    opcode <= {ins[30],ins[14:12]};
                    pc <= pc+4;
                end
                7'b0010011: begin
                    optype <= `CALi;
                    if(ins[14:12] == 3'b001 || ins[14:12] == 3'b101) imm <= ins[24:20];
                    else imm <= {{20{ins[31]}},ins[31:20]};
                    opcode <= {ins[30],ins[14:12]};
                    pc <= pc+4;
                end
                7'b0100011: begin
                    optype <= `STR;
                    imm <= {{20{ins[31]}},ins[31:25],ins[11:7]};
                    opcode <= {1'b0,ins[14:12]};
                    pc <= pc+4;
                end
                7'b0000011: begin
                    optype <= `LAD;
                    imm <= {{20{ins[31]}},ins[31:20]};
                    opcode <= {1'b0,ins[14:12]};
                    pc <= pc+4;
                end
                7'b1100011: begin
                    optype <= `BRA;
                    imm <= {{19{ins[31]}},ins[31],ins[7],ins[30:25],ins[11:8],1'b0};
                    opcode <= {1'b0,ins[14:12]};
                    pc <= pc+4;
                end
                7'b1100111: begin
                    optype <= `JUM;
                    opcode <= `JALR;
                    imm <= {{20{ins[31]}},ins[31:20]};
                    pc <= pc+4;
                end
                7'b1101111: begin
                    optype <= `JUM;
                    opcode <= `JAL;
                    imm <= {{11{ins[31]}},ins[31],ins[19:12],ins[20],ins[30:21],1'b0};
                    pc <= pc+{{11{ins[31]}},ins[31],ins[19:12],ins[20],ins[30:21],1'b0};
                end
                7'b0010111: begin
                    optype <= `CALi;
                    opcode <= `AUIPC;
                    imm <= {ins[31:12],12'h0};
                    pc <= pc+4;
                end
                7'b0110111: begin
                    optype <= `CALi;
                    opcode <= `LUI;
                    imm <= {ins[31:12],12'h0};
                    pc <= pc+4;
                end
            endcase

            pc_ret <= pc + 4;
        end
        
    end

endmodule