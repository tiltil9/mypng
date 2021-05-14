#------------------------------------------------------------------------------
#                            0   Setup
#------------------------------------------------------------------------------
# 0.1   logic Library settings
set search_path         "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/ref/models"  
# set target_library      "saed90nm_max.db"
# set link_library        "saed90nm_max.db" 
# set target_library      "saed90nm_min.db"
# set link_library        "saed90nm_min.db" 
set target_library      "saed90nm_typ.db SRAM32x512_1rw_typ.db"
set link_library        "saed90nm_typ.db SRAM32x512_1rw_typ.db" 
# set target_library      "saed90nm_max.db  saed90nm_min.db  saed90nm_typ.db"
# set link_library        "saed90nm_max.db  saed90nm_min.db  saed90nm_typ.db" 
# set symbol_library      "smic13g.sdb"

# 0.2   outputfile path
set log_path            "../log"
set report_path         "../report"
set export_path         "../netlist"

# 0.3   RTL design
#  ***   UPDATE   *************************************************************************
#  ****************************************************************************************
set verilog_file       "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/common/defines.vh        \
                        /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/common/ram.v             \
                        /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/common/fifo.v            \
                        /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/filter/filter.v          \
                        /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/filter/filter_paeth.v    \
                        /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/filter/filter_top.v      \
                        "
# set verilog_file       "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/adler32/adler32.v        \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/bs/bs_output.v           \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/bs/bs_top.v              \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/bs/huffman_fixed.v       \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/common/defines.vh        \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/common/fifo.v            \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/common/ram.v             \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/crc32/crc32_core.v       \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/crc32/crc32_top.v        \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/filter/filter.v          \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/filter/filter_paeth.v    \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/filter/filter_top.v      \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/lz77/lz77_detect_one.v   \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/lz77/lz77_top.v          \
#                         /net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl/png_top.v"
set top_design          "filter_top"
#  ****************************************************************************************

# 0.3   enable logging
set timestamp [clock format [clock scan now] -format "%Y-%m-%d_%H-%M"]
set sh_output_log_file  "$log_path/log.[pid].$timestamp"
set sh_command_log_file "$log_path/cmd.[pid].$timestamp"

# 0.4   name rules
define_name_rules BORG -allowed {A-Za-z0-9_} -first_restricted "_" -last_restricted "_" -max_length 30

# 0.5   no tri-state gate
set verilogout_no_tri true

# 0.6   show unconnected pins 
set verilogout_show_unconnected_pins  true

# 0.7   scan chain
set test_default_scan_style  multiplexed_flip_flop


#------------------------------------------------------------------------------
#                            1  Translate
#------------------------------------------------------------------------------
# remove_design $top_design
analyze -format verilog $verilog_file
elaborate $top_design

current_design $top_design
link  
uniquify
check_design


#------------------------------------------------------------------------------
#                            2  Constraint
#------------------------------------------------------------------------------
# 2.1   clock and rst
set clk_name "clk"
set rst_name "rstn"
#  ***   UPDATE   *************************************************************************
#  ****************************************************************************************
create_clock -name $clk_name -period 8 -waveform {0 4} [get_ports $clk_name]
#  ****************************************************************************************
set_dont_touch_network [get_clocks $clk_name]
set_clock_latency 0.1 [get_clocks $clk_name]
set_clock_uncertainty 0.1 [get_clocks $clk_name]
set_input_delay -max 0.1 -clock $clk_name [remove_from_collection [all_inputs] [get_ports "$clk_name $rst_name"]]
set_input_delay -min -0.1 -clock $clk_name [remove_from_collection [all_inputs] [get_ports "$clk_name $rst_name"]]
set_output_delay -max 0.1 -clock $clk_name [all_outputs]
set_output_delay -min -0.1 -clock $clk_name [all_outputs]
set_fix_hold [get_clocks $clk_name]

set_ideal_network [get_ports "$rst_name"]
set_false_path -from [get_ports "$rst_name"]
set_dont_touch_network [get_ports "$rst_name"]

# 2.3   environment
# set_operating_conditions WCCOM
# set_wire_load_mode top
set_drive 0  $clk_name
set_drive 0  $rst_name
set_load  0.5 [all_outputs]

# 2.4   rule
set_max_fanout 1000 $top_design
set_max_transition 0.2 $top_design
# set_max_capacitance 0.2 $top_design
# report_constraint -max_capacitance -significant_digits 13
# report_constraint -max_transition  -significant_digits 13
# report_constraint -max_fanout      -significant_digits 13

# 2.5   area_opt
set_max_area 0


#------------------------------------------------------------------------------
#                            3  map
#------------------------------------------------------------------------------
# compile_ultra
compile


#------------------------------------------------------------------------------
#                            4  report
#------------------------------------------------------------------------------
report_constraint             > "$report_path/constraint.rpt"
report_constraint -all        > "$report_path/constraint_violator.rpt"
report_timing                 > "$report_path/timing.rpt"
report_timing -nworst 1000    > "$report_path/timing_1000.rpt"
report_area                   > "$report_path/area.rpt"
report_power                  > "$report_path/power.rpt"


#------------------------------------------------------------------------------
#                            5  export
#------------------------------------------------------------------------------
write -hierarchy -format verilog -output "$export_path/$top_design.dc.v"
write_sdc "$export_path/$top_design.dc.sdc"
write_sdf "$export_path/$top_design.dc.sdf"

quit
