# Testes cocotb do projeto
#   make            -> roda todos os testes
#   make DUT=ula    -> roda apenas o teste da ULA
#   make DUT=reg_file / arith_machine / demux
#   make DUT=mips_rom / mips_ram                 (APS-1-4: memorias)
#   make DUT=control_unit / nextPC               (APS-1-4: decoder e proximo PC)
#   make DUT=mips_word_toplevel                  (APS-1-4: MIPS completo, ROM de teste mips_rom_programa.vhd)

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
else ifeq ($(DUT),mips_rom)
  TOPLEVEL = mips_rom
  MODULE = test_mips_rom
  VHDL_SOURCES = $(SRC)/mips_rom.vhd
else ifeq ($(DUT),mips_ram)
  TOPLEVEL = mips_ram
  MODULE = test_mips_ram
  VHDL_SOURCES = $(SRC)/mips_ram.vhd
else ifeq ($(DUT),control_unit)
  TOPLEVEL = control_unit
  MODULE = test_control_unit
  VHDL_SOURCES = $(SRC)/control_unit.vhd
else ifeq ($(DUT),nextPC)
  TOPLEVEL = nextpc
  MODULE = test_nextPC
  VHDL_SOURCES = $(SRC)/nextPC.vhd
else ifeq ($(DUT),mips_word_toplevel)
  # usa a ROM de teste (mips_rom_programa.vhd, gerada por gen_rom_programa.py)
  TOPLEVEL = mips_word_toplevel
  MODULE = test_mips_word_toplevel
  VHDL_SOURCES = $(ULA_SOURCES) \
                 $(SRC)/reg_file.vhd \
                 $(SRC)/sign_extender.vhd \
                 $(SRC)/zero_extender.vhd \
                 $(SRC)/shift_left2.vhd \
                 $(SRC)/pc_register.vhd \
                 $(SRC)/nextPC.vhd \
                 $(SRC)/control_unit.vhd \
                 $(abspath mips_rom_programa.vhd) \
                 $(SRC)/mips_ram.vhd \
                 $(SRC)/mips_word_toplevel.vhd
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
	$(MAKE) DUT=mips_rom
	$(MAKE) DUT=mips_ram
	$(MAKE) DUT=control_unit
	$(MAKE) DUT=nextPC
	$(MAKE) DUT=mips_word_toplevel

clean:
	rm -rf sim_build_* results*.xml __pycache__ *.vcd *.ghw
endif
