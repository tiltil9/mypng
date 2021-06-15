# dc

#===================== set variables ======================
set top             "png_top"
set design_path     "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/icc/png2/netlist"
set search_path     "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/ref/db"


#===================== set library ========================
set target_library "saed90nm_typ.db SRAM32x512_1rw_typ.db"
set link_library   "* $target_library"                    ; # * is a must, or submodule will not be found 


#==================== read netlist and sdc ================
read_verilog  $design_path/${top}.icc.v
current_design $top
link

read_parasitics -verbose -keep_capacitive_coupling -format SPEF $design_path/${top}.spef

source $design_path/${top}.icc.sdc


#==================== report ==============================
report_timing > primetime.icc.log
check_timing -verbose > primetime.violations.icc.log

# quit