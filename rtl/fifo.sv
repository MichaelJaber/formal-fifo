module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 4
) (
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  push,
    input  logic                  pop,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic                  full,
    output logic                  empty
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    // The storage containing the queued values.
    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    // Locations of the next read and write.
    logic [PTR_WIDTH-1:0] read_ptr;
    logic [PTR_WIDTH-1:0] write_ptr;

    // DEPTH+1 possible values: 0 through DEPTH.
    logic [$clog2(DEPTH+1)-1:0] count;

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    // The oldest element is visible at the output.
    assign data_out = memory[read_ptr];

    always_ff @(posedge clk) begin
    if (reset) begin
        read_ptr <= 0;
        write_ptr <= 0;
        count <= 0;
    end
    else begin
        if (push && !full) begin
            memory[write_ptr] <= data_in;
            write_ptr <= (write_ptr == DEPTH-1) ? 0 : write_ptr+1;

        end
        if (pop && !empty) begin
            read_ptr <= (read_ptr == DEPTH-1) ? 0 : read_ptr+1;
        end
        case ({push && !full, pop && !empty})
            2'b10: count <= count + 1;
            2'b01: count <= count - 1;
            default: ;
        endcase
    end
end

`ifdef FORMAL
    logic formal_past_valid;

    (* anyseq *) logic select_this_push;

    logic tracking;
    logic [DATA_WIDTH-1:0] tracked_data;
    logic [$clog2(DEPTH+1)-1:0] tracked_position; 
    
    logic tracked_item_started_behind;

    logic [PTR_WIDTH:0] formal_write_sum;
    logic [PTR_WIDTH:0] formal_tracked_sum;

    logic [PTR_WIDTH-1:0] formal_write_index;
    logic [PTR_WIDTH-1:0] formal_tracked_index;

    logic formal_fifo_shape;
    logic formal_pointer_relation;
    logic formal_tracker_valid;
    logic formal_invariant;

    assign formal_write_sum =
        {1'b0, read_ptr} + count;

    assign formal_tracked_sum =
        {1'b0, read_ptr} + tracked_position;

    assign formal_write_index =
        (formal_write_sum >= DEPTH)
            ? formal_write_sum - DEPTH
            : formal_write_sum;

    assign formal_tracked_index =
        (formal_tracked_sum >= DEPTH)
            ? formal_tracked_sum - DEPTH
            : formal_tracked_sum;

    assign formal_fifo_shape =
        (count <= DEPTH) &&
        (read_ptr < DEPTH) &&
        (write_ptr < DEPTH) &&
        (empty == (count == 0)) &&
        (full  == (count == DEPTH));

    assign formal_pointer_relation =
        (write_ptr == formal_write_index);

    assign formal_tracker_valid =
        !tracking ||
        (
            (tracked_position < count) &&
            (memory[formal_tracked_index] == tracked_data)
        );

    assign formal_invariant =
        formal_fifo_shape &&
        formal_pointer_relation &&
        formal_tracker_valid;
    
    initial formal_past_valid = 0; 

    always_ff @(posedge clk) begin
        if(formal_past_valid)
            assert(formal_invariant);

        if (reset) begin
            tracking <= 0;
            tracked_data <= '0;
            tracked_position <= '0;
            tracked_item_started_behind <= 1'b0;
        end
        else if (!tracking) begin
            if (select_this_push && push && !full) begin
                tracking <= 1;
                tracked_data <= data_in;

                if (pop && !empty) begin
                    tracked_position <= count - 1;
                    tracked_item_started_behind <= (count > 1); // if simultaneous push/pop, need to have
                                                                // at least two items in the FIFO
                end 
                else
                    tracked_position <= count;
                    tracked_item_started_behind <= (count > 0); // if only a push, just need one other item
                                                                // in the FIFO
            end
        end
        else if (pop && !empty) begin
            if (tracked_position == 0) begin
                assert(data_out == tracked_data);
                
                cover(
                    data_out == tracked_data &&
                    tracked_item_started_behind
                );
                
                tracking <= 0;
                tracked_item_started_behind <= 0;
            end
            else begin
                tracked_position <= tracked_position - 1;
            end
        end
    end

    always_ff @(posedge clk) begin
        formal_past_valid <= 1;

        if (formal_past_valid && $past(reset)) begin
            assert(count == 0);
            assert(read_ptr == 0);
            assert(write_ptr == 0);
            assert(empty);
            assert(!full);
        end
        
        if (formal_past_valid && !$past(reset)) begin
            case ({
                $past(push && !full),
                $past(pop && !empty)
            })
                2'b10:
                    assert(count == $past(count) + 1);

                2'b01:
                    assert(count == $past(count) - 1);

                default:
                    assert(count == $past(count));
            endcase

            if ($past(push && !full))
                assert(
                    write_ptr ==
                    (($past(write_ptr) == DEPTH-1) ?
                        0 : $past(write_ptr) + 1)
                );
            else
                assert(write_ptr == $past(write_ptr));

            if ($past(pop && !empty))
                assert(
                    read_ptr ==
                    (($past(read_ptr) == DEPTH-1) ?
                        0 : $past(read_ptr) + 1)
                );
            else
                assert(read_ptr == $past(read_ptr));

            cover(
                formal_past_valid && 
                !$past(reset) &&
                $past(write_ptr == DEPTH - 1) &&
                write_ptr == 0
            );
        end
    end
`endif

endmodule