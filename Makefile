# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2026 Karoshibee LTD
#
# Leaf targets assume the matching nix dev shell (see sections below).
# Orchestrators (test-all, ci, gen-all) invoke nix develop themselves — run
# those from a plain shell at the repo root.
#
#   nix develop          — oracle, proofs, format/check (default)
#   nix develop .#fpaa   — AD2 / fpaa scripts
#   nix develop .#asic   — Ngspice, xschem, base-4 CSV/sim
#   nix develop .#fpga   — HardCaml

NIX ?= nix
MAKEFLAGS += --no-print-directory

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:

export PYTHONPATH := $(CURDIR)/python$(if $(PYTHONPATH),:$(PYTHONPATH),)
export PYTHONUNBUFFERED := 1

.PHONY: help all check ci test test-all test-asic format check-format check-license \
	install-hooks \
	gen-all gen-refs gen-kbee-w8 gen-kbee-base4-w4 \
	test-python build-proofs test-proofs \
	build-fpga test-fpga \
	test-asic-csv run-asic-sim test-asic-fabric \
	gen-fpaa-waveforms fpaa-hw-gate

.DEFAULT_GOAL := help

##@ Aggregates

help: ## List targets (default)
	@awk 'BEGIN { FS = ":.*##"; printf "Usage: make [target]\n\nOrchestrators (test-all, ci, gen-all): plain shell, no nix develop needed.\nLeaf targets: matching dev shell (see Makefile header).\n" } \
		/^##@/ { printf "\n%s\n", substr($$0, 5) } \
		/^[a-zA-Z0-9_.-]+:.*##/ { printf "  %-22s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

all: check test ## Format/header checks + fast tests (default shell)

ci: ## Full gate via nix develop (plain shell OK)
	$(NIX) develop -c $(MAKE) check test
	$(NIX) develop .#asic -c $(MAKE) test-asic
	$(NIX) develop .#fpga -c $(MAKE) test-fpga

check: ## Format + SPDX/copyright headers (pre-push gate)
	check-kbee

test: test-python build-proofs ## Oracle + Lean (default shell)

test-asic: test-asic-csv test-asic-fabric run-asic-sim ## ASIC sim + CSV (.#asic)

test-all: ## All tests via nix develop (plain shell OK)
	$(NIX) develop -c $(MAKE) test
	$(NIX) develop .#asic -c $(MAKE) test-asic
	$(NIX) develop .#fpga -c $(MAKE) test-fpga

##@ Formatting & hooks

format: ## Format tracked py/sh/nix/md/toml/yaml
	format-kbee

check-format: ## Check formatting (no writes)
	check-format-kbee

check-license: ## Check SPDX / copyright headers
	check-license-headers

install-hooks: ## Set git core.hooksPath to .githooks
	install-git-hooks

##@ Reference CSV generation

gen-all: ## Regenerate all golden CSV tables via nix develop (plain shell OK)
	$(NIX) develop -c $(MAKE) gen-refs
	$(NIX) develop .#asic -c $(MAKE) gen-kbee-base4-w4

gen-refs: gen-kbee-w8 ## W=8 reference CSV (default shell)

gen-kbee-w8: ## data/kbee-w8-refs.csv (65536 rows)
	gen-kbee-refs

gen-kbee-base4-w4: ## data/kbee-base4-w4-refs.csv (ASIC oracle; .#asic)
	gen-kbee-base4-w4-refs

##@ Python oracle

test-python: ## unittest discover under python/test/
	run-kbee-tests

##@ Lean proofs

build-proofs: ## lake build Kbee
	cd proofs && lake build Kbee

test-proofs: build-proofs ## Alias for build-proofs

##@ FPGA (HardCaml) — requires: nix develop .#fpga

build-fpga: ## dune build in fpga/
	@command -v dune >/dev/null 2>&1 || { \
		echo "error: dune not found — run: nix develop .#fpga" >&2; exit 1; }
	cd fpga && dune build

test-fpga: build-fpga ## dune runtest in fpga/ (~2 min; CSV oracle)
	cd fpga && dune runtest

##@ ASIC (Ngspice + base-4 oracle; nix develop .#asic)

test-asic-csv: ## Oracle vs kbee-base4-w4-refs.csv (sampled)
	check-asic-csv --only-equiv --max-rows 5000

run-asic-sim: ## Batch Ngspice benches under asic/ngspice/tb/
	run-asic-sim

test-asic-fabric: ## Ngspice fabric corners vs Python oracle
	python3 asic/scripts/compare-ngspice-fabric.py

##@ FPAA scripts (waveforms + HW capture checks; nix develop .#fpaa)

gen-fpaa-waveforms: ## Canonical 81-case zsum pulse/zero waveforms
	python3 fpaa/scripts/gen-zsum-4trit-81-pulse-zero.py

# Example:
#   make fpaa-hw-gate RESIDUE=fpaa/data/cap-residue.csv NOR=... NOR_OR=... \
#                    NAND_AND=... XOR_XNOR=...
RESIDUE ?=
NOR ?=
NOR_OR ?=
NAND_AND ?=
XOR_XNOR ?=
OUT ?=

fpaa-hw-gate: ## Run kbee-04 HW gate script (requires capture CSV paths)
	@test -n "$(RESIDUE)" || { echo "Set RESIDUE=, NOR=, NOR_OR=, NAND_AND=, XOR_XNOR=" >&2; exit 1; }
	bash fpaa/scripts/kbee-04-hw-gate-runner.sh \
		--residue "$(RESIDUE)" \
		--nor "$(NOR)" \
		--nor-or "$(NOR_OR)" \
		--nand-and "$(NAND_AND)" \
		--xor-xnor "$(XOR_XNOR)" \
		$(if $(OUT),--out "$(OUT)",)
