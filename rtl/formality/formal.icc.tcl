# dc vs icc

#===================== set variables ======================
set top                 "png_top"
set ref_design_path     "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/dc_high/netlist"
set imp_design_path     "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/icc/png2/netlist"
set search_path         "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/ref/db"


#===================== set library ========================
set target_library "saed90nm_typ.db SRAM32x512_1rw_typ.db"
read_db -tech $target_library


#==================== set reference =======================
read_verilog -r $ref_design_path/${top}.dc.v
set_top r:/WORK/${top}
current_design $top


#==================== set implementation ==================
read_verilog -i $imp_design_path/${top}.icc.v
set_top i:/WORK/${top}
current_design $top


#==================== compare =============================
match
verify


#==================== report ==============================
report_status > formality.icc.log

# quit
