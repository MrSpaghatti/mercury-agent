.PHONY: build test lint desloppify

PYTHON ?= python3

build:
	cd mercury_core && nimble build -y
	cd mercury_agent && nimble build -y

test:
	cd mercury_core && nimble test -y 2>&1
	cd mercury_agent && nimble test -y 2>&1

lint: desloppify

desloppify:
	/tmp/opencode/desloppify-venv/bin/python -m desloppify scan --path .
