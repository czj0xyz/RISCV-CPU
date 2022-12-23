`include "def.v"

`ifndef MemCtlMod
`define MemCtlMod

module MemCtl(
    input  wire                 clk,			// system clock signal
    input  wire                 rst,			// reset signal
    input  wire                 rdy,			// ready signal, pause cpu when low
    
    //from LSB 
    input  wire                  lsb_in_flg,
    input  wire                  lsb_out_flg,
    input  wire[5:0]             lsb_len,
    input  wire[31:0]            lsb_addr,
    input  wire[31:0]            lsb_num,

    //from inst
    input  wire                  inst_in_flg,
    input  wire[31:0]            inst_addr, 
    input  wire                  reset,

    //from mem
    input  wire [ 7:0]          mem_din_,		// data input bus
    output reg [ 7:0]           mem_dout_,		// data output bus
    output reg [31:0]           mem_a_,			// address bus (only 17:0 is used)
    output reg                  mem_wr_,			// write/read signal (1 for write)
 
    output reg                  ret_lsb_in_flg,
    output reg                  ret_inst_in_flg,
    output reg[31:0]            ret_res

);//read all 1    write only 1
    reg[5:0]  lsb_out_len = 0;
    reg[31:0] lsb_out_num;
    reg[31:0] lsb_out_addr;

    reg lsb_in = 0;
    reg inst_in = 0;

    reg[3:0] get_len;
    reg[7:0] data[3:0];

    reg[31:0] ans;
    integer i;

    always @(*)begin
        if(!reset)
        if(lsb_out_flg || lsb_out_len > 0)begin
            mem_wr_ = 1;
            if(lsb_out_flg) mem_a_  = lsb_addr;
            else mem_a_= lsb_out_addr;
            case(lsb_len)
                6'd32: mem_dout_ = lsb_num[31:24];
                6'd24: mem_dout_ = lsb_num[23:16];
                6'd16: mem_dout_ = lsb_num[15:8];
                6'd8:  mem_dout_ = lsb_num[7:0];
            endcase
        end else begin
            mem_wr_ = 0;
            if(lsb_in_flg)begin
                if(!lsb_in)mem_a_ = lsb_addr;
                else mem_a_ = lsb_addr + get_len + 1;
            end else if(inst_in_flg)begin
                if(!inst_in)mem_a_ = inst_addr;
                else mem_a_ = inst_addr + get_len + 1;
            end
        end


        data[get_len] = mem_din_;
        for(i=get_len+1;i<4;i=i+1)data[i] = 8'h00;
        ans = {data[3],data[2],data[1],data[0]};
    end

    always @(posedge clk)begin
        if(rst)begin
            lsb_out_len <= 0;
        end else if(~rdy);
        else if(reset)begin
            lsb_out_len <= 0;
            lsb_in <= 0;
            inst_in <= 0;
            get_len <= 0;
        end else begin
            if(lsb_out_flg || lsb_out_len > 0)begin
                lsb_in <= 0;
                inst_in <= 0;
                ret_lsb_in_flg <= 0;
                ret_inst_in_flg <= 0;
                if(lsb_out_flg)begin
                    lsb_out_addr <= lsb_addr;
                    lsb_out_num <= lsb_num;
                    lsb_out_len <= lsb_len - 8;
                end else begin
                    lsb_out_len <= lsb_out_len - 8;
                end
            end else begin
                mem_wr_ <= 0;
                if(lsb_in_flg)begin
                    ret_inst_in_flg <= 0;
                    inst_in <= 0;
                    if(!lsb_in)begin
                        get_len <= 0;
                        ret_lsb_in_flg <= 0;
                        lsb_in <= 1;
                    end else begin
                        if(get_len*8+8 == lsb_len)begin
                            ret_lsb_in_flg <= 1;
                            lsb_in <= 0;
                            ret_res <= ans;
                        end else begin
                            ret_lsb_in_flg <= 0;
                            data[get_len] <= mem_din_;
                            get_len <= get_len + 1;
                        end
                    end

                end else if(inst_in_flg)begin
                    ret_lsb_in_flg <= 0;
                    lsb_in <= 0;

                    if(!inst_in)begin
                        get_len <= 0;
                        ret_inst_in_flg <= 0;
                        inst_in <= 1;
                    end else begin
                        if(get_len == 3)begin
                            ret_inst_in_flg <= 1;
                            inst_in <= 0;
                            ret_res <= ans;
                        end else begin
                            ret_inst_in_flg <= 0;
                            data[get_len] <= mem_din_;
                            get_len <= get_len + 1;
                        end
                    end
                end else begin
                    ret_lsb_in_flg <= 0;
                    ret_inst_in_flg <= 0;
                end
            end
        end
    end
endmodule

`endif