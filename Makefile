.PHONY: build test lint desloppify

PYTHON ?= python3

build:
	nimble build -p:mercury_core
	nimble build -p:mercury_agent

test:
	nimble test -p:mercury_core
	nimble test -p:mercury_agent

lint: desloppify

desloppify:
	/tmp/opencode/desloppify-venv/bin/python -m desloppify scan --path .
