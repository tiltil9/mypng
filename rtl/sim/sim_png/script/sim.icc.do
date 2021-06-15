quit -sim
.main clear

vlib ./lib3
vlib ./lib3/work3
vmap work ./lib3/work3

vlog 	../../../netlist/saed90nm.v             \
			../../../netlist/SRAM32x512_1rw.v       \
			../../../netlist/png/png_top.dc.v       \
			../../../src/common/defines.vh          \
			../../../sim/sim_png/sim_png_top.v
			
vsim -voptargs=+acc work.sim_png_top

run 1000000000ns