Copied Mercury scaffold to /home/spag/mercury and verified Nimble builds for mercury_core and mercury_agent.
Installed desloppify in a local virtual environment at /tmp/opencode/desloppify-venv because system pip was unavailable (PEP 668/external management).
Added make desloppify target to run /tmp/opencode/desloppify-venv/bin/python -m desloppify scan --path . explicitly on demand.
Added .desloppify/ to .gitignore and documented explicit usage in README.md.
Verified make desloppify succeeds and reports a clean scan (0 issues, 100 strict/verified).
6. nimble test discovers tests in <package>/tests/ directory. Use `nimble test <name>` to run a specific test file (e.g., `nimble test tconfig` runs tests/tconfig.nim).
7. nimble test uses `--path:.` (package root) for compilation. To expose src/ modules to tests, add a `tests/config.nims` with `switch("path", "../src")`.
8. std/parsecfg handles INI/TOML-like files with [section] headers and key=value pairs — sufficient for Mercury's config.toml format.
9. Use `template withEnv(key, val: string; body: untyped)` for env var test helpers in Nim 2.x — avoids StmtListLambda deprecation warning from `proc()` body syntax.
10. Config loading priority (highest wins): env vars > .env file > TOML file > defaults.
