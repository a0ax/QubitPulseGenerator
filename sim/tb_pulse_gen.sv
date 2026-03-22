`timescale 1ns/1ps

module tb_pulse_gen;
    localparam int WIDTH_BITS  = 8;
    localparam int PERIOD_BITS = 16;
    localparam int RANDOM_TESTS = 50;

    logic clk;
    logic rst_n;
    logic enable;
    logic [WIDTH_BITS-1:0] width;
    logic [PERIOD_BITS-1:0] period;
    logic pulse;
    logic busy;

    int errors;
    int tests_run;
    int checks_run;
    int unsigned model_count;

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

    task automatic expect_bit(input string tag, input bit got, input bit exp);
        if (got !== exp) begin
            $error("%s mismatch: got=%0b exp=%0b at t=%0t", tag, got, exp, $time);
            errors++;
        end
    endtask

    task automatic drive_inputs(input bit en, input int unsigned w, input int unsigned p);
        @(negedge clk);
        enable = en;
        width = w[WIDTH_BITS-1:0];
        period = p[PERIOD_BITS-1:0];
    endtask

    task automatic check_cycle(input string tag);
        int unsigned width_eff;
        bit exp_pulse;
        bit exp_busy;

        @(posedge clk);
        #1;

        if (!rst_n || !enable || (period == 0) || (width == 0)) begin
            exp_pulse = 1'b0;
            exp_busy = 1'b0;
            model_count = '0;
        end else begin
            width_eff = (width >= period) ? period : width;
            exp_pulse = (model_count < width_eff);
            exp_busy = 1'b1;

            if (model_count == (period - 1))
                model_count = '0;
            else
                model_count++;
        end

        expect_bit({tag, " pulse"}, pulse, exp_pulse);
        expect_bit({tag, " busy"}, busy, exp_busy);
        checks_run++;
    endtask

    task automatic run_cycles(input int unsigned count, input string tag);
        for (int unsigned i = 0; i < count; i++) begin
            check_cycle(tag);
        end
    endtask

    task automatic assert_reset_low(input string tag);
        #1;
        expect_bit({tag, " pulse"}, pulse, 1'b0);
        expect_bit({tag, " busy"}, busy, 1'b0);
    endtask

    initial begin
        int unsigned seed;
        int unsigned random_period;
        int unsigned random_width;
        int unsigned random_cycles;

        clk = 1'b0;
        rst_n = 1'b1;
        enable = 1'b0;
        width = '0;
        period = '0;
        errors = 0;
        tests_run = 0;
        checks_run = 0;
        model_count = '0;

        seed = 32'h2A3B_4C5D;
        void'($urandom(seed));

        #2;
        rst_n = 1'b0;
        assert_reset_low("reset assert");
        tests_run++;
        run_cycles(2, "reset hold");

        rst_n = 1'b1;
        drive_inputs(1'b1, 0, 8);
        run_cycles(6, "width zero");
        tests_run++;

        drive_inputs(1'b1, 5, 0);
        run_cycles(6, "period zero");
        tests_run++;

        drive_inputs(1'b1, 4, 4);
        run_cycles(10, "width equals period");
        tests_run++;

        drive_inputs(1'b1, 9, 4);
        run_cycles(10, "width greater than period");
        tests_run++;

        drive_inputs(1'b1, 2, 5);
        run_cycles(3, "enable high before toggle");
        @(negedge clk);
        enable = 1'b0;
        run_cycles(2, "enable low toggle");
        @(negedge clk);
        enable = 1'b1;
        run_cycles(4, "enable high after toggle");
        tests_run++;

        drive_inputs(1'b1, 3, 7);
        run_cycles(3, "reset prep");
        rst_n = 1'b0;
        assert_reset_low("reset during run");
        run_cycles(2, "reset low hold");
        rst_n = 1'b1;
        drive_inputs(1'b1, 3, 7);
        run_cycles(4, "post reset recovery");
        tests_run++;

        for (int unsigned test = 0; test < RANDOM_TESTS; test++) begin
            random_period = $urandom_range(1, 8);
            random_width = $urandom_range(0, random_period + 4);
            random_cycles = $urandom_range(5, 10);

            drive_inputs(1'b1, random_width, random_period);
            run_cycles(random_cycles, "random pair");
            tests_run++;
        end

        if (errors == 0) begin
            $display("PASS: %0d tests run, %0d cycle checks completed", tests_run, checks_run);
        end else begin
            $fatal(1, "FAIL: %0d errors after %0d tests and %0d cycle checks", errors, tests_run, checks_run);
        end

        $finish;
    end
endmodule
