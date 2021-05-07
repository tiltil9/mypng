quit -sim
.main clear

vlib ./lib
vlib ./lib/work
vmap work ./lib/work

vlog 	../../../src/common/*   \
			../../../src/adler32/*  \
			../../../src/bs/*       \
			../../../src/crc32/*    \
			../../../src/filter/*   \
      ../../../src/lz77/*     \
			../../../sim/sim_png/sim_png_top.v \
			../../../src/png_top.v
			
vsim -voptargs=+acc work.sim_png_top

add wave * 
add wave sim:/sim_png_top/dut/*
add wave sim:/sim_png_top/dut/lz77_top/*
add wave sim:/sim_png_top/dut/fifo_flt/*

run 1000000000ns