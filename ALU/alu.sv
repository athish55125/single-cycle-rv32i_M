module alu #(parameter int DATA_WIDTH = 32)(
    input  logic [4:0]            alu_control,
    input  logic [DATA_WIDTH-1:0] rs1_data,
    input  logic [DATA_WIDTH-1:0] rs2_data,
    output logic [DATA_WIDTH-1:0] alu_out,
    output logic                  zero
);
    localparam int W = DATA_WIDTH;

    logic signed [W-1:0]   s1, s2;
    logic signed [2*W-1:0] mul_ss, mul_su, mul_uu;
    logic [W-1:0]          int_min;

    assign s1 = rs1_data;
    assign s2 = rs2_data;
    assign int_min = {1'b1, {(W-1){1'b0}}};

    // full-width products
    assign mul_ss = $signed({{W{rs1_data[W-1]}}, rs1_data}) * $signed({{W{rs2_data[W-1]}}, rs2_data});
    assign mul_su = $signed({{W{rs1_data[W-1]}}, rs1_data}) * $signed({{W{1'b0}},          rs2_data});
    assign mul_uu = $signed({{W{1'b0}},          rs1_data}) * $signed({{W{1'b0}},          rs2_data});

    always_comb begin
        alu_out = '0;
        zero    = 1'b0;
        case (alu_control)
            // ---- RV32I ----
            5'b00000: alu_out = rs1_data + rs2_data;
            5'b00001: alu_out = rs1_data - rs2_data;
            5'b00010: alu_out = rs1_data ^ rs2_data;
            5'b00011: alu_out = rs1_data | rs2_data;
            5'b00100: alu_out = rs1_data & rs2_data;
            5'b00101: alu_out = rs1_data << rs2_data[4:0];
            5'b00110: alu_out = rs1_data >> rs2_data[4:0];
            5'b00111: alu_out = s1 >>> rs2_data[4:0];
            5'b01000: alu_out = {{(W-1){1'b0}}, (s1 < s2)};
            5'b01001: alu_out = {{(W-1){1'b0}}, (rs1_data < rs2_data)};
            5'b01010: zero = (rs1_data == rs2_data);
            5'b01011: zero = (rs1_data != rs2_data);
            5'b01100: zero = (s1 <  s2);
            5'b01101: zero = (s1 >= s2);
            5'b01110: zero = (rs1_data <  rs2_data);
            5'b01111: zero = (rs1_data >= rs2_data);
            // ---- M extension ----
            5'b10000: alu_out = mul_ss[W-1:0];                       // MUL
            5'b10001: alu_out = mul_ss[2*W-1:W];                     // MULH
            5'b10010: alu_out = mul_su[2*W-1:W];                     // MULHSU
            5'b10011: alu_out = mul_uu[2*W-1:W];                     // MULHU
            5'b10100: begin                                          // DIV
                if (rs2_data == '0)                                alu_out = '1;
                else if (rs1_data == int_min && rs2_data == '1)    alu_out = int_min;
                else                                               alu_out = s1 / s2;
            end
            5'b10101: alu_out = (rs2_data == '0) ? '1 : (rs1_data / rs2_data);   // DIVU
            5'b10110: begin                                          // REM
                if (rs2_data == '0)                                alu_out = rs1_data;
                else if (rs1_data == int_min && rs2_data == '1)    alu_out = '0;
                else                                               alu_out = s1 % s2;
            end
            5'b10111: alu_out = (rs2_data == '0) ? rs1_data : (rs1_data % rs2_data); // REMU
            default: begin
                alu_out = '0;
                zero    = 1'b0;
            end
        endcase
    end
endmodule
