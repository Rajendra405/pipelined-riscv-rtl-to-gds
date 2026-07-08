
# icc2_01_setup.tcl
# ICC2 Stage 1: create design library, read netlist + SDC, link.

set SAED32   /data/pdk/pdk32nm/SAED32_EDK
set STD_NDM  $SAED32/lib/stdcell_rvt/ndm/saed32rvt_c.ndm
set TECH_TF  $SAED32/tech/milkyway/saed32nm_1p9m_mw.tf
set TLU_MAP  $SAED32/tech/milkyway/saed32nm_tf_itf_tluplus.map
set TLU_MAX  $SAED32/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus
set TLU_MIN  $SAED32/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus

set NETLIST  ../syn/work/netlist/riscv_synth.v
set SDC      ../syn/work/netlist/riscv.sdc
set DESIGN   riscv


set STD_DB   $SAED32/lib/stdcell_rvt/db_ccs/saed32rvt_tt1p05v25c.db

set DLIB riscv.dlib


if {[file exists $DLIB]} { file delete -force $DLIB }

create_lib $DLIB \
    -technology $TECH_TF \
    -ref_libs   $STD_NDM

read_verilog $NETLIST -top $DESIGN
link_block

source $SDC

read_parasitic_tech -tlup $TLU_MAX -layermap $TLU_MAP -name maxTLU
read_parasitic_tech -tlup $TLU_MIN -layermap $TLU_MAP -name minTLU


report_ref_libs
report_clocks

save_block -as ${DESIGN}_setup
save_lib

puts "==== ICC2 setup done: library $DLIB, block ${DESIGN}_setup ===="
