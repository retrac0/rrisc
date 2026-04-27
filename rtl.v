
module top();

endmodule

module register_file(
    input clk,
    input [2:0] sel1,
    input [2:0] sel2,
    input [2:0] selwr,
    input [11:0] data_in,
    output [11:0] data1,
    output [11:0] data2
);

    reg [11:0] regs[0:7];

    // r0 hardwired 0, r7 hardwired -1; r1-r6 are general purpose
    assign data1 = (sel1 == 3'd0) ? 12'd0 :
                   (sel1 == 3'd7) ? 12'hFFF :
                   regs[sel1];

    assign data2 = (sel2 == 3'd0) ? 12'd0 :
                   (sel2 == 3'd7) ? 12'hFFF :
                   regs[sel2];

    // writes to r0 and r7 are silently ignored
    always @(posedge clk) begin
        if (selwr != 3'd0 && selwr != 3'd7)
            regs[selwr] <= data_in;
    end

endmodule

module program_counter(
    input clk,
    input rst,
    input inc,
    input [11:0] pc_in,
    output [11:0] pc
);

    reg [11:0] pc_reg;

    assign pc = pc_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_reg <= 12'd0;
        else if (inc)
            pc_reg <= pc_reg + 1;
        else
            pc_reg <= pc_in;
    end
endmodule 

module ram64(
    input clk,
    input [5:0] addr,
    input [11:0] data_in,
    output [11:0] data_out,
    output rdy
);

    reg [11:0] mem[0:63];

    assign data_out = mem[addr];
    assign rdy = 1'b1; // always ready for simplicity

    always @(posedge clk) begin
        mem[addr] <= data_in;
    end

endmodule

module rom1k(
    input [9:0] addr,
    output [11:0] data_out,
    output rdy
);

    reg [11:0] mem[0:1023];

    assign data_out = mem[addr];
    assign rdy = 1'b1; // always ready for simplicity

    // load ROM contents from a file (for simulation)
    initial begin
        $readmemb("rom.bin", mem);
    end

endmodule