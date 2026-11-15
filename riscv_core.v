`timescale 1ns/1ps

//////////////////////////////////////////////////////////////
// RISC-V CORE (MULTI-CYCLE, SYNTHESIS CLEAN)
//////////////////////////////////////////////////////////////
module riscv_core(
    input clk,
    input reset,

    // Debug outputs
    output [31:0] pc_out,
    output [31:0] instr_out,
    output [31:0] alu_out_out,
    output [31:0] x3_out,
    output [31:0] mem96_out
);

    // FSM states
    localparam FETCH     = 3'd0,
               DECODE    = 3'd1,
               EXECUTE   = 3'd2,
               MEMORY    = 3'd3,
               WRITEBACK = 3'd4;

    reg [2:0] state;

    // PC & instruction
    reg [31:0] pc;
    reg [31:0] instr;

    // Memories (simple inferred RAMs)
    reg [31:0] instr_mem [0:255];
    reg [31:0] data_mem  [0:255];

    // Register file interface
    wire [4:0] rs1 = instr[19:15];
    wire [4:0] rs2 = instr[24:20];
    wire [4:0] rd  = instr[11:7];

    wire [6:0] opcode = instr[6:0];
    wire [6:0] funct7 = instr[31:25];

    wire [31:0] rd1, rd2;
    wire [31:0] x3_debug;

    reg        reg_we;
    reg [31:0] write_data;

    register_file rf (
        .clk(clk),
        .reset(reset),
        .we(reg_we),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(write_data),
        .rd1(rd1),
        .rd2(rd2),
        .x3_debug(x3_debug)
    );

    // Immediates
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7],
                         instr[30:25], instr[11:8], 1'b0};

    // ALU
    reg  [3:0]  alu_ctrl;
    wire [31:0] alu_out;
    wire        zero;

    wire [31:0] alu_src2 =
        (opcode == 7'b0010011) ? imm_i :
        (opcode == 7'b0000011) ? imm_i :
        (opcode == 7'b0100011) ? imm_s :
                                 rd2;

    alu alu_unit (
        .a(rd1),
        .b(alu_src2),
        .alu_ctrl(alu_ctrl),
        .result(alu_out),
        .zero(zero)
    );

    //////////////////////////////////////////////////////////
    // FSM
    //////////////////////////////////////////////////////////
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc      <= 32'd0;
            instr   <= 32'd0;
            state   <= FETCH;
            reg_we  <= 1'b0;
        end else begin
            case (state)

                FETCH: begin
                    instr <= instr_mem[pc[9:2]];
                    state <= DECODE;
                end

                DECODE: begin
                    state <= EXECUTE;
                end

                EXECUTE: begin
                    case (opcode)
                        7'b0110011: begin
                            if (funct7 == 7'b0100000)
                                alu_ctrl <= 4'b0001; // SUB
                            else
                                alu_ctrl <= 4'b0000; // ADD
                        end
                        7'b0010011,
                        7'b0000011,
                        7'b0100011:
                            alu_ctrl <= 4'b0000;
                        default:
                            alu_ctrl <= 4'b0000;
                    endcase

                    if (opcode == 7'b1100011) begin
                        if (rd1 == rd2)
                            pc <= pc + imm_b;
                        else
                            pc <= pc + 4;
                        state <= FETCH;
                    end else begin
                        state <= MEMORY;
                    end
                end

                MEMORY: begin
                    if (opcode == 7'b0100011) begin
                        data_mem[alu_out[9:2]] <= rd2;
                    end
                    state <= WRITEBACK;
                end

                WRITEBACK: begin
                    reg_we <= 1'b0;

                    if (opcode == 7'b0110011 ||
                        opcode == 7'b0010011) begin
                        write_data <= alu_out;
                        reg_we     <= 1'b1;
                    end
                    else if (opcode == 7'b0000011) begin
                        write_data <= data_mem[alu_out[9:2]];
                        reg_we     <= 1'b1;
                    end

                    if (opcode != 7'b1100011)
                        pc <= pc + 4;

                    state <= FETCH;
                end

                default: state <= FETCH;

            endcase
        end
    end

    //////////////////////////////////////////////////////////
    // Debug outputs
    //////////////////////////////////////////////////////////
    assign pc_out      = pc;
    assign instr_out   = instr;
    assign alu_out_out = alu_out;
    assign x3_out      = x3_debug;
    assign mem96_out   = data_mem[96];

endmodule


//////////////////////////////////////////////////////////////
// ALU
//////////////////////////////////////////////////////////////
module alu(
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  alu_ctrl,
    output reg [31:0] result,
    output zero
);

    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;
            4'b0001: result = a - b;
            default: result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule


//////////////////////////////////////////////////////////////
// REGISTER FILE (SYNTHESIS CLEAN)
//////////////////////////////////////////////////////////////
module register_file(
    input clk,
    input reset,
    input we,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] wd,
    output [31:0] rd1,
    output [31:0] rd2,
    output [31:0] x3_debug
);

    reg [31:0] regs[0:31];
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end else begin
            if (we && rd != 0)
                regs[rd] <= wd;
        end
    end

    assign rd1 = (rs1 == 0) ? 32'd0 : regs[rs1];
    assign rd2 = (rs2 == 0) ? 32'd0 : regs[rs2];
    assign x3_debug = regs[3];

endmodule
