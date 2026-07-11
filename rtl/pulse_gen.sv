module pulse_gen #(
    parameter int WIDTH_BITS  = 8,
    parameter int PERIOD_BITS = 16
) (
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   enable,
    input  logic [WIDTH_BITS-1:0]  width,
    input  logic [PERIOD_BITS-1:0] period,
    output logic                   pulse,
    output logic                   busy
);

    logic [PERIOD_BITS-1:0] count;
    logic [PERIOD_BITS-1:0] width_eff;

    always_comb begin
        if (width >= period)
            width_eff = period;
        else
            width_eff = {{(PERIOD_BITS-WIDTH_BITS){1'b0}}, width};
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= '0;
            pulse <= 1'b0;
            busy  <= 1'b0;
        end else if (!enable || (period == '0) || (width == '0)) begin
            count <= '0;
            pulse <= 1'b0;
            busy  <= 1'b0;
        end else begin
            busy <= 1'b1;

            if (count == (period - 1'b1))
                count <= '0;
            else
                count <= count + 1'b1;

            pulse <= (count < width_eff);
        end
    end

endmodule
