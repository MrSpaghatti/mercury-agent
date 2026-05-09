.PHONY: build test lint desloppify

build:
	nimble build -p:mercury_core
	nimble build -p:mercury_agent

test:
	nimble test -p:mercury_core
	nimble test -p:mercury_agent

lint:
	desloppify .

desloppify:
	desloppify .
