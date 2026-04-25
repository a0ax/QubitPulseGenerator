`timescale 1ns/1ps

module tb_multi_pulse_gen;
    localparam int WIDTH_BITS   = 8;
    localparam int PERIOD_BITS  = 16;
    localparam int DATA_BITS    = (WIDTH_BITS > PERIOD_BITS) ? WIDTH_BITS : PERIOD_BITS;
    localparam int NUM_CHANNELS = 4;

    logic clk;
    logic rst_n;
    logic [1:0] channel_sel;
    logic wr_en;
    logic [1:0] addr;
    logic [DATA_BITS-1:0] wr_data;
    logic [DATA_BITS-1:0] rd_data;
    logic [NUM_CHANNELS-1:0] pulse_out;
    logic busy;

    int errors;
    int checks_run;
    int writes_run;
    int reads_run;

    int unsigned model_width [NUM_CHANNELS];
    int unsigned model_period [NUM_CHANNELS];
    int unsigned model_count [NUM_CHANNELS];
    bit model_enable [NUM_CHANNELS];

    multi_pulse_gen #(
        .WIDTH_BITS(WIDTH_BITS),
        .PERIOD_BITS(PERIOD_BITS),
        .NUM_CHANNELS(NUM_CHANNELS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .channel_sel(channel_sel),
        .wr_en(wr_en),
        .addr(addr),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .pulse_out(pulse_out),
        .busy(busy)
    );

    always #5 clk = ~clk;

    function automatic int unsigned min_unsigned(input int unsigned a, input int unsigned b);
        if (a < b)
            return a;
        return b;
    endfunction

    function automatic string channel_name(input int idx);
        case (idx)
            0: return "ch0";
            1: return "ch1";
            2: return "ch2";
            3: return "ch3";
            default: return "ch?";
        endcase
    endfunction

    task automatic reset_model;
        for (int i = 0; i < NUM_CHANNELS; i++) begin
            model_width[i] = 0;
            model_period[i] = 0;
            model_count[i] = 0;
            model_enable[i] = 0;
        end
    endtask

    task automatic model_step;
        for (int i = 0; i < NUM_CHANNELS; i++) begin
            if (!rst_n || !model_enable[i] || (model_width[i] == 0) || (model_period[i] == 0)) begin
                model_count[i] = 0;
            end else if (model_count[i] == (model_period[i] - 1)) begin
                model_count[i] = 0;
            end else begin
                model_count[i]++;
            end
        end
    endtask

    task automatic expect_bit(input string tag, input bit got, input bit exp);
        if (got !== exp) begin
            $error("%s mismatch: got=%0b exp=%0b at t=%0t", tag, got, exp, $time);
            errors++;
        end
    endtask

    task automatic expect_data(input string tag, input logic [DATA_BITS-1:0] got, input logic [DATA_BITS-1:0] exp);
        if (got !== exp) begin
            $error("%s mismatch: got=0x%0h exp=0x%0h at t=%0t", tag, got, exp, $time);
            errors++;
        end
    endtask

    task automatic bus_write(input logic [1:0] ch, input logic [1:0] reg_addr, input logic [DATA_BITS-1:0] data);
        @(negedge clk);
        channel_sel = ch;
        addr = reg_addr;
        wr_data = data;
        wr_en = 1'b1;
        @(posedge clk);
        #1;
        wr_en = 1'b0;
        model_step();
        case (reg_addr)
            2'd0: model_width[ch] = data[WIDTH_BITS-1:0];
            2'd1: model_period[ch] = data[PERIOD_BITS-1:0];
            2'd2: model_enable[ch] = data[0];
            default: begin
            end
        endcase
        writes_run++;
    endtask

    task automatic bus_read(input logic [1:0] ch, input logic [1:0] reg_addr, input logic [DATA_BITS-1:0] exp, input string tag);
        @(negedge clk);
        channel_sel = ch;
        addr = reg_addr;
        wr_en = 1'b0;
        wr_data = '0;
        model_step();
        #1;
        expect_data(tag, rd_data, exp);
        reads_run++;
    endtask

    task automatic step_and_check(input string tag);
        bit expected_busy;

        @(posedge clk);
        #1;
        expected_busy = 1'b0;

        for (int i = 0; i < NUM_CHANNELS; i++) begin
            bit exp_pulse;
            int unsigned width_eff;

            if (!rst_n || !model_enable[i] || (model_width[i] == 0) || (model_period[i] == 0)) begin
                exp_pulse = 1'b0;
            end else begin
                width_eff = min_unsigned(model_width[i], model_period[i]);
                exp_pulse = (model_count[i] < width_eff);
                expected_busy = 1'b1;
            end

            expect_bit({tag, " ", channel_name(i), " pulse"}, pulse_out[i], exp_pulse);
        end

        expect_bit({tag, " busy"}, busy, expected_busy);
        model_step();
        checks_run++;
    endtask

    task automatic run_cycles(input int unsigned count, input string tag);
        for (int unsigned i = 0; i < count; i++) begin
            step_and_check(tag);
        end
    endtask

    task automatic configure_channel(input logic [1:0] ch, input int unsigned width_value, input int unsigned period_value, input bit enable_value);
        bus_write(ch, 2'd0, width_value[DATA_BITS-1:0]);
        bus_write(ch, 2'd1, period_value[DATA_BITS-1:0]);
        bus_write(ch, 2'd2, { {(DATA_BITS-1){1'b0}}, enable_value });
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b1;
        channel_sel = '0;
        wr_en = 1'b0;
        addr = '0;
        wr_data = '0;
        errors = 0;
        checks_run = 0;
        writes_run = 0;
        reads_run = 0;
        reset_model();

        #2;
        rst_n = 1'b0;
        #1;
        expect_bit("reset pulse", |pulse_out, 1'b0);
        expect_bit("reset busy", busy, 1'b0);

        run_cycles(2, "reset hold");
        rst_n = 1'b1;

        configure_channel(2'd0, 2, 8, 1'b1);
        configure_channel(2'd1, 0, 5, 1'b1);
        configure_channel(2'd2, 4, 4, 1'b1);
        configure_channel(2'd3, 1, 3, 1'b0);

        bus_read(2'd0, 2'd0, {{(DATA_BITS-WIDTH_BITS){1'b0}}, 8'd2}, "ch0 width readback");
        bus_read(2'd0, 2'd1, {{(DATA_BITS-PERIOD_BITS){1'b0}}, 16'd8}, "ch0 period readback");
        bus_read(2'd0, 2'd2, '0, "ch0 control readback");
        bus_read(2'd1, 2'd0, '0, "ch1 width readback");
        bus_read(2'd1, 2'd1, {{(DATA_BITS-PERIOD_BITS){1'b0}}, 16'd5}, "ch1 period readback");
        bus_read(2'd1, 2'd2, '0, "ch1 control readback");
        bus_read(2'd2, 2'd0, {{(DATA_BITS-WIDTH_BITS){1'b0}}, 8'd4}, "ch2 width readback");
        bus_read(2'd2, 2'd1, {{(DATA_BITS-PERIOD_BITS){1'b0}}, 16'd4}, "ch2 period readback");
        bus_read(2'd2, 2'd2, '0, "ch2 control readback");
        bus_read(2'd3, 2'd0, {{(DATA_BITS-WIDTH_BITS){1'b0}}, 8'd1}, "ch3 width readback");
        bus_read(2'd3, 2'd1, {{(DATA_BITS-PERIOD_BITS){1'b0}}, 16'd3}, "ch3 period readback");
        bus_read(2'd3, 2'd2, '0, "ch3 control readback");

        run_cycles(16, "configured run");

        bus_write(2'd0, 2'd2, '0);
        bus_write(2'd1, 2'd2, '0);
        bus_write(2'd2, 2'd2, '0);
        bus_write(2'd3, 2'd2, '0);
        run_cycles(4, "all disabled");

        bus_write(2'd1, 2'd0, {{(DATA_BITS-WIDTH_BITS){1'b0}}, 8'd1});
        bus_write(2'd1, 2'd1, {{(DATA_BITS-PERIOD_BITS){1'b0}}, 16'd4});
        bus_write(2'd1, 2'd2, {{(DATA_BITS-1){1'b0}}, 1'b1});

        bus_read(2'd1, 2'd0, {{(DATA_BITS-WIDTH_BITS){1'b0}}, 8'd1}, "ch1 width rerun readback");
        bus_read(2'd1, 2'd1, {{(DATA_BITS-PERIOD_BITS){1'b0}}, 16'd4}, "ch1 period rerun readback");
        bus_read(2'd1, 2'd2, '0, "ch1 control rerun readback");

        run_cycles(12, "single channel busy");

        if (errors == 0) begin
            $display("PASS: %0d writes, %0d reads, %0d cycle checks completed", writes_run, reads_run, checks_run);
        end else begin
            $fatal(1, "FAIL: %0d errors after %0d writes, %0d reads, and %0d cycle checks", errors, writes_run, reads_run, checks_run);
        end

        $finish;
    end
endmodule