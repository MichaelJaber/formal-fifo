# Formally Verified Parameterized FIFO

A synchronous FIFO implemented in SystemVerilog and verified using simulation and formal methods.

The design supports configurable data width and depth, circular read and write pointers, simultaneous push and pop requests, and explicit handling of full and empty boundary conditions.

## Interface

| Signal | Direction | Description |
|---|---|---|
| `clk` | Input | Rising-edge clock |
| `reset` | Input | Synchronous active-high reset |
| `push` | Input | Requests insertion of `data_in` |
| `pop` | Input | Requests removal of the oldest item |
| `data_in` | Input | Value presented for insertion |
| `data_out` | Output | Oldest value currently in the FIFO |
| `full` | Output | Asserted when the FIFO contains `DEPTH` items |
| `empty` | Output | Asserted when the FIFO contains no items |

A push is accepted when `push && !full`. A pop is accepted when `pop && !empty`.

When push and pop are simultaneously requested:

- In an ordinary nonempty, nonfull state, both operations are accepted.
- When empty, only the push is accepted.
- When full, only the pop is accepted.

## Implementation

The FIFO uses:

- A memory array containing `DEPTH` words
- A read pointer identifying the oldest item
- A write pointer identifying the next insertion location
- A count ranging from zero through `DEPTH`
- Explicit pointer wraparound supporting non-power-of-two depths

The formal configuration uses `DEPTH = 3` to exercise pointer wraparound where one encoding of the two-bit pointers is invalid.

## Simulation

The self-checking testbench covers:

- Reset behavior
- Ordinary pushes and pops
- FIFO ordering
- Full and empty flags
- Pointer wraparound
- Rejected pushes while full
- Rejected pops while empty
- Simultaneous push and pop
- Simultaneous requests at full and empty boundaries

Run the simulation with:

```bash
make sim
```

## Formal verification

The project uses Yosys, SymbiYosys, and Boolector.

The proved properties include:

- `count <= DEPTH`
- Read and write pointers always remain in range
- `empty` is equivalent to `count == 0`
- `full` is equivalent to `count == DEPTH`
- Reset clears the count and both pointers
- Accepted pushes and pops update the count correctly
- Read and write pointers advance exactly when their corresponding operations are accepted
- The write pointer remains `count` circular positions ahead of the read pointer
- FIFO contents preserve insertion order

### Ordering proof

The ordering proof selects an arbitrary accepted push and records its value and zero-based position in the queue.

Each accepted pop ahead of the selected item decreases its tracked position. When the position reaches zero, the proof asserts that `data_out` equals the tracked value.

An inductive invariant connects the abstract tracked position to the physical memory location:

```text
memory[(read_ptr + tracked_position) mod DEPTH] = tracked_data
```

This establishes that an arbitrary selected item cannot be lost or overtaken by later pushes.

Run the proofs with:

```bash
make prove
```

## Cover witnesses

Cover properties generate concrete traces showing that important scenarios are reachable, including:

- The FIFO becoming full
- Circular pointer wraparound
- Simultaneous push and pop
- A selected item entering behind another item, reaching the front, and being popped with the correct output value

Generate cover traces with:

```bash
make cover
```

Run both proof and cover tasks with:

```bash
make formal
```

## Project structure

```text
formal-fifo/
├── rtl/
│   └── fifo.sv
├── sim/
│   └── fifo_tb.sv
├── formal/
│   ├── fifo_formal.sv
│   └── fifo.sby
├── Makefile
├── README.md
└── .gitignore
```

## Requirements

- Icarus Verilog
- Yosys
- SymbiYosys
- Boolector
- GTKWave (optional, for viewing generated traces)
