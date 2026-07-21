## Description

<!-- Short summary of what this PR does. Link the issue if applicable. -->

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds capability)
- [ ] Refactoring (no functional change)
- [ ] Documentation (no functional change)
- [ ] CI / infrastructure (no functional change)

## How has this been tested?

<!-- Describe what tests were added or updated. Run `nimble test` locally. -->
- [ ] `nimble test` — all packages, both Nim versions if possible
- [ ] Manual testing (describe what you did)
- [ ] N/A (documentation/CI only)

```
# Test output
```

## Checklist

- [ ] Code follows the project's style (run `nph fmt` if available)
- [ ] No `as any`, `@ts-ignore`, or bare `Exception` catches in production code
- [ ] Tests pass: `nimble test` in `talos_core/`, `talos_agent/`, `talos_code/`
- [ ] `CHANGELOG.md` updated under `[Unreleased]` with the change summary
- [ ] No sensitive data (tokens, keys, secrets) in the diff

## Additional context

<!-- Screenshots, edge cases, related issues, anything else relevant -->