module pulse_gen_assert #(
    parameter int WIDTH_BITS  = 8,
    parameter int PERIOD_BITS = 16
) (
    input logic                   clk,
    input logic                   rst_n,
    input logic                   enable,
    input logic [WIDTH_BITS-1:0]  width,
    input logic [PERIOD_BITS-1:0] period,
    input logic                   pulse,
    input logic                   busy
);

    logic [PERIOD_BITS-1:0] width_eff;
    logic pulse_prev;
    logic seen_high;
    int unsigned high_run;
    int unsigned low_run;

    always_comb begin
        if (width >= period)
            width_eff = period;
        else
            width_eff = {{(PERIOD_BITS-WIDTH_BITS){1'b0}}, width};
    end

`ifdef FORMAL
    assume_valid_period: assume property (@(posedge clk) disable iff (!rst_n) period > 0);
    assume_valid_width: assume property (@(posedge clk) disable iff (!rst_n) width >= '0);
`endif

    assert_disabled_low: assert property (@(posedge clk) disable iff (!rst_n) !enable |-> (!pulse && !busy));
    assert_zero_inputs_low: assert property (@(posedge clk) disable iff (!rst_n) ((width == '0) || (period == '0)) |-> !pulse);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_prev <= 1'b0;
            seen_high <= 1'b0;
            high_run <= 0;
            low_run <= 0;
        end else if (!enable) begin
            assert (pulse == 1'b0);
            assert (busy == 1'b0);
            pulse_prev <= pulse;
            seen_high <= 1'b0;
            high_run <= 0;
            low_run <= 0;
        end else if ((width == '0) || (period == '0)) begin
            assert (pulse == 1'b0);
            pulse_prev <= pulse;
            seen_high <= 1'b0;
            high_run <= 0;
            low_run <= 0;
        end else begin
            assert (busy == 1'b1);

            if (pulse) begin
                if (pulse_prev == 1'b0 && seen_high)
                    assert (low_run >= (period - width_eff));

                assert ((high_run + 1) <= width_eff);
                high_run <= high_run + 1;
                low_run <= 0;
                seen_high <= 1'b1;
            end else begin
                high_run <= 0;
                low_run <= low_run + 1;
            end

            pulse_prev <= pulse;
        end
    end

endmodule