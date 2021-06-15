#-----------------------------------------------------------
#                         Log
#-----------------------------------------------------------
define_name_rules BORG -allowed {A-Za-z0-9_} -first_restricted "_" -last_restricted "_" -max_length 30
set timestamp [clock format [clock scan now] -format "%Y-%m-%d_%H-%M"]
set log_path            "../log"
set sh_output_log_file "$log_path/log.[pid].$timestamp"
set sh_command_log_file "$log_path/cmd.[pid].$timestamp"

#-----------------------------------------------------------
#                          Variables
#-----------------------------------------------------------
#   library
set lib_name            "saed90nm_typ"
set target_library      "saed90nm_typ.db       \
                         SRAM32x512_1rw_typ.db"
set link_library        "* $target_library"
set lib_path            "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/ref/db"
set script_path         "../script"
set search_path         "$lib_path $script_path"

set file_path           "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/ref/"
set tech_file           "$file_path/tf/saed90nm_icc_1p9m.tf"
set mw_path             "$file_path/mw_std          \
                         $file_path/mw_sram_32x512  \
                         $file_path/mw_io"
set tlup_map            "$file_path/tlup/tech2itf.map"
set tlup_max            "$file_path/tlup/saed90nm_1p9m_1t_Cmax.tluplus"
set tlup_min            "$file_path/tlup/saed90nm_1p9m_1t_Cmin.tluplus"

# using max to fix setup time, min to fix hold time
set_min_library saed90nm_max.db       -min_ver saed90nm_min.db
set_min_library SRAM32x512_1rw_max.db -min_ver SRAM32x512_1rw_min.db
set_min_library saed90nm_io_max.db    -min_ver saed90nm_io_min.db

#   design
set top_name            "png_top"
set rtl_path            "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl"
set dc_netlist_path     "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/dc_high/netlist"
set verilog_file        "$dc_netlist_path/png_top.dc.v"
set sdc_file            "$dc_netlist_path/png_top.dc.sdc"

set netlist_path        "../netlist"
set report_path         "../report"
set gds_path            "../gds"

# speed up
set_host_options  -max_core       16


#-----------------------------------------------------------
#                          Steps
#-----------------------------------------------------------
# 1  setup
# 2  floorplan
# 3  place
# 4  clock tree synthesis
# 5  route
# 6  check
# 7  export


#-----------------------------------------------------------
#                            1  setup
#-----------------------------------------------------------
gui_start

create_mw_lib   -technology           $tech_file    \
                -mw_reference_library $mw_path      \
                -bus_naming_style     {[%d]}        \
                -open                 $top_name

read_verilog $verilog_file \
            -dirty_netlist \
            -top $top_name \
            -cel $top_name
current_design $top_name
uniquify_fp_mw_cel
link

read_sdc $sdc_file

set_tlu_plus_files  -max_tluplus  $tlup_max \
                    -min_tluplus  $tlup_min \
                    -tech2itf_map $tlup_map

# if {[check_error -verbose] != 0} { exit 1 }
check_error -verbose
save_mw_cel     -as $top_name\_1_setup
report_timing   >   $report_path/timing_1_setup.rpt


#-----------------------------------------------------------
#                            2  floorplan
#-----------------------------------------------------------

# pad
source ../script/pin.tcl

create_floorplan -control_type      width_and_height \
                 -core_width        1300             \
                 -core_height       1300             \
                 -core_utilization  0.7              \
                 -left_io2core      10               \
                 -top_io2core       10               \
                 -right_io2core     10               \
                 -bottom_io2core    10               \
                 -start_first_row

# macro
set_fp_placement_strategy -macros_on_edge on              \
                          -min_distance_between_macros 20 \
                          -auto_grouping high
# set_fp_rail_constraints
# todo : no power ring on macro 

# standard cell
create_fp_placement
source ../script/connect_pg.tcl

# power ring
create_rectangular_rings 	-nets  {VDD VSS}		\
                          -left_offset   0.5 -left_segment_layer   M8 -left_segment_width   1.5 \
                          -right_offset  0.5 -right_segment_layer  M8 -right_segment_width  1.5 \
                          -bottom_offset 0.5 -bottom_segment_layer M9 -bottom_segment_width 1.5 \
                          -top_offset    0.5 -top_segment_layer    M9 -top_segment_width    1.5

# power ring around ram
create_rectangular_rings  -nets   {VDD VSS}                        \
                          -around specified                        \
                          -cells  {fifo_flt/ram_90nm               \
                                   filter_top/fifo_1/ram_90nm      \
                                   filter_top/fifo_0/ram_90nm }    \
                          -left_offset   0.5 -left_segment_layer   M6 -left_segment_width   1.5 \
                          -right_offset  0.5 -right_segment_layer  M6 -right_segment_width  1.5 \
                          -bottom_offset 0.5 -bottom_segment_layer M7 -bottom_segment_width 1.5 \
                          -top_offset    0.5 -top_segment_layer    M7 -top_segment_width    1.5

# power strapes
create_power_straps -direction  horizontal      \
                    -do_not_route_over_macros   \
                    -nets       {VSS VDD}       \
                    -layer      M5              \
                    -width      2               \
                    -configure  step_and_stop   \
                    -start_at   30              \
                    -step       60              \
                    -stop       1300
create_power_straps -direction  vertical        \
                    -nets       {VDD VSS }      \
                    -layer      M4              \
                    -width      2               \
                    -configure  step_and_stop   \
                    -start_at   30              \
                    -step       60              \
                    -stop       1300


source ../script/connect_pg.tcl

# connect to power and ground rings and straps
preroute_standard_cells -nets {VDD VSS}                 \
                        -port_filter_mode          off  \
                        -cell_master_filter_mode   off  \
                        -cell_instance_filter_mode off  \
                        -voltage_area_filter_mode  off
preroute_instances -ignore_pads        \
                   -ignore_cover_cells \
                   -select_net_by_type \
                    specified -nets {VDD VSS}

verify_pg_nets

# no cell under power ring in M1-M2
set_pnet_options -complete {M1 M2}
set_pnet_options -partial  {M3 M4 M5 M6 M7 M8 M9}

create_fp_placement -incremental all

route_fp_proto
source ../script/connect_pg.tcl

set_dont_touch_placement {fifo_flt/ram_90nm          \
                          filter_top/fifo_1/ram_90nm \
                          filter_top/fifo_0/ram_90nm }

check_error -verbose
# if {[check_error -verbose] != 0} { exit 2 }
save_mw_cel     -as $top_name\_2_floorplan
report_timing   >   $report_path/timing_2_floorplan.rpt


#-----------------------------------------------------------
#                            3  place
#-----------------------------------------------------------

# set_keepout_margin 20
set_app_var physopt_hard_keepout_distance 20
set placer_soft_keepout_channel_width 25

check_physical_design -stage pre_place_opt
check_physical_constraints

remove_ideal_net [get_nets rstn]

place_opt
source ../script/connect_pg.tcl

check_error -verbose
# if {[check_error -verbose] != 0} { exit 3 }
save_mw_cel     -as $top_name\_3_place
report_timing   >   $report_path/timing_3_place.rpt


#-----------------------------------------------------------
#                            4  cts
#-----------------------------------------------------------
remove_ideal_net [get_ports clk]
check_physical_design -stage pre_clock_opt

set_clock_tree_options -target_skew    0.1 \
                       -max_transition 0.5 \
                       -layer_list {METAL3 METAL4 METAL5 METAL6 METAL7 METAL8 METAL9}

clock_opt
report_constraint

set_fix_hold [all_clocks]
clock_opt -fix_hold_all_clocks
report_constraint

set_max_area 0
set physopt_area_critical_range 1.0
psynopt -area_recovery
source ../script/connect_pg.tcl
report_constraint

# if {[check_error -verbose] != 0} { exit 4 }
check_error -verbose
save_mw_cel     -as $top_name\_4_cts
report_timing   >   $report_path/timing_4_cts.rpt


#-----------------------------------------------------------
#                            5  route
#-----------------------------------------------------------
check_physical_design -stage pre_route_opt
check_routeability

route_opt
route_zrt_eco
report_constraints
verify_zrt_route


# if {[check_error -verbose] != 0} { exit 5 }
check_error -verbose
save_mw_cel     -as $top_name\_5_route
report_timing   >   $report_path/timing_5_route.rpt

#-----------------------------------------------------------
#                            6  check
#-----------------------------------------------------------
# insert_pad_filler -cell " FILLER01 FILLER1  FILLER5  FILLER10 FILLER15  \
#                           FILLER20 FILLER35 FILLER40 FILLER55 FILLER   "\
#                   -overlap_cell "FILLER01"

insert_stdcell_filler  -cell_without_metal "SHFILL1   SHFILL2    SHFILL3    SHFILL64        \ 
                                            SHFILL128 DHFILLHLH2 DHFILLLHL2 DHFILLHLHLS11 " \
                       -connect_to_power  {VDD}                                             \
                       -connect_to_ground {VSS}
insert_metal_filler   -bounding_box [get_placement_area] \
                      -from_metal 1 -to_metal 9          \
                      -tie_to_net none                   \
                      -fill_poly                         \
                      -timing_driven

                    
source ../script/connect_pg.tcl
   
preroute_standard_cells -nets {VDD VSS}                 \
                        -port_filter_mode          off  \
                        -cell_master_filter_mode   off  \
                        -cell_instance_filter_mode off  \
                        -voltage_area_filter_mode  off
preroute_instances -ignore_pads        \
                   -ignore_cover_cells \
                   -select_net_by_type \
                    specified -nets {VDD VSS}

report_constraints


route_zrt_eco
report_constraints
verify_zrt_route


verify_lvs

save_mw_cel         -as $top_name\_6_check
report_timing       >   $report_path/timing_6_check.rpt
report_area         >   $report_path/area.rpt
report_constraints  >   $report_path/constraints.rpt

# gui_load_clock_tree_vm -clock_trees clk

#-----------------------------------------------------------
#                            7  export
#-----------------------------------------------------------
write_verilog   -no_io_pad_cells                    \
                -no_corner_pad_cells                \
                -no_pad_filler_cells                \
                -no_core_filler_cells               \
                -no_unconnected_cells               \
                -no_pg_pin_only_cells               \
                $netlist_path/$top_name\.icc.v
write_stream    -format gds                         \
                -lib_name $top_name                 \
                -cells $top_name                    \
                $gds_path/$top_name.gds
write_sdf       $netlist_path/$top_name\.icc.sdf
write_sdc       $netlist_path/$top_name\.icc.sdc
write_parasitics -output $netlist_path/$top_name\.spef

report_timing                    >   $report_path/timing_6_check_setup.rpt
report_timing  -delay_type min   >   $report_path/timing_6_check_hold.rpt
report_area                      >   $report_path/area.rpt
report_power                      >   $report_path/power.rpt
report_constraints               >   $report_path/constraints.rpt


# change_names -rules verilog -hierarchy
# remove_unconnected_ports [get_cells -hier {*}]
# write_sdc       $netlist_path/$top_name\.icc.sdc
# write_verilog -no_pad_filler_cells -no_corner_pad_cells -no_core_filler_cells -o $netlist_path/$top_name\2.icc.v

# quit
