`timescale 1ns/1ps

module tb;

    reg clk;
    reg rst;

    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;

    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire        dmem_we;

    wire [31:0] pc_out;
    wire [31:0] wb_data_out;
    wire        wb_we_out;

    integer i;

    rv32i_top dut (
        .clk(clk),
        .rst(rst),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata),
        .dmem_we(dmem_we),
        .pc_out(pc_out),
        .wb_data_out(wb_data_out),
        .wb_we_out(wb_we_out)
    );

    reg [31:0] instr_mem [0:255];
    reg [31:0] data_mem  [0:255];

    assign imem_rdata = instr_mem[imem_addr[9:2]];
    assign dmem_rdata = data_mem[dmem_addr[9:2]];

    always @(posedge clk)
        if (dmem_we)
            data_mem[dmem_addr[9:2]] <= dmem_wdata;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;

        for (i = 0; i < 256; i = i + 1) begin
            instr_mem[i] = 0;
            data_mem[i]  = 0;
        end

        instr_mem[0] = 32'h00500093; // addi x1,x0,5
        instr_mem[1] = 32'h00700113; // addi x2,x0,7
        instr_mem[2] = 32'h002081b3; // add x3,x1,x2
        instr_mem[3] = 32'h06302023; // sw x3,96(x0)
        instr_mem[4] = 32'h06002283; // lw x4,96(x0)

        #20 rst = 0;
    end

    always @(posedge clk)
        $display("T=%0t PC=%h WB_WE=%b WB_DATA=%d MEM[96]=%d",
                 $time, pc_out, wb_we_out, wb_data_out,
                 data_mem[96>>2]);

    initial begin
        #300 $finish;
    end

endmodule
