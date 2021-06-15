# rtl vs dc

#===================== set variables ======================
set top                 "png_top"
set ref_design_path     "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/rtl"
set imp_design_path     "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/dc_high/netlist"
set search_path         "/net/dellr940d/export/ybfan2/ttli/VLSI/mypng/ref/db"


#===================== set library ========================
set target_library "saed90nm_typ.db SRAM32x512_1rw_typ.db"
read_db -tech $target_library


#==================== set reference =======================
read_verilog -r "   $ref_design_path/common/defines.vh        \
                    $ref_design_path/common/ram.v             \
                    $ref_design_path/common/fifo.v            \
                    $ref_design_path/filter/filter.v          \
                    $ref_design_path/filter/filter_paeth.v    \
                    $ref_design_path/filter/filter_top.v      \
                    $ref_design_path/adler32/adler32.v        \
                    $ref_design_path/bs/bs_output.v           \
                    $ref_design_path/bs/bs_top.v              \
                    $ref_design_path/bs/huffman_fixed.v       \
                    $ref_design_path/crc32/crc32_core.v       \
                    $ref_design_path/crc32/crc32_top.v        \
                    $ref_design_path/lz77/lz77_detect_one.v   \
                    $ref_design_path/lz77/lz77_top.v          \
                    $ref_design_path/$top.v                   \
                "
set_top r:/WORK/${top}
current_design $top


#==================== set implementation ==================
read_verilog -i $imp_design_path/${top}.dc.v
set_top i:/WORK/${top}
current_design $top


#==================== compare =============================
match
verify


#==================== report ==============================
report_status > formality.dc.log

quit
