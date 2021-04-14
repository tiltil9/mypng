quit -sim
.main clear

vlib ./lib
vlib ./lib/work
vmap work ./lib/work

vlog 	../../src/common/defines.vh \
			../../src/common/fifo.v     \
		  ../../src/common/ram.v

/* vsim -voptargs=+acc work.cputop
add wave * 
run 16000ns */
