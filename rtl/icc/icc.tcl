#-----------------------------------------------------------
#                          Variables
#-----------------------------------------------------------
#   library
set lib_name            "saed90nm_typ"
set target_library      "saed90nm_typ.db SRAM32x512_1rw_typ.db"
set link_library        "* $target_library"
set lib_path            "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/ref/db"
set script_path         "../script"
set search_path         "$lib_path $script_path"

set file_path           "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/ref/"
set tech_file           "$file_path/tf/saed90nm_icc_1p9m.tf"
set mw_path             "$file_path/mw_std $file_path/mw_sram_32x512"
set tlup_map            "$file_path/tlup/tech2itf.map"
set tlup_max            "$file_path/tlup/saed90nm_1p9m_1t_Cmax.tluplus"
set tlup_min            "$file_path/tlup/saed90nm_1p9m_1t_Cmin.tluplus"

set power_name          "VDD"
set ground_name         "VSS"

#   design
set top_name            "filter_top"
set dc_netlist_path     "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/dc_submodule/dc_filter/netlist"
set verilog_file        "$dc_netlist_path/filter_top.dc.v"
set sdc_file            "$dc_netlist_path/filter_top.dc.sdc"

set netlist_path        "../netlist"
set report_path         "../report"
set log_path            "../log"
set gds_path            "../gds"


#-----------------------------------------------------------
#                         Log
#-----------------------------------------------------------
define_name_rules BORG -allowed {A-Za-z0-9_} -first_restricted "_" -last_restricted "_" -max_length 30
set timestamp [clock format [clock scan now] -format "%Y-%m-%d_%H-%M"]
set sh_output_log_file "$log_path/log.[pid].$timestamp"
set sh_command_log_file "$log_path/cmd.[pid].$timestamp"


#-----------------------------------------------------------
#                         Steps
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
                -open                 $top_name

# import_designs  $verilog_file \
#                 -format verilog \
#                 -top $top_design

read_verilog $verilog_file \
            -dirty_netlist \
            -top $top_name \
            -cel $top_name

set_tlu_plus_files  -max_tluplus  $tlup_max \
                    -min_tluplus  $tlup_min \
                    -tech2itf_map $tlup_map

read_sdc $sdc_file

uniquify_fp_mw_cel
current_design $top_name
link

if {[check_error -verbose] != 0} { exit 1 }
save_mw_cel     -as $top_name\_1_setup
report_timing   >   $report_path/timing_1_setup.rpt


#-----------------------------------------------------------
#                            2  floorplan
#-----------------------------------------------------------
remove_ideal_network -all
remove_propagated_clock [all_clocks]

derive_pg_connection -power_net  $power_name  \
                     -power_pin  $power_name  \
                     -ground_net $ground_name \
                     -ground_pin $ground_name
derive_pg_connection -power_net  $power_name  \
                     -ground_net $ground_name \
                     -tie

# read_pin_pad_physical_constraints ../scripts/pin.tcl

create_floorplan -core_utilization  0.4     \
                 -left_io2core      15      \
                 -bottom_io2core    15      \
                 -right_io2core     15      \
                 -top_io2core       15      \
                 -start_first_row

if {[check_error -verbose] != 0} { exit 2 }
save_mw_cel     -as $top_name\_2_floorplan
report_timing   >   $report_path/timing_2_floorplan.rpt


#-----------------------------------------------------------
#                            3  place
#-----------------------------------------------------------
# optimization setting
set_host_options                -max_core       16
# set_delay_calculation_options   -arnoldi_effort high
# set_route_opt_strategy          -fix_hold_mode  all
# set_fix_hold_options            -prioritize_min
# set_fix_multiple_port_nets      -all            -buffer_constants
# set_auto_disable_drc_nets       -constant       false
# set_app_var timing_enable_multiple_clocks_per_reg false

# set_fp_placement_strategy   -auto_grouping  high\
#                             -sliver_size    10  \
#                             -virtual_IPO    on  \
#                             -macros_on_edge on  \
#                             -fix_macros     all

set_app_var physopt_hard_keepout_distance 10
set placer_soft_keepout_channel_width 25 

# set_app_var derive_pg_preserve_floating_tieoff false

# cts_setting
# define_routing_rule iccrm_clock_double_spacing -default_reference_rule -multiplier_spacing 2 -multiplier_width 2
# report_routing_rule iccrm_clock_double_spacing
# set_clock_tree_options -routing_rule iccrm_clock_double_spacing -use_default_routing_for_sinks 1

# set_clock_tree_options -layer_list "M3 M4" ; # typically route clocks on metal3 and above

# set_route_zrt_detail_options -antenna true

# place opt
check_mv_design -verbose
create_fp_placement -timing_driven -no_hierarchy_gravity
derive_pg_connection -power_net  $power_name  \
                     -power_pin  $power_name  \
                     -ground_net $ground_name \
                     -ground_pin $ground_name
derive_pg_connection -power_net  $power_name  \
                     -ground_net $ground_name \
                     -tie

# power ring
# create_rectilinear_rings  -nets     {VDD VSS}    \
#                           -offset   {1   1  }    \
#                           -width    {3   3  }    \
#                           -space    {1   1  }
create_rectangular_rings 	\
	 -nets  {VDD}		\
	 -left_offset 0.5	\
	 -left_segment_layer M4	\
	 -left_segment_width 2	\
	 -right_offset 0.5 	\
	 -right_segment_layer M4	\
	 -right_segment_width 2	\
	 -bottom_offset 0.5	\
	 -bottom_segment_layer M4	\
	 -bottom_segment_width 2 	\
	 -top_offset 0.5	\
	 -top_segment_layer M4	\
	 -top_segment_width 2	
     
create_rectangular_rings  	\
		-nets  {VSS}	\
		-left_offset 3	\
		-left_segment_layer M5	\
		-left_segment_width 2	\
		-right_offset 3		\
		-right_segment_layer M5	\
		-right_segment_width 2	\
		-bottom_offset 3		\
		-bottom_segment_layer M5	\
		-bottom_segment_width 2		\
		-top_offset 3			\
		-top_segment_layer M5		\
		-top_segment_width 2
# power strap
# create_power_straps -direction  vertical        \
#                     -start_at   30              \
#                     -nets       {VSS VDD}       \
#                     -layer      M5              \
#                     -width      2               \
#                     -configure  step_and_stop   \
#                     -step       60              \
#                     -stop       465

set_dont_touch_placement [all_macro_cells]

# create_rectangular_rings	\
# 	  -nets  {VDD}		\
# 	  -skip_left_side	\
# 	  -right_segment_layer M4	\
# 	  -right_segment_width 2	\
# 	  -extend_rl			\
# 	  -skip_bottom_side		\
# 	  -top_segment_layer M4		\
# 	  -top_segment_width 2		\
# 	  -extend_tl			\
# 	  -around specified -cells  {ram_90nm}	
	  
# create_rectangular_rings	\
# 	  -nets  {VSS}		\
# 	  -skip_left_side	\
# 	  -right_offset 2.5	\
# 	  -right_segment_layer M5	\
# 	  -right_segment_width 2	\
# 	  -extend_rl			\
# 	  -skip_bottom_side		\
# 	  -top_offset 2.5		\
# 	  -top_segment_layer M5		\
# 	  -top_segment_width 2		\
# 	  -extend_tl			\
# 	  -around specified -cells  {ram_90nm}


# create_power_straps	\
# 	  -direction vertical	\
# 	  -start_at 13		\
# 	  -num_placement_strap 6	\
# 	  -increment_x_or_y 30	\
# 	  -nets  {VDD}	\
# 	  -layer M4	\
# 	  -width 2.0	\
# 	  -do_not_route_over_macros
	  
# create_power_straps	\
# 	-direction vertical	\
# 	-start_at 10	\
# 	-num_placement_strap 6	\
# 	-increment_x_or_y 30	\
# 	-nets  {VSS}	\
# 	-layer M5	\
# 	-width 2.0	\
# 	-do_not_route_over_macros

preroute_standard_cells	\
	 -connect horizontal	\
	 -port_filter_mode off	\
	 -cell_master_filter_mode off	\
	 -cell_instance_filter_mode off	\
	 -voltage_area_filter_mode off
	 
preroute_instances	\
	-ignore_pads -ignore_cover_cells

# \u907f\u514d\u7535\u6e90\u7f51\u683c\u901a\u5b54\u7ecf\u8fc7M1
# preroute_standard_cells -fill_empty_rows -do_not_route_over_macros -route_pins_on_layer M2 -remove_floating_pieces -skip_macro_pins -cut_out_empty_spans
# preroute_standard_cells -fill_empty_rows -remove_floating_pieces -extend_for_multiple_connections -extension_gap 2

# create_fp_placement -timing_driven -no_hierarchy_gravity -incremental all
verify_pg_nets

# place_opt
# place_opt -area_recovery -effort medium -congestion -power -continue_on_missing_scandef

derive_pg_connection -power_net  $power_name  \
                     -power_pin  $power_name  \
                     -ground_net $ground_name \
                     -ground_pin $ground_name
derive_pg_connection -power_net  $power_name  \
                     -ground_net $ground_name \
                     -tie

if {[check_error -verbose] != 0} { exit 3 }
save_mw_cel     -as $top_name\_3_place
report_timing   >   $report_path/timing_3_place.rpt


#-----------------------------------------------------------
#                            4  cts
#-----------------------------------------------------------
check_mv_design -verbose
# psynopt
# clock_opt -only_cts -no_clock_route -continue_on_missing_scandef -update_clock_latency
clock_opt -clock_trees {clk}

derive_pg_connection -power_net  $power_name  \
                     -power_pin  $power_name  \
                     -ground_net $ground_name \
                     -ground_pin $ground_name
derive_pg_connection -power_net  $power_name  \
                     -ground_net $ground_name \
                     -tie

remove_ideal_network [all_fanout -flat -clock_tree]
set_fix_hold [all_clocks]

if {[check_error -verbose] != 0} { exit 4 }
save_mw_cel     -as $top_name\_4_cts
report_timing   >   $report_path/timing_4_cts.rpt


#-----------------------------------------------------------
#                            5  route
#-----------------------------------------------------------
#   3.1 pg_physically
derive_pg_connection -power_net  $power_name  \
                     -power_pin  $power_name  \
                     -ground_net $ground_name \
                     -ground_pin $ground_name
derive_pg_connection -power_net  $power_name  \
                     -ground_net $ground_name \
                     -tie
                     
# set_delay_calculation_options   -arnoldi_effort high
# set_fix_hold_options            -prioritize_min
# set_route_opt_strategy          -fix_hold_mode all 

# set_route_options -track_assign_timing_driven true -same_net_notch check_and_fix

# set_distributed_route
# route_opt -initial_route_only
# route_opt -skip_initial_route -effort medium -xtalk_reduction
# route_opt -incremental 
# route_opt -incremental -size_only
route_opt

if {[check_error -verbose] != 0} { exit 5 }
save_mw_cel     -as $top_name\_5_route
report_timing   >   $report_path/timing_5_route.rpt

#-----------------------------------------------------------
#                            6  check
#-----------------------------------------------------------
insert_stdcell_filler  -cell_without_metal "SHFILL1 SHFILL2 SHFILL3 SHFILL64 SHFILL128 DHFILLHLH2 DHFILLLHL2 DHFILLHLHLS11"
# insert_pad_filler -cell "pfeed10000 pfeed05000 pfeed02000 pfeed01000 pfeed00500 pfeed00200 pfeed00100 pfeed00050 pfeed00010 pfeed00005"
# fix short
derive_pg_connection -power_net  $power_name  \
                     -power_pin  $power_name  \
                     -ground_net $ground_name \
                     -ground_pin $ground_name
derive_pg_connection -power_net  $power_name  \
                     -ground_net $ground_name \
                     -tie

# set_route_zrt_global_options -timing_driven false -crosstalk_driven false
# set_route_zrt_track_options -timing_driven false -crosstalk_driven false
# set_route_zrt_detail_options -timing_driven false

route_zrt_eco

# route_search_repair -rerun_drc -loop 20

verify_lvs

save_mw_cel         -as $top_name\_6_check
report_timing       >   $report_path/timing_6_check.rpt
report_area         >   $report_path/area.rpt
report_constraints  >   $report_path/constraints.rpt

#-----------------------------------------------------------
#                            7  export
#-----------------------------------------------------------
write_verilog   -no_io_pad_cells                    \
                -no_unconnected_cells               \
                -no_corner_pad_cells                \
                -no_pad_filler_cells                \
                -no_core_filler_cells               \
                -no_pg_pin_only_cells               \
                $netlist_path/$top_name\.icc.v
write_stream    -format gds                         \
                -lib_name $top_name                 \
                -cells $top_name                    \
                $gds_path/$top_name.gds
write_sdf        -version 2.1 $netlist_path/$top_name\.icc.sdf
write_sdc        -version 2.1 $netlist_path/$top_name\.icc.sdc
write_parasitics -output      $netlist_path/$top_name\.spef

# quit
