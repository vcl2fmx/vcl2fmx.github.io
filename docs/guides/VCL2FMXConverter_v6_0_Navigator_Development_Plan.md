# VCL2FMXConverter v6.0 Navigator Development Plan

Last changed: August 1, 2026

Current iteration: Navigator Release v6.0 Build 020

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

## Iteration 002

Scope:

- Keep the complete version, build, date, and time inside the hero badge at
  normal and compact heights.
- Guard the minimum badge width in both designer and responsive-layout state.
- Make build-identity validation derive the active three-digit build rather
  than hardcode Build 001.
- Capture report-output equivalence baselines before decomposing the report
  generator.
- Extract the static HTML document head and CSS without changing rendered
  output.

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

## Iteration 003 — Contract Runner Provenance

Navigator Build 003 makes contract execution reject a stale
`RunConversionEngine.exe` whenever its runner project or converter source is
newer than the executable. Successful runs print the UTC run time, executable
timestamp and SHA-256 hash, plus the newest source timestamp. This prevents a
green contract result from being attributed to source the runner did not
actually contain.

## Iteration 004 — Lexical Ownership and Identifier Semantics

Navigator Build 004 removes the two byte-equivalent string-literal stripping
routines nested in the uses-clause rewriter and routes both callers through
the contract-protected shared lexical routine in `Converter.Core.Types`.

The RTTI property/event inventories and LiveBindings component-name lookup
tables now use ordinal, case-insensitive comparers. These keys are Delphi
identifiers, so their lookup semantics must match the language rather than
the spelling found in one source file. Other dictionaries remain unchanged
until their key semantics are reviewed individually.

## Iteration 005 — Navigator Identity Completion

Navigator Build 005 removes the inherited v5.0 Vanguard identity from active
converter unit headers and generated-project banners. Historical v5 website,
documentation, help, and archived sample material remain labeled Vanguard
because they describe the v5 release rather than the active v6 program.

## Iteration 006 — Verified Lexical and Comparer Cleanup

Navigator Build 006 completes the source-level dictionary comparer review.
String keys representing Delphi identifiers, symbols, vendor identities, and
Windows source paths now use ordinal, case-insensitive comparison. No default
string-keyed `TDictionary` or owning `TObjectDictionary` constructor remains
in active converter source.

The Pascal parser now delegates comment stripping to the shared lexical owner
with compiler-directive preservation explicitly disabled, matching its prior
parser-specific behavior without retaining a second scanner.

The original E35 audit lists 14 public methods, while the later merged note
requests deletion of five without naming them. Because public methods can be
invoked through external code, RTTI, interfaces, or method pointers, no method
was deleted based only on the two-reference count.

## Iteration 007 — Exact Report Golden Baselines

Navigator Build 007 adds exact normalized SHA-256 golden comparisons for both
text and HTML reports. Normalization is deliberately limited to workspace
paths, timestamps, and measured duration; totals, categories, severity,
ordering, escaping, messages, locations, and recommendations remain protected
byte for byte.

Golden coverage now includes a mixed/manual project report, a blocking report,
and an unknown third-party report. These baselines protect subsequent report
model and renderer extraction from silent text/HTML drift.

## Iteration 008 — Explicit Report Semantics and Parity

Navigator Build 008 adds independent text and HTML assertions for summary
totals, severity, category, source file and line, section ordering, HTML
escaping, recommendations, and paired text/HTML meaning. Exact goldens remain
the broad drift detector; these semantic checks identify the report contract
that was broken.

## Iteration 009 — Internal Report Snapshot Model

Navigator Build 009 introduces an internal report snapshot shared by text and
HTML summary rendering. It captures conversion totals, risk outcomes, paths,
status, next-step guidance, and issue snapshots with stable identity,
severity, category, source span, original evidence, and recommended action.
The existing normalized goldens must remain byte-equivalent.

## Iteration 010 — Model-Backed Text Renderer

Navigator Build 010 moves all text report rendering into
`Converter.Reporting.Text`. The renderer consumes only the internal report
snapshot; the engine no longer contains a second text-rendering path.
`GenerateReport` falls from 1,099 to 904 lines while all three exact text and
HTML goldens remain unchanged.

## Iteration 011 — Model-Backed HTML Renderer

Navigator Build 011 moves all dynamic HTML body rendering into
`Converter.Reporting.Html`. The existing static document head remains isolated
in its already-extracted method, while both dynamic renderers now consume the
same report snapshot. `GenerateReport` falls from 904 to 552 lines and the
normalized text and HTML goldens remain byte-equivalent.

## Iteration 012 — Deterministic JSON Report

Navigator Build 012 adds `VCL_to_FMX_Conversion_Report.json` only after text
and HTML equivalence was proven. The JSON uses schema
`vcl2fmx.report.v1` and exposes summary totals, risk outcomes, and stable issue
identity with severity, category, source span, original evidence, and
recommended action. Three representative contracts now protect exact
normalized text, HTML, and JSON artifacts.

## Iteration 013 — Review Corrections and Complete JSON Snapshot

Navigator Build 013 restores the field-test and smoke-test suites identified by
external review and makes the acceptance gate fail when either required guard
script is absent. Regression-guard reports now default to a temporary directory
instead of accumulating as untracked project files.

The `vcl2fmx.report.v1` JSON output now explicitly identifies `issues` as the
raw issue inventory. Per-issue presentation flags distinguish detailed,
dry-run-preview, and actionable informational entries. Stable identities include
the computed risk category, and the JSON snapshot now includes manual-review
groups, loaded mapping packs, mapping usages, and conversion-log lines already
owned by the shared report model.

## Iteration 014 — Navigator Hero and Compact Build Badge

Navigator Build 014 removes the remaining runtime-painted Vanguard wordmark
from the application hero. The existing designer-owned `HeroNavigatorGhost`
label is now visible and supplies the Navigator wordmark through editable FMX
properties. The release badge retains the product line, release, build number,
date, and time in a shorter format and a narrower designer-owned rectangle.

## Iteration 015 — Hero Alignment and Isolated French Regression Work

Navigator Build 015 centers the release text inside its designer-owned badge,
applies the established translucent orange accent to the Navigator wordmark,
and moves that wordmark farther right in both responsive layouts. The French
beta guard now creates all generated conversion, binary-DFM, and compiler
artifacts beneath a unique temporary directory and removes that directory
after the run, leaving its tracked fixture tree unchanged.

## Iteration 016 — Review Housekeeping Closure

Navigator Build 016 closes the remaining Round 2 review housekeeping. The 38
ignored legacy regression logs were removed while the 34 tracked historical
records were preserved. Legacy French-regression output folders are explicitly
ignored as a secondary defense, and regression guards now require the French
suite to use and clean an isolated temporary working directory rather than
write generated artifacts into its tracked fixture tree.

## Iteration 017 — E35 Reachability Closure

Navigator Build 017 reconciles the original fourteen-method E35 inventory and
removes only candidates that passed the full sequencing qualification. Each
method was verified as non-published, unbound to designer events, unrelated to
interfaces or method pointers, absent from name-based RTTI invocation, and
unreferenced beyond its declaration and implementation. A permanent regression
guard protects the closed inventory, and the detailed evidence is recorded in
`docs/notes/V6_E35_REACHABILITY_AUDIT.md`.

## Iteration 018 — Parser, Generator, and Catalog Responsibilities

Navigator Build 018 completes the measured oversized-unit split without
changing converter behavior. `Converter.Parser.DFM` now owns the DFM object
model and parsing only, while `Converter.Generator.FMX` owns FMX text
generation. `Converter.Mapper.Component` retains mapping resolution and RTTI
behavior, while static built-in and FMX component catalog construction lives
in `Converter.Mapper.Catalog`.

The original public parser and mapper entry points remain stable. Their
delegation boundaries are protected by regression guards, and both new units
are registered in the Delphi project so the split remains visible and
designer/IDE friendly.

## Iteration 019 — Mapping-Pack Schema Discipline

Navigator Build 019 establishes `vcl2fmx.mapping-pack.v1` as the explicit
mapping-pack schema for all 22 bundled packs and 493 rules. Runtime loading now
rejects missing or unsupported schema identifiers, malformed semantic versions,
unsupported modes/actions, invalid class names, confidence outside 0–100,
duplicate pack IDs, duplicate classes within a pack, and cross-pack class
collisions.

The reusable `tools/validate_mapping_packs.ps1` command applies the same
discipline before release or authoring work. Mapping-gap export now produces a
complete schema-bearing starter pack instead of a loose suggestion array,
deduplicates candidate classes, and keeps source evidence for review.

## Iteration 020 — Isolated and Semantic Validation

Navigator Build 020 moves default contract execution beneath a unique
temporary work tree and removes that tree after a successful run. Contract
validation no longer rewrites tracked output fixtures. Every generated JSON
report is parsed and checked for schema and required snapshot collections, and
declared auxiliary JSON files are parsed and may carry explicit content
patterns.

The mapping-pack schema suite now proves both sides of the contract: all
bundled packs pass, while missing schema, duplicate pack IDs, duplicate VCL
classes, and invalid confidence are rejected. The dry-run mapping suggestion
contract also verifies that its auxiliary artifact is a usable v1 starter
pack rather than merely checking that a file exists.
