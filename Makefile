BSC := bsc
SOURCE_DIR := ../src

BSC_FLAGS += -show-schedule -warn-method-urgency -warn-action-shadowing -bdir . -info-dir . -simdir . -vdir .

.PHONY: all
all: mkTestbench_bsim mkTestbench.v

mkTestbench_bsim: $(wildcard $(SOURCE_DIR)/*.bsv)
	$(BSC) $(BSC_FLAGS) -sim -u -p $(SOURCE_DIR):%/Libraries -g mkTestbench $(SOURCE_DIR)/Testbench.bsv
	$(BSC) $(BSC_FLAGS) -sim -u -p $(SOURCE_DIR):%/Libraries -e mkTestbench -o $@

mkTestbench.v: $(wildcard $(SOURCE_DIR)/*.bsv)
	$(BSC) $(BSC_FLAGS) -verilog -u -p $(SOURCE_DIR):%/Libraries -g mkTestbench $(SOURCE_DIR)/Testbench.bsv

ixayoi_axi_bsv.v: $(wildcard $(SOURCE_DIR)/*.bsv)
	$(BSC) $(BSC_FLAGS) -verilog -u -p $(SOURCE_DIR):%/Libraries -g ixayoi_axi_bsv $(SOURCE_DIR)/ixayoi_axi_bsv.bsv

.PHONY: sim
sim: mkTestbench_bsim
	./$< -V ../simout/sim.vcd
