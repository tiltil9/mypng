quit -sim
.main clear

vlib ./lib
vlib ./lib/work
vmap work ./lib/work

vlog 	../../../src/common/defines.vh         \
			../../../src/common/fifo.v             \
		  ../../../src/common/ram.v              \
			../../../src/filter/filter_paeth.v     \
			../../../src/filter/filter.v           \
			../../../src/filter/filter_top.v       \
			../sim_filter_top.v   								
			
vsim -voptargs=+acc work.sim_filter_top

add wave * 
add wave sim:/sim_filter_top/dut/filter/*
add wave sim:/sim_filter_top/dut/fifo_0/*
add wave sim:/sim_filter_top/dut/fifo_1/*

run 10000000ns
