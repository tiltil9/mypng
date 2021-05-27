quit -sim
.main clear

vlib ./lib2
vlib ./lib2/work2
vmap work ./lib2/work2

vlog 	../../../netlist/saed90nm.v             \
			../../../netlist/SRAM32x512_1rw.v       \
			../../../netlist/filter/filter_top.dc.v \
			../../../src/common/defines.vh          \
			../sim_filter_top.v
			
vsim -voptargs=+acc work.sim_filter_top

run 10000000ns
