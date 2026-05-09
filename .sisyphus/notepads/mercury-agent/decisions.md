Keep the scaffold minimal until Phase 1 implementation begins.
Config module uses std/parsecfg (not a TOML library) since the format is INI-compatible. .env parsing is done with a simple line parser (no external deps). tests/config.nims adds --path:../src so test files can import mercury_core/config.
