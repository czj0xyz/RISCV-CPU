`include "def.v"

module MemCtl(
    input  wire                 clk,			// system clock signal
    input  wire                 rst,			// reset signal
    input  wire                 rdy,			// ready signal, pause cpu when low
    
    //from LSB 
    input  reg                  lsb_in_flg,
    input  reg                  lsb_out_flg,
    input  reg[5:0]             lsb_len,
    input  reg[31:0]            lsb_addr,
    input  reg[31:0]            lsb_num,

    //from inst
    input  reg                  inst_in_flg,
    input  reg                  inst_addr

    //from mem
    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

    output reg                  ret_lsb_in_flg,
    output reg                  ret_inst_in_flg,
    output reg[31:0]            ret_res,

);//read all 1    write only 1
    reg[5:0] lsb_out_len;
    reg[5:0] lsb_out_num;
    reg[5:0] lsb_out_addr;
    

endmodule