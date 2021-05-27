# dc

#===================== set variables ======================
set top             "filter_top"
set design_path     "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/dc_submodule/dc_filter/netlist"
set search_path     "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/ref/models"


#===================== set library ========================
set target_library "saed90nm_typ.db SRAM32x512_1rw_typ.db"
set link_library   "* $target_library"                    ; # * is a must, or submodule will not be found 


#==================== read netlist and sdc ================
read_verilog  $design_path/${top}.dc.v
current_design $top
link

source $design_path/${top}.dc.sdc


#==================== report ==============================
report_timing > primetime.dc.log
check_timing -verbose > primetime.violations.dc.log

quit