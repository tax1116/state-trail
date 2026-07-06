# 0001. Adopt Spec and ADR Documentation Model

Status: Accepted

## Context

StateTrail needs documentation that remains useful as the product and architecture
evolve. Temporary implementation notes, proposal drafts, and research notes can
help during a change, but they should not become the default source of truth for
people or agents reading the repository later.

The durable documentation model needs to distinguish between:

- observable product behavior that consumers and maintainers can rely on;
- architecture and process decisions that explain why the system is shaped a
  certain way;
- temporary review and implementation packages for in-flight Spec changes;
- local research and draft material that should not be treated as active
  project guidance.

## Decision

StateTrail will keep long-lived documentation centered on Specs and ADRs.

Specs live under `openspec/specs/` and describe observable behavior contracts:
what the product does, what guarantees it exposes, and what scenarios must keep
working. They are the primary durable reference for product behavior.

ADRs live under `docs/adr/` and describe durable architecture or process
decision rationale: the context, decision, consequences, and tradeoffs that
should shape future changes.

`openspec/changes/<change>/` is a Spec Change review package. Its proposal,
design, tasks, and spec deltas support review and implementation of that
specific change; they are not standalone long-lived documentation types.
People and agents should read a change package when they are working on that
change or reviewing its history.

`openspec/changes/archive/` is historical record. It can explain how previous
changes landed, but it is not active guidance for normal implementation work.
Active behavior guidance should come from `openspec/specs/`; durable decision
guidance should come from `docs/adr/`.

`docs/research/` remains an ignored local research and draft space. Research
notes can inform future Specs or ADRs, but files in that directory are not
repository guidance until the relevant conclusions are promoted into a tracked
Spec or ADR.

## Consequences

People and agents have two default durable reading locations:

- `openspec/specs/` for product behavior contracts;
- `docs/adr/` for architecture and process decision rationale.

Spec Change package files remain useful during review and implementation, but
they should not be cited as the current contract after a change is complete.
Specs are current, reviewable behavior contracts; they are durable guidance,
not immutable final decisions.
When a change affects durable behavior, update or add Specs. When a change
creates a durable architectural or process decision, add an ADR.

Research and draft material can stay lightweight and local without polluting the
repository source of truth.
