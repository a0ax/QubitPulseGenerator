`timescale 1ns/1ps

module tb_pulse_gen;
    localparam int WIDTH_BITS  = 8;
    localparam int PERIOD_BITS = 16;

    logic clk;
    logic rst_n;
    logic enable;
    logic [WIDTH_BITS-1:0] width;
    logic [PERIOD_BITS-1:0] period;
    logic pulse;
    logic busy;

    int errors;

    pulse_gen #(
        .WIDTH_BITS(WIDTH_BITS),
        .PERIOD_BITS(PERIOD_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .width(width),
        .period(period),
        .pulse(pulse),
        .busy(busy)
    );

    always #5 clk = ~clk;

    task automatic expect_equal(input string tag, input bit got, input bit exp);
        if (got !== exp) begin
            $error("%s mismatch: got=%0b exp=%0b at t=%0t", tag, got, exp, $time);
            errors++;
        end
    endtask

    task automatic verify_periodic(input int unsigned w, input int unsigned p, input int unsigned cycles);
        int unsigned i;
        for (i = 0; i < cycles; i++) begin
            @(posedge clk);
            expect_equal("busy", busy, (enable && (w != 0) && (p != 0)));
            expect_equal("pulse", pulse, ((i % p) < ((w < p) ? w : p)));
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        enable = 1'b0;
        width = '0;
        period = '0;
        errors = 0;

        repeat (3) @(posedge clk);
        expect_equal("reset pulse", pulse, 1'b0);
        expect_equal("reset busy", busy, 1'b0);

        rst_n = 1'b1;
        @(posedge clk);

        width = 8'd1;
        period = 16'd2;
        enable = 1'b1;
        verify_periodic(1, 2, 12);

        enable = 1'b0;
        repeat (2) @(posedge clk);
        expect_equal("disabled pulse", pulse, 1'b0);
        expect_equal("disabled busy", busy, 1'b0);

        width = 8'hFF;
        period = 16'hFFFF;
        enable = 1'b1;
        verify_periodic(8'hFF, 16'hFFFF, 66000);

        enable = 1'b0;
        @(posedge clk);
        expect_equal("toggle low pulse", pulse, 1'b0);
        expect_equal("toggle low busy", busy, 1'b0);

        enable = 1'b1;
        verify_periodic(8'hFF, 16'hFFFF, 300);

        rst_n = 1'b0;
        @(posedge clk);
        expect_equal("reset2 pulse", pulse, 1'b0);
        expect_equal("reset2 busy", busy, 1'b0);
        rst_n = 1'b1;

        if (errors == 0)
            $display("PASS: all checks passed");
        else
            $fatal(1, "FAIL: %0d checks failed", errors);

        $finish;
    end
endmodule
