# QubitPulseGenerator

- Run simulation (Questa or Vivado xsim): `cd scripts && vsim -c -do sim.do` or `vivado -mode batch -source sim.do`.
- Create Vivado project (XC7A100T): `create_project pulse_gen ./build -part xc7a100tcsg324-1; add_files ../rtl/pulse_gen.sv; add_files -fileset constrs_1 ../constraints/pulse_gen.xdc`.
- Run implementation: `launch_runs impl_1 -to_step write_bitstream; wait_on_run impl_1`.
- Generate timing report: `report_timing_summary -delay_type max -report_unconstrained -max_paths 10 -file timing_summary.rpt`.
- Verify in `timing_summary.rpt` that `WNS >= 0` and reported Fmax is greater than 100 MHz.
