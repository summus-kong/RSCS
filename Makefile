# This file is a part of RSCS
#
# Makefile for install RSCS dependices and change associated files executable authority
#
# define variable
SH = $(wildcard *.sh ./bin/*.sh)
FILEH = $(notdir $(SH))
PY = $(wildcard ./bin/*.py)
FILEPY = $(notdir $(PY))

install: executesh executepy dependices options
executesh:
	@echo "Give executable permissions: "$(FILEH)
	@chmod u+x $(SH)
executepy:
	@echo "Give executable permissions: "$(FILEPY)
	@chmod u+x $(PY)
dependices:
	@bash install_dependices.sh
options:
	@bash install_options.sh
