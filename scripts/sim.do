if {[info commands vlog] ne ""} {
    vlib work
    vlog -sv ../rtl/pulse_gen.sv ../sim/tb_pulse_gen.sv
    vsim -c tb_pulse_gen -do "run -all; quit -f"
} elseif {[info commands xvlog] ne ""} {
    file mkdir xsim
    xvlog -sv ../rtl/pulse_gen.sv ../sim/tb_pulse_gen.sv
    xelab tb_pulse_gen -s tb_pulse_gen_sim
    xsim tb_pulse_gen_sim -runall
} else {
    puts "No supported simulator commands found (vlog/vsim or xvlog/xelab/xsim)."
}
