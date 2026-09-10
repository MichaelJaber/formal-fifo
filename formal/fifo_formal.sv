module fifo_formal;

    localparam DATA_WIDTH = 8;
    localparam DEPTH = 3;

    (* gclk *) logic clk;

    (* anyseq *) logic reset;
    (* anyseq *) logic push;
    (* anyseq *) logic pop;
    (* anyseq *) logic [DATA_WIDTH-1:0] data_in;

    logic [DATA_WIDTH-1:0] data_out;
    logic full;
    logic empty;

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .push(push),
        .pop(pop),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

        logic past_valid;

    initial past_valid = 0;

    always_ff @(posedge clk) begin
        past_valid <= 1;

        // Require reset on the first clock edge.
        if (!past_valid)
            assume(reset);
    end

    always_ff @(posedge clk) begin
        if (past_valid && !reset)
            cover(full & !$past(full));     // FIFO becomes full
            cover(push && pop);             // Simultaneous request
    end

endmodule