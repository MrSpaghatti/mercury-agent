.PHONY: build test lint nph

PYTHON ?= python3

build:
	cd mercury_core && nimble build -y
	cd mercury_agent && nimble build -y

test:
	cd mercury_core && nimble test -y 2>&1
	cd mercury_agent && nimble test -y 2>&1

lint: nph

nph:
	nimpretty --outputDir:src src/mercury_core/src/mercury_core/*.nim 2>/dev/null || echo "nimpretty not available"
