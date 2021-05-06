quit -sim
.main clear

vlib ./lib
vlib ./lib/work
vmap work ./lib/work

vlog 	../../../src/common/defines.vh       \
			../../../src/Lz77/lz77_top.v         \
			../../../src/Lz77/lz77_detect_one.v  \
			../sim_lz77_top.v

vsim -voptargs=+acc work.sim_lz77_top

add wave * 
add wave sim:/sim_lz77_top/dut/*
add wave sim:/sim_lz77_top/FILTER_DATA_O/*

run 1000000000ns