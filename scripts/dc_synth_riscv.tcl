# dc_synth_riscv.tcl
# Library : SAED32 RVT, typical corner (1.05 V, 25 C)
# Tool    : Design Compiler (Graphical / Ultra), logical mode



#------------------------------------------------------------------------------
# 0. Paths  --  edit RTL_FILE to point at your uploaded riscvpipelined.v
#------------------------------------------------------------------------------
set SAED32   /data/pdk/pdk32nm/SAED32_EDK
set RVT_DB   $SAED32/lib/stdcell_rvt/db_ccs
set RTL_FILE  ../../rtl/riscv_core_synth.v        ;# <-- set to wherever you copied it

# Confirm this filename exists (see note in chat). If your corner name differs,
# fix it here:
set STD_DB   $RVT_DB/saed32rvt_tt1p05v25c.db

#------------------------------------------------------------------------------
# 1. Library setup
#------------------------------------------------------------------------------
set_app_var target_library $STD_DB
set_app_var link_library  "* $STD_DB"

define_design_lib WORK -path ./work
file mkdir ./work
file mkdir ./reports
file mkdir ./netlist

#------------------------------------------------------------------------------
# 2. Read RTL and elaborate ONLY the core
#
#    The file also contains testbench / top / imem / dmem. By elaborating
#    'riscv' as the top, DC builds only the core hierarchy -- imem and dmem
#    are instantiated up in 'top', not inside 'riscv', so the behavioral
#    memories, $readmemh, $display and $stop never enter the synthesized
#    design. Expect (harmless) analyze-time warnings about those constructs.
#------------------------------------------------------------------------------
analyze -format verilog $RTL_FILE
elaborate riscv
current_design riscv
link
uniquify

#------------------------------------------------------------------------------
# 3. Constraints
#    Starting target: 2.0 ns = 500 MHz. This is deliberately comfortable --
#    run it, read the WNS, then tighten the period to find the wall. The
#    execute-stage path (forward mux -> ALU) is the one to watch.
#------------------------------------------------------------------------------
set CLK_PERIOD 3.3 
create_clock -name clk -period $CLK_PERIOD [get_ports clk]

# Clock is ideal pre-CTS; model a little pessimism.
set_clock_uncertainty 0.15 [get_clocks clk]
set_clock_transition  0.10 [get_clocks clk]

# Async reset: treat as an ideal network for synthesis (no timing on it yet).
set_ideal_network [get_ports reset]

# I/O timing: budget ~40% of the period at the boundary.
set IO_DELAY [expr 0.40 * $CLK_PERIOD]
set_input_delay  $IO_DELAY -clock clk \
    [remove_from_collection [all_inputs] [get_ports {clk reset}]]
set_output_delay $IO_DELAY -clock clk [all_outputs]

# Boundary drive/load without depending on exact cell/pin names (robust first run).
# The realistic refinement later is set_driving_cell with a real RVT buffer.
set_input_transition 0.10 [remove_from_collection [all_inputs] [get_ports clk]]
set_load             0.05 [all_outputs]

#------------------------------------------------------------------------------
# 4. Compile
#    -no_autoungroup keeps controller / datapath / hazard as visible blocks in
#    the area report, which is nicer to talk through. Drop it for best QoR.
#------------------------------------------------------------------------------
check_design > reports/check_design.rpt
compile_ultra -no_autoungroup

#------------------------------------------------------------------------------
# 5. Reports  (these are your interview evidence -- keep them)
#------------------------------------------------------------------------------
report_qor                              > reports/qor.rpt
report_timing -max_paths 10 -nworst 10  > reports/timing.rpt
report_area   -hierarchy                > reports/area.rpt
report_constraint -all_violators        > reports/violators.rpt
report_power                            > reports/power.rpt
report_clock_gating                     > reports/clock_gating.rpt

#------------------------------------------------------------------------------
# 6. Write outputs for ICC2 / PrimeTime
#------------------------------------------------------------------------------
write -format verilog -hierarchy -output netlist/riscv_synth.v
write -format ddc     -hierarchy -output netlist/riscv_synth.ddc
write_sdc netlist/riscv.sdc

puts "==== synthesis done: see ./reports and ./netlist ===="
exit
