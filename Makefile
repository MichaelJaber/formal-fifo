.PHONY: sim prove cover formal clean

sim:
	mkdir -p build
	iverilog -g2012 -s fifo_tb -o build/fifo_tb rtl/fifo.sv sim/fifo_tb.sv
	vvp build/fifo_tb

prove:
	cd formal && sby -f fifo.sby prove

cover:
	cd formal && sby -f fifo.sby cover

formal:
	cd formal && sby -f fifo.sby

clean:
	rm -rf build/fifo_tb formal/fifo_prove formal/fifo_cover