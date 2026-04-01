# Commenting Standard

## Goal

Comments must explain intent and constraints, not restate syntax.

## Allowed Comment Types

- Intent: why this approach exists.
- Invariant: what must always hold true.
- Boundary: platform/runtime assumptions.
- Safety: risk-sensitive logic and mitigation.

## Not Allowed

- Repeating obvious code behavior.
- Large narrative blocks that hide logic.
- Comments that no longer match behavior.

## Function Documentation Expectations

For non-trivial helper functions, document:

- Purpose.
- Input assumptions.
- Output guarantees.
- Failure behavior.
- Side effects.

## Repository-Specific Guidance

- AppleScript and shell glue should include boundary comments explaining escaping assumptions.
- Persistence helpers should include invariant comments for on-disk schema compatibility.
- Startup guards should explain why startup continues on missing generated files.
