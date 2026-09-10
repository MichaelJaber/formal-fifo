module fifo_tb;

    localparam DATA_WIDTH = 8;
    localparam DEPTH = 4;

    logic                  clk = 0;
    logic                  reset;
    logic                  push;
    logic                  pop;
    logic [DATA_WIDTH-1:0] data_in;
    
    logic [DATA_WIDTH-1:0] data_out;
    logic                  full;
    logic                  empty;

    fifo #(
        .DATA_WIDTH(DATA_WIDTH), 
        .DEPTH(DEPTH)
    ) dut(
        .clk(clk), 
        .reset(reset), 
        .push(push), 
        .pop(pop), 
        .data_in(data_in), 
        .data_out(data_out), 
        .full(full), 
        .empty(empty)
    );

    always #5 clk = ~clk;

    initial begin
        reset = 1;
        push = 0;
        pop = 0;
        data_in = 0;

        @(negedge clk);
        reset = 0;
        data_in = 8'hA1;
        push = 1;

        @(negedge clk);
        push = 0;

        $display("data_out=%h empty=%b full=%b",
                data_out, empty, full);
        
        @(negedge clk);
        data_in = 8'hB2;
        push = 1;

        @(negedge clk);
        data_in = 8'hC3;
        push = 1;

        @(negedge clk);
        push = 0;

        if (data_out == 8'hA1)
            $display("SUCCESS: data_out is A1");
        else
            $fatal(1, "FAILURE: expected A1, got %h", data_out);


        @(negedge clk);
        pop = 1;

        @(negedge clk);
        pop = 0;
        if (data_out === 8'hB2)
            $display("SUCCESS: data_out is B2");
        else
            $fatal(1, "FAILURE: expected B2, got %h", data_out);

        @(negedge clk);
        data_in = 8'hD4;
        push = 1;

        @(negedge clk);
        push = 0;

        @(negedge clk);
        data_in = 8'hE5;
        push = 1;

        @(negedge clk);
        push = 0;

        if (data_out == 8'hB2 && full == 1 && empty == 0)
            $display("SUCCESS: data_out is B2, full = 1, and empty = 0");
        else
            $fatal(1, "FAILURE: expected B2, full = 1, and empty = 0, got %h, full = %b, empty = %b", 
            data_out, full, empty);

        @(negedge clk);
        pop = 1;

        @(negedge clk);
        pop = 0;

        if (data_out == 8'hC3 && full == 0 && empty == 0)
            $display("SUCCESS: data_out is C3, full = 0, and empty = 0");
        else
            $fatal(1, "FAILURE: expected C3, full = 0, and empty = 0, got %h, full = %b, empty = %b", 
            data_out, full, empty);

        @(negedge clk);
        pop = 1;

        @(negedge clk); 
        pop = 0;

        if (data_out == 8'hD4 && full == 0 && empty == 0)
            $display("SUCCESS: data_out is D4, full = 0, and empty = 0");
        else
            $fatal(1, "FAILURE: expected D4, full = 0, and empty = 0, got %h, full = %b, empty = %b", 
            data_out, full, empty);

        @(negedge clk);
        pop = 1;

        @(negedge clk);
        pop = 0;

        if (data_out == 8'hE5 && full == 0 && empty == 0)
            $display("SUCCESS: data_out is E5, full = 0, and empty = 0");
        else
            $fatal(1, "FAILURE: expected E5, full = 0, and empty = 0, got %h, full = %b, empty = %b", 
            data_out, full, empty);

            @(negedge clk);
        pop = 1;

        @(negedge clk);
        pop = 0;

        // illegal pop
        @(negedge clk);
        pop = 1;

        @(negedge clk);
        pop = 0;

        if (full == 0 && empty == 1)
            $display("SUCCESS: full = 0, and empty = 1");
        else
            $fatal(1, "FAILURE: expected full = 0 and empty = 1, got full = %b, empty = %b", 
            full, empty);

        @(negedge clk);
            push = 1;
            data_in = 8'h11;

        @(negedge clk);
            push = 0;

        @(negedge clk);
            push = 1;
            data_in = 8'h22;

        @(negedge clk);
            push = 0;
        
        if (data_out == 8'h11 && dut.count == 2)
            $display("SUCCESS: data_out = 11, and count = 2");
        else
            $fatal(1, "FAILURE, expected data_out = 11 and count = 2, got data_out = %h, count = %h", 
            data_out, dut.count);

        @(negedge clk);
            push = 1;
            pop = 1;
            data_in = 8'h33;

        @(negedge clk);
            push = 0;
            pop = 0;
            if (data_out == 8'h22 && dut.count == 2 && empty == 0 && full == 0)
                $display("SUCCESS: data_out = 22, count = 2, empty = 0, full = 0");
            else
                $fatal(1, "FAILURE: expected data_out = 22, count = 2, empty = 0, full = 0, ",
                "got data_out = %h, count = %d, empty = %b, full = %b", 
                data_out, dut.count, empty, full);

                        // Reset so the boundary tests are independent.
        @(negedge clk);
        reset = 1;
        push = 0;
        pop = 0;

        @(negedge clk);
        reset = 0;

        if (empty == 1 && full == 0 && dut.count == 0)
            $display("SUCCESS: reset produced an empty FIFO");
        else
            $fatal(
                1,
                "FAILURE after reset: count=%0d empty=%b full=%b",
                dut.count, empty, full
            );

        // Simultaneous push and pop while empty.
        push = 1;
        pop = 1;
        data_in = 8'h44;

        @(negedge clk);
        push = 0;
        pop = 0;

        if (data_out == 8'h44 &&
            dut.count == 1 &&
            empty == 0 &&
            full == 0)
            $display(
                "SUCCESS: simultaneous push/pop while empty accepted only the push"
            );
        else
            $fatal(
                1,
                "FAILURE at empty boundary: data_out=%h count=%0d empty=%b full=%b",
                data_out, dut.count, empty, full
            );

        // Remove 44 so that the FIFO is empty again.
        pop = 1;

        @(negedge clk);
        pop = 0;

        if (dut.count == 0 && empty == 1)
            $display("SUCCESS: FIFO is empty before full-boundary test");
        else
            $fatal(
                1,
                "FAILURE: expected empty FIFO, count=%0d empty=%b",
                dut.count, empty
            );

        // Fill the FIFO with 51, 52, 53, 54.
        push = 1;
        data_in = 8'h51;

        @(negedge clk);
        data_in = 8'h52;

        @(negedge clk);
        data_in = 8'h53;

        @(negedge clk);
        data_in = 8'h54;

        @(negedge clk);
        push = 0;

        if (data_out == 8'h51 &&
            dut.count == DEPTH &&
            full == 1 &&
            empty == 0)
            $display("SUCCESS: FIFO filled for full-boundary test");
        else
            $fatal(
                1,
                "FAILURE filling FIFO: data_out=%h count=%0d empty=%b full=%b",
                data_out, dut.count, empty, full
            );

        // Simultaneous push and pop while full.
        // Under the current policy, pop succeeds and push is rejected.
        push = 1;
        pop = 1;
        data_in = 8'h55;

        @(negedge clk);
        push = 0;
        pop = 0;

        if (data_out == 8'h52 &&
            dut.count == DEPTH-1 &&
            full == 0 &&
            empty == 0)
            $display(
                "SUCCESS: simultaneous push/pop while full accepted only the pop"
            );
        else
            $fatal(
                1,
                "FAILURE at full boundary: data_out=%h count=%0d empty=%b full=%b",
                data_out, dut.count, empty, full
            );

        // Check that the remaining values are still 52, 53, 54.
        pop = 1;

        @(negedge clk);
        pop = 0;

        if (data_out != 8'h53)
            $fatal(1, "FAILURE: expected 53, got %h", data_out);

        @(negedge clk);
        pop = 1;

        @(negedge clk);
        pop = 0;

        if (data_out != 8'h54)
            $fatal(1, "FAILURE: expected 54, got %h", data_out);

        @(negedge clk);
        pop = 1;

        @(negedge clk);
        pop = 0;

        if (empty == 1 && dut.count == 0)
            $display(
                "SUCCESS: full-boundary operation preserved FIFO contents"
            );
        else
            $fatal(
                1,
                "FAILURE: expected empty FIFO, count=%0d empty=%b",
                dut.count, empty
            );

        $finish;
    end

endmodule