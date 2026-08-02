# VCL2FMXConverter v6.0 Navigator Development Plan

Last changed: August 1, 2026

Current iteration: Navigator Release v6.0 Build 001

## Release Direction

VCL2FMXConverter v6.0 Navigator is centered on:

- Maintainability and verified cleanup.
- Reporting integrity.
- Designer-owned user interface controls.
- Mapping-pack discipline.
- Stronger automated and real-project validation.

Compiler-style Pascal and DFM models, project-wide symbol indexing, and
edit-based generation are research and prototype work. They are not promised
v6 release deliverables.

## Binding Sequencing Qualifications

1. Methods identified as dead code must not be removed from reference counts
   alone. Every candidate must also be checked against FMX/DFM event
   assignments, published members, RTTI, interfaces, method pointers, and
   name-based invocation.
2. Dictionary comparers must be reviewed individually. Case-insensitive
   comparison is appropriate only where the key represents a
   case-insensitive Delphi or platform identifier.
3. Shared lexical behavior must have a deliberate owner. Core.Types must not
   become a general dumping ground, and dependency direction must remain
   valid.
4. The reporting procedure is a high-value but high-risk refactor. Exact
   output behavior must be captured before it is decomposed.

## Build Number Policy

- Build numbering begins at 001.
- Increment the build once for every completed and validated v6 iteration.
- Experimental recompiles do not increment the build number.
- The designer label uses the form:
  `Navigator Release v6.0 Build nnn`.
- The form caption, source version header, executable version information,
  README, and designer label must remain synchronized.
- Build identity must remain visible and editable in the RAD Studio Object
  Inspector. It must not be injected by runtime UI construction.

## Iteration 001

Scope:

- Establish v6.0 Navigator and Build 001 identity.
- Move the dry-run checkbox from runtime construction into MainForm.fmx.
- Add regression guards for designer ownership and synchronized build
  identity.
- Record the adopted v6 plan.

Validation gate:

- Release Win32 and Win64 builds.
- Full conversion-contract suite with coverage enforcement.
- Regression guards with zero blockers.
- Direct inspection of executable version information.
- Git review and an intentional Build 001 commit.

## Next: Verified Cleanup

Perform only independently verified cleanup:

- Validate each allegedly dead method before removal.
- Confirm the reported duplicate lexical function and its scopes.
- Review remaining dictionary comparer sites one by one.
- Correct stale contract and rules-reference counts from the actual fixture
  inventory.
- Add build and contract-runner provenance with stale-executable rejection.

Each behavioral correction requires a focused regression contract or guard.

## Reporting Integrity Milestone

The existing report generator exceeds 1,400 lines and mixes analysis,
aggregation, text rendering, and HTML rendering.

Safe sequence:

1. Capture representative text and HTML reports as normalized golden outputs.
2. Add assertions for totals, severity, category, file, source location,
   ordering, escaping, recommendations, and text/HTML parity.
3. Extract an internal report data model without changing rendered output.
4. Move text rendering and HTML rendering behind that model one at a time.
5. Compare normalized before-and-after artifacts at each step.
6. Add JSON output only after text and HTML equivalence is proven.

Stable issue identity should ultimately include category, severity, source
file, source span, original evidence, and recommended action.

## Mapper, DFM Parser, and Mapping Packs

Split oversized units by their existing responsibilities before considering
model rewrites:

- Mapping-pack schema and loading.
- Mapping lookup and precedence.
- Component, property, and event mapping.
- DFM reading and normalization.
- DFM object parsing.
- FMX emission and fidelity checks.

Mapping packs require an explicit schema version, compatibility validation,
deterministic precedence, duplicate/conflict reporting, and traceable mapping
provenance.

Standard VCL mappings may use the same external infrastructure after the
mapping-pack schema is stable and contract-protected.

## Designer-Owned UI

All controls and editable visual parameters belong in FMX form resources and
the Object Inspector unless the developer separately approves an unavoidable
runtime exception.

Worker-thread errors must be marshalled safely to the UI thread. Preview
workflows must preserve the source and must not write converted project files
until the user starts a real conversion.

## Stronger Validation

Required improvements:

- A false-positive fix must include both a positive fixture and a false-guard
  fixture.
- Add large Pascal and DFM fixtures beyond the existing small examples.
- Add explicit duration limits for selected scale-sensitive tests.
- Record the compiler, runner executable, source revision, build number, and
  timestamp used for a contract run.
- Reject a stale contract runner when its provenance does not match the source
  under test.
- Prefer structural comparisons where regex-only assertions can pass
  incorrectly.

Pre-release validation includes:

- Release Win32 and Win64 builds.
- Full contracts and regression guards.
- Carillon, GPS Control, and RealTimeClock field trials.
- Source-distribution inspection.
- Independent static review.

## Deferred Backlog

The following are not committed v6 scope:

- Full Pascal intermediate model.
- Full DFM intermediate model.
- Project-wide compiler-like symbol resolution.
- Edit-based Pascal generation.
- Conversion confidence scoring.
- Visual conversion diff view.
- Replay mode.
- Telemetry.

A shared lexical scanner may be prototyped against representative contracts
and field-trial projects. Broader compiler-style work requires evidence from
that prototype and separate approval.
