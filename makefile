################################################################################
# Makefile - spi_to_memory UVM environment
################################################################################

TEST ?= spi_to_memory_basic_test


# ------------------------------------------------------------------------------
# VCS compile options
# ------------------------------------------------------------------------------

VCS = vcs -sverilog -full64 -ntb_opts uvm \
      -timescale=1ns/1ps \
      -kdb -debug_acc+all \
      -f spi.fl \
      -o spi.simv


# Normal simulation command
SIM = ./spi.simv +UVM_TESTNAME=$(TEST)


# ------------------------------------------------------------------------------
# Coverage settings
# ------------------------------------------------------------------------------

COV_DB     = coverage.vdb
COV_REPORT = coverage_report

COV_FLAGS  = -cm line+cond+tgl+branch+fsm+assert


################################################################################
# Targets
################################################################################


# ------------------------------------------------------------------------------
# Default
# ------------------------------------------------------------------------------

all: comp


# ------------------------------------------------------------------------------
# Compile only
# ------------------------------------------------------------------------------

comp:
	$(VCS)


# ------------------------------------------------------------------------------
# Normal simulation
# ------------------------------------------------------------------------------

run: comp
	$(SIM)


# ------------------------------------------------------------------------------
# Normal simulation with GUI
# ------------------------------------------------------------------------------

gui: comp
	$(SIM) -gui &


# ------------------------------------------------------------------------------
# Functional Coverage + Code Coverage
#
# Functional Coverage:
#   covergroups
#   coverpoints
#   bins
#   crosses
#
# Code Coverage:
#   line
#   condition
#   toggle
#   branch
#   FSM
#
# Assertion coverage will also be available later when assertions are added.
# ------------------------------------------------------------------------------

cov:
	$(VCS) $(COV_FLAGS) -cm_dir $(COV_DB)
	$(SIM) $(COV_FLAGS) -cm_dir $(COV_DB)
	urg -dir $(COV_DB) -report $(COV_REPORT) -format both
	@echo "------------------------------------------------"
	@echo "Coverage completed"
	@echo "Test:              $(TEST)"
	@echo "Coverage database: $(COV_DB)"
	@echo "Coverage report:   $(COV_REPORT)"
	@echo "------------------------------------------------"


# ------------------------------------------------------------------------------
# Run coverage and open it in Verdi
# ------------------------------------------------------------------------------

cov_gui: cov
	verdi -cov -covdir $(COV_DB) &


# ------------------------------------------------------------------------------
# Clean
# ------------------------------------------------------------------------------

clean:
	rm -rf csrc \
	       spi.simv \
	       spi.simv.daidir \
	       *.vdb \
	       $(COV_REPORT) \
	       verdi_config_file* \
	       *.fsdb \
	       ucli.key
	@echo "Cleanup complete."


.PHONY: all comp run gui cov cov_gui clean
