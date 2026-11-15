# ##########################################################
# RISC-V Core SDC
# Generated for RISC-V Core RTL
# ##########################################################
set sdc_version 2.0

# Units
set_units -capacitance 1000fF
set_units -time 1000ps

# Current design
current_design riscv_core

# ---------------------------
# Clocks
# ---------------------------
create_clock -name clk -period 5.5 -waveform {0 2.75} [get_ports clk]
set_clock_transition 0.1 [get_clocks clk]
set_clock_uncertainty -setup 0.05 [get_clocks clk]
set_clock_uncertainty -hold 0.05 [get_clocks clk]

# ---------------------------
# Input Delays
# ---------------------------
set_input_delay -clock [get_clocks clk] -max 1.0 [get_ports reset]

# ---------------------------
# False paths
# ---------------------------
set_false_path -from [get_ports reset]

# ---------------------------
# Wire Load
# ---------------------------
set_wire_load_mode "enclosed"

# --------------------------- 
# Clock Gating (if used) 
# --------------------------- 
set_clock_gating_style -positive_clock_enable
set_clock_gating_check -setup 0.1
