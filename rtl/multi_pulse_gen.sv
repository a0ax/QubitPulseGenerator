module multi_pulse_gen #(
    parameter int WIDTH_BITS   = 8,
    parameter int PERIOD_BITS  = 16,
    parameter int DATA_BITS    = (WIDTH_BITS > PERIOD_BITS) ? WIDTH_BITS : PERIOD_BITS,
    parameter int NUM_CHANNELS  = 4
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [1:0]              channel_sel,
    input  logic                    wr_en,
    input  logic [1:0]              addr,
    input  logic [DATA_BITS-1:0]    wr_data,
    output logic [DATA_BITS-1:0]    rd_data,
    output logic [NUM_CHANNELS-1:0]  pulse_out,
    output logic                    busy
);

    logic [WIDTH_BITS-1:0]  width_reg  [NUM_CHANNELS];
    logic [PERIOD_BITS-1:0] period_reg [NUM_CHANNELS];
    logic                   enable_reg [NUM_CHANNELS];
    logic [NUM_CHANNELS-1:0] busy_vec;

    genvar channel;
    generate
        for (channel = 0; channel < NUM_CHANNELS; channel++) begin : gen_channels
            pulse_gen #(
                .WIDTH_BITS(WIDTH_BITS),
                .PERIOD_BITS(PERIOD_BITS)
            ) u_pulse_gen (
                .clk(clk),
                .rst_n(rst_n),
                .enable(enable_reg[channel]),
                .width(width_reg[channel]),
                .period(period_reg[channel]),
                .pulse(pulse_out[channel]),
                .busy(busy_vec[channel])
            );
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_CHANNELS; i++) begin
                width_reg[i]  <= '0;
                period_reg[i] <= '0;
                enable_reg[i] <= 1'b0;
            end
        end else if (wr_en && (channel_sel < NUM_CHANNELS)) begin
            case (addr)
                2'd0: width_reg[channel_sel]  <= wr_data[WIDTH_BITS-1:0];
                2'd1: period_reg[channel_sel] <= wr_data[PERIOD_BITS-1:0];
                2'd2: enable_reg[channel_sel] <= wr_data[0];
                default: begin
                    // no-op
                end
            endcase
        end
    end

    always_comb begin
        rd_data = '0;
        if (channel_sel < NUM_CHANNELS) begin
            case (addr)
                2'd0: rd_data = {{(DATA_BITS-WIDTH_BITS){1'b0}}, width_reg[channel_sel]};
                2'd1: rd_data = {{(DATA_BITS-PERIOD_BITS){1'b0}}, period_reg[channel_sel]};
                2'd2: rd_data = '0;
                default: rd_data = '0;
            endcase
        end
    end

    assign busy = |busy_vec;

endmodule