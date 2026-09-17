# Testes cocotb do projeto
#   make            -> roda todos os testes (ULA, banco de registradores e maquina aritmetica)
#   make DUT=ula    -> roda apenas o teste da ULA
#   make DUT=reg_file / make DUT=arith_machine / make DUT=demux

SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl
SRC := $(abspath ../src)

ULA_SOURCES = $(SRC)/ula_fullAdder.vhd \
              $(SRC)/ula_logicUnit.vhd \
              $(SRC)/ula_1bit.vhd \
              $(SRC)/ula_32bits.vhd \
              $(SRC)/ula_flags.vhd \
              $(SRC)/ula.vhd

ifeq ($(DUT),ula)
  TOPLEVEL = ula
  MODULE = test_ula
  VHDL_SOURCES = $(ULA_SOURCES)
else ifeq ($(DUT),reg_file)
  TOPLEVEL = reg_file
  MODULE = test_reg_file
  VHDL_SOURCES = $(SRC)/reg_file.vhd
else ifeq ($(DUT),demux)
  TOPLEVEL = demux
  MODULE = test_demux
  VHDL_SOURCES = $(SRC)/demux.vhd
else ifeq ($(DUT),arith_machine)
  TOPLEVEL = arith_machine
  MODULE = test_arith_machine
  VHDL_SOURCES = $(ULA_SOURCES) \
                 $(SRC)/reg_file.vhd \
                 $(SRC)/sign_extender.vhd \
                 $(SRC)/zero_extender.vhd \
                 $(SRC)/arith_machine.vhd
endif

ifdef DUT
SIM_BUILD = sim_build_$(DUT)
COCOTB_RESULTS_FILE = results_$(DUT).xml
include $(shell cocotb-config --makefiles)/Makefile.sim
else
.PHONY: all clean
all:
ifneq ($(wildcard $(SRC)/demux.vhd),)
	$(MAKE) DUT=demux
endif
	$(MAKE) DUT=ula
	$(MAKE) DUT=reg_file
	$(MAKE) DUT=arith_machine

clean:
	rm -rf sim_build_* results*.xml __pycache__ *.vcd *.ghw
endif
