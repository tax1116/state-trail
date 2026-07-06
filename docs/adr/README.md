# Architecture Decision Records

ADRs record durable architecture and process decisions for StateTrail.

Use an ADR when a decision should guide future work and the rationale matters:
module boundaries, documentation policy, persistence strategy, integration
contracts, operational constraints, or other choices with lasting tradeoffs.

Do not use ADRs for transient implementation notes, task lists, research dumps,
or observable product behavior contracts. Product behavior belongs in
`openspec/specs/`. In-flight Spec Change material belongs under
`openspec/changes/<change>/`.

Each ADR should be short and use this shape:

- `Status`: Proposed, Accepted, Superseded, or Deprecated.
- `Context`: the forces, constraints, and problem that led to the decision.
- `Decision`: the chosen policy or architecture.
- `Consequences`: the tradeoffs, follow-up obligations, and reading guidance.

When reading the repository, check `openspec/specs/` for behavior and this
directory for durable decision rationale. Treat `openspec/changes/archive/` as
history, not active guidance.
