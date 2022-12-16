// low & high
`define LOW 1'b0
`define HIGH 1'b1


// optype
`define CAL 3'd0
`define CALi 3'd1
`define STR 3'd2
`define LAD 3'd3
`define BRA 3'd4
`define JUM 3'd5

// opcode
`define ADD  4'b0000
`define SUB  4'b1000
`define SLL  4'b0001
`define SLT  4'b0010
`define SLTU 4'b0011
`define XOR  4'b0100
`define SRL  4'b0101
`define SRA  4'b1101
`define OR   4'b0110
`define AND  4'b0111

`define ADDI  4'b0000
`define SLTI  4'b0010
`define SLTIU 4'b0011
`define XORI  4'b0100
`define ORI   4'b0110
`define ANDI  4'b0111
`define SLLI  4'b0001
`define SRLI  4'b0101
`define SRAI  4'b1101
`define AUIPC 4'b1111
`define LUI   4'b1100

`define SB 4'b0000
`define SH 4'b0001
`define SW 4'b0010

`define LB  4'b0000
`define LH  4'b0001
`define LW  4'b0010
`define LBU 4'b0100
`define LHU 4'b0101

`define BEQ  4'b0000
`define BNE  4'b0001
`define BLT  4'b0100
`define BGE  4'b0101
`define BLTU 4'b0110
`define BGEU 4'b0111

`define JAL  4'b0001
`define JALR 4'b0000

//ROB
`define ROB_SZ_LOG 4
`define ROB_SZ 32

//Reg
`define REG_SZ_LOG 4
`define REG_SZ 32

//RS
`define RS_SZ 32
`define RS_SZ_LOG 4

//LSB
`define LSB_SZ 32
`define LSB_SZ_LOG 4