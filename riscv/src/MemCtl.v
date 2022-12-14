`include "def.v"

`ifndef MemCtlMod
`define MemCtlMod

module MemCtl(
    input  wire                 clk,			// system clock signal
    input  wire                 rst,			// reset signal
    input  wire                 rdy,			// ready signal, pause cpu when low
    input  wire                 io_buffer_full,
    
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
    output reg                  mem_wr_,		// write/read signal (1 for write)
 
    output reg                  ret_lsb_in_flg,
    output reg                  ret_inst_in_flg = 0,
    output reg[31:0]            ret_res,
    output reg                  ret_str_commit

);//read all 1    write only 1
    reg[5:0]  lsb_out_len = 0;
    reg[31:0] lsb_out_num = 0;
    reg[31:0] lsb_out_addr = 0;

    reg lsb_in = 0;
    reg inst_in = 0;

    reg[3:0] get_len = 0, lsb_len_byte = 0;
    reg[7:0] data[2:0];
    reg[2:0] lsb_hv_wt = 0;

    integer i;

    reg valid[`ICACHE_SZ-1:0];
    reg[21:0] tag[`ICACHE_SZ-1:0];
    reg[31:0] icache_data[`ICACHE_SZ-1:0];

    wire stall_out = io_buffer_full & (lsb_out_flg ? (lsb_addr[17:16] == 2'b11) : ((lsb_out_addr[17:16] == 2'b11) & (lsb_out_len>0) ) );

    always @(*)begin
        if(!reset)begin
            if(lsb_out_flg || lsb_out_len > 0)begin
                if(stall_out)begin
                    mem_dout_ = 0;
                    mem_a_ = 0;
                    mem_wr_ = 0;
                end else begin
                    mem_wr_ = 1;
                    if(lsb_out_flg)begin
                        mem_a_  = lsb_addr;
                        mem_dout_ = lsb_num[7:0];
                    end else begin
                        mem_a_= lsb_out_addr;
                        case(lsb_hv_wt)
                            3'd0: mem_dout_ = lsb_out_num[7:0];
                            3'd1: mem_dout_ = lsb_out_num[15:8];
                            3'd2: mem_dout_ = lsb_out_num[23:16];
                            3'd3: mem_dout_ = lsb_out_num[31:24];
                            default: mem_dout_ = 0;
                        endcase
                    end
                end
            end else begin
                mem_wr_ = 0;
                mem_dout_ = 0;
                if(lsb_in_flg)begin
                    if(!lsb_in)mem_a_ = lsb_addr;
                    else mem_a_ = lsb_addr + get_len + 1;
                end else if(inst_in_flg)begin
                    if(!inst_in)mem_a_ = inst_addr;
                    else mem_a_ = inst_addr + get_len + 1;
                end else begin
                    mem_a_ = 0;
                end
            end 
        end else begin
            mem_dout_ = 0;
            mem_a_ = 0;
            mem_wr_ = 0;
        end

    end

    always @(posedge clk)begin
        if(rst)begin
            lsb_out_len <= 0;
            for(i=0;i<`ICACHE_SZ;i = i + 1) valid[i] <= 0;
        end else if(~rdy);
        else if(reset)begin
            lsb_in <= 0;
            inst_in <= 0;
            ret_lsb_in_flg <= 0;
            ret_inst_in_flg <= 0;
            ret_str_commit <= 0;
        end else begin
            if(lsb_out_flg || lsb_out_len > 0)begin
                lsb_in <= 0;
                inst_in <= 0;
                ret_lsb_in_flg <= 0;
                ret_inst_in_flg <= 0;
                if(lsb_out_flg)begin
                    if(~stall_out)begin
                        if(lsb_len == 8) ret_str_commit <= 1;
                        else ret_str_commit <= 0;

                        lsb_out_addr <= lsb_addr + 1;
                        lsb_out_num <= lsb_num;
                        lsb_out_len <= lsb_len - 8;
                        lsb_hv_wt <= 1;
                    end else begin
                        ret_str_commit <= 0;

                        lsb_out_addr <= lsb_addr;
                        lsb_out_num <= lsb_num;
                        lsb_out_len <= lsb_len;
                        lsb_hv_wt <= 0;
                    end
                end else if(~stall_out)begin
                    if(lsb_out_len == 8) ret_str_commit <= 1;
                    else ret_str_commit <= 0;

                    lsb_out_len <= lsb_out_len - 8;
                    lsb_out_addr <= lsb_out_addr + 1;
                    lsb_hv_wt <= lsb_hv_wt + 1;
                end else ret_str_commit <= 0;
            end else begin
                ret_str_commit <= 0;
                if(lsb_in_flg)begin
                    ret_inst_in_flg <= 0;
                    inst_in <= 0;
                    if(!lsb_in)begin
                        get_len <= 0;
                        ret_lsb_in_flg <= 0;
                        lsb_in <= 1;
                        case(lsb_len)
                            6'd8: lsb_len_byte <= 1;
                            6'd16: lsb_len_byte <= 2;
                            6'd24: lsb_len_byte <= 3;
                            default: lsb_len_byte <= 4;
                        endcase
                    end else begin
                        if(get_len+1 == lsb_len_byte)begin
                            ret_lsb_in_flg <= 1;
                            lsb_in <= 0;
                            case(lsb_len)
                                6'd8: ret_res <= {24'h000000,mem_din_};
                                6'd16: ret_res <= {12'h0000,mem_din_,data[0]};
                                6'd24: ret_res <= {6'h00,mem_din_,data[1],data[0]};
                                default: ret_res <= {mem_din_,data[2],data[1],data[0]};
                            endcase
                        end else begin
                            ret_lsb_in_flg <= 0;
                            data[get_len] <= mem_din_;
                            get_len <= get_len + 1;
                        end
                    end

                end else if(inst_in_flg)begin
                    ret_lsb_in_flg <= 0;
                    lsb_in <= 0;

                    if(valid[inst_addr[`iIndex]] && tag[inst_addr[`iIndex]] == inst_addr[`iTag])begin//hit
                        ret_inst_in_flg <= 1;
                        inst_in <= 0;
                        ret_res <= icache_data[inst_addr[`iIndex]];
                    end else begin
                        if(!inst_in)begin
                            get_len <= 0;
                            ret_inst_in_flg <= 0;
                            inst_in <= 1;
                        end else begin
                            if(get_len == 3)begin
                                valid[inst_addr[`iIndex]] <= 1;
                                tag[inst_addr[`iIndex]] <= inst_addr[`iTag];
                                icache_data[inst_addr[`iIndex]] <= {mem_din_,data[2],data[1],data[0]};
                                
                                ret_inst_in_flg <= 1;
                                inst_in <= 0;
                                ret_res <= {mem_din_,data[2],data[1],data[0]};
                            end else begin
                                ret_inst_in_flg <= 0;
                                data[get_len] <= mem_din_;
                                get_len <= get_len + 1;
                            end
                        end
                    end
                end else begin
                    ret_lsb_in_flg <= 0;
                    ret_inst_in_flg <= 0;
                    inst_in <= 0;
                    lsb_in <= 0;
                end
            end
        end
    end
endmodule

`endif