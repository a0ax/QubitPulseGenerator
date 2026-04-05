SHELL := /bin/sh

IVERILOG ?= iverilog
VVP ?= vvp
VERILATOR ?= verilator
PYTHON ?= python3

RTL_DIR := ../rtl
SIM_DIR := ../sim
BUILD_DIR := ../build
DOCS_DIR := ../docs

.PHONY: all sim sim-pulse sim-multi wave lint clean

all: sim lint

sim: sim-pulse sim-multi

sim-pulse:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $(BUILD_DIR)/tb_pulse_gen.vvp $(RTL_DIR)/pulse_gen.sv $(SIM_DIR)/tb_pulse_gen.sv
	$(VVP) $(BUILD_DIR)/tb_pulse_gen.vvp

sim-multi:
	mkdir -p $(BUILD_DIR)
	$(IVERILOG) -g2012 -o $(BUILD_DIR)/tb_multi_pulse_gen.vvp $(RTL_DIR)/pulse_gen.sv $(RTL_DIR)/multi_pulse_gen.sv $(SIM_DIR)/tb_multi_pulse_gen.sv
	$(VVP) $(BUILD_DIR)/tb_multi_pulse_gen.vvp

wave:
	$(PYTHON) generate_waveform.py

lint:
	$(VERILATOR) --lint-only --sv --Wall -Wno-fatal $(RTL_DIR)/pulse_gen.sv $(RTL_DIR)/multi_pulse_gen.sv

clean:
	rm -rf $(BUILD_DIR) $(DOCS_DIR)/waveform.png