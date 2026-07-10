# VCL2FMX v5.0 Conversion Contract Plan

This file tracks structural conversion work deferred from v4.1.x into v5.0.

## Early v5 Structural Review

Because v5 is a major upgrade, this is the preferred window for structural changes that would be disruptive later. Review the converter for broader architecture changes before the v5 contract surface becomes large.

Large-unit review notes:

- `Converter.Parser.DFM.pas` is the best future split candidate. It currently contains DFM parsing, FMX generation, image/blob helpers, layout normalization, property/event review, and final FMX normalization. A clean split would likely separate DFM model/parser from FMX generation after contract coverage around DFM pairs is stronger.
- `Converter.Mapper.Component.pas` is a future split candidate. Built-in mappings, mapping-pack loading, RTTI inventory, reference artifact export, and mapping resolution can become separate mapper support units. Do this after mapper behavior has contract coverage, because mapping order and reporting side effects are sensitive.
- `Converter.Rewrite.LiveBindings.pas` is large by byte size, but it is mostly one cohesive injector with several generated-code appenders. Splitting is lower priority unless LiveBindings contracts expand substantially.
- `MainForm.pas` is large UI code. Avoid mixing UI refactors with converter-engine contract work unless UI behavior becomes a blocker.
- `Converter.Core.Engine.pas` may eventually split report generation and include analysis into support units. Defer until include contracts define the report fields and include traversal behavior.

Current decision: do not split units before the next contract expansion. Add executable contracts first, then split only when a test-backed boundary is clear.

## Include File Analysis

Add tested support for Pascal include directives:

- `{$I FileName.inc}`
- `{$INCLUDE FileName.inc}`
- `(*$I FileName.inc*)`
- `(*$INCLUDE FileName.inc*)`

Planned behavior:

- Resolve include paths safely from the source tree.
- Reject or warn on includes outside the source tree.
- Detect and prevent recursive include loops.
- Read include files with the same encoding detection used for Pascal files.
- Support nested includes with a depth guard.
- Preserve useful report locations for included-file findings.
- Analyze include contents without assuming the converter should rewrite project structure.
- Decide and test whether v5 should analyze-inline only, offer optional output inlining, or keep includes unchanged.

Preferred first implementation:

- Analyze included code so the converter can see VCL/Winapi/message usage.
- Keep the original include directive in generated output.
- Copy the include file to the matching output location.

Full output inlining can be added after contract tests prove line mapping, conditionals, and recursion handling are safe.

### Include Modernization Considerations

The converter should not automatically convert `.inc` files into `.pas` units in v5.0 without explicit user approval. Include files are valid Delphi syntax and may intentionally depend on textual inclusion.

For consideration only, v5.0 may report modernization guidance when an include file appears to be a good candidate for a normal Pascal unit:

- Shared constants.
- Shared types.
- Resource strings.
- Standalone utility functions or procedures.
- Repeated helper code included by multiple units.

The report may suggest that a programmer consider moving those items into a `.pas` unit and adding that unit to the appropriate interface or implementation `uses` clause.

The converter should avoid making that change automatically for risky include files:

- Method bodies injected into a form or class unit.
- Code fragments that rely on private fields of the including unit.
- Partial syntax fragments such as pieces of a `case` statement, class declaration, property list, or `uses` list.
- Compiler-switch include files containing only defines, warnings, conditionals, or version flags.
- Deeply conditional legacy code where intent is unclear.

This is a programmer guidance/reporting feature, not an automatic v5.0 implementation requirement.

Required contract tests:

- Include beside source unit.
- Include in source subfolder.
- Missing include.
- Include outside source tree.
- Nested include.
- Recursive include loop.
- Include containing VCL uses.
- Include containing Winapi message handlers.
- Include inside conditional directives.
- Include with UTF-8 accented text.

## Windows Messaging Contract

Turn the existing Windows messaging fixtures into tested conversion rules.

Initial v5 harness:

- `tools/run_conversion_contracts.ps1` discovers sibling `*.expected.json` files.
- Each expectation converts its input fixture in isolation through `tools\RunConversionEngine.exe`.
- The runner checks generated Pascal/FMX/DPR text, report text, expected/forbidden unit names, and expected/forbidden regex patterns.
- Use `-EnforceCoverage` when the full first-pass fixture set is ready; without it, the runner executes only fixtures that already have expectation files.

Primary fixture folders:

- `contracts/winapi_messages`
- `contracts/uses_clause`
- `contracts/comments_and_boundaries`
- `contracts/components_and_events`

### Detection Rules

The converter must explicitly classify real Windows messaging categories and families.

This is not a complete inventory of every Windows message code. Windows messaging includes hundreds of named constants and many thousands of possible `WM_USER`, `WM_APP`, and registered-message values. The contract tests representative families and behaviors rather than attempting to enumerate every possible message ID.

Representative detection families:

- `SendMessage(...)`
- `PostMessage(...)`
- `DispatchMessage(...)`
- `PeekMessage(...)`
- `GetMessage(...)`
- `Control.Perform(...)`
- `WM_*` constants
- `CM_*` constants
- `CN_*` constants
- common control-message families such as `EM_*`, `LB_*`, `CB_*`, `LVM_*`, `TVM_*`, `TCM_*`
- `TWM*` records
- `TCM*` records
- `message WM_*` method declarations
- `WndProc` overrides
- `WM_USER` and custom message offsets

The representative family list is intentionally category-based. It should be expanded when a fixture exposes a new message family, but v5.0 should not depend on a handwritten list of every individual Windows message constant.

The contract must also prove false positives are ignored:

- User-defined methods named `SendMessage`.
- User-defined methods named `PostMessage`.
- User-defined methods named `GetMessage`.
- Domain objects with message-like method names.
- Message API names inside comments.
- Message API names inside string literals.
- Lowercase or unrelated identifiers that only resemble Windows message names.
- Third-party class names that begin with message-like prefixes but are not message records.

### Conversion Rules

Each fixture must declare the expected conversion category:

- Safe automatic replacement.
- FMX helper replacement.
- `System.Messaging` / `FMXMessageBridge` conversion.
- Platform-specific preservation with warning.
- Commented-out unsupported VCL/Winapi behavior.
- Manual-review report only.
- No-op because the source was a false positive.

Examples:

- Simple memo/list control messages should convert to FMX-safe helper logic when a reliable mapping exists.
- `WM_USER` messaging should convert to, or be reported as needing, `System.Messaging`/bridge behavior.
- Message-pump APIs such as `GetMessage`, `PeekMessage`, and `DispatchMessage` should not remain silently active in FMX output.
- `WndProc` overrides and `message WM_*` handlers should produce explicit review/conversion results.

### Reporting Rules

Every real Windows messaging item that cannot be safely converted must produce a report item with:

- Source file.
- Source line.
- Original API/message symbol.
- Original code excerpt.
- Conversion category.
- Suggested FMX replacement path.
- Whether the issue blocks reliable generated output.

False-positive fixtures must prove no unnecessary report item is emitted.

### Uses-Clause Rules

The contract must verify unit insertion/removal:

- Do not retain unused original `Winapi.Messages`.
- Do not add `Winapi.Messages` for false positives.
- Add `Winapi.Messages` only when active generated code still requires it.
- Add `Winapi.Windows` only when active generated code still requires it.
- Add `System.Messaging` only when message-bridge conversion requires it.
- Add `FMXMessageBridge` only when generated bridge code is required.
- Preserve or remove implementation-only Windows units according to active code needs.

### Boundary And Comment Rules

The contract must verify the converter does not convert or report message code from inactive locations:

- Comments.
- String literals.
- Disabled/commented conversion blocks.
- Routine declarations that follow commented-out unsupported blocks.
- Comment-only lines inside disabled blocks.
- Initialization/finalization sections.
- End-of-unit boundaries.
- Attribute/declaration boundaries.
- Include-file boundaries after the include contract is implemented.

### How Samples Become Tested Rules

Each fixture receives a companion expectation file in v5.0, for example:

- `sample_name.expected.json`
- `sample_name.expected.pas`
- `sample_name.expected.report.txt`

The test runner must:

1. Convert the fixture input.
2. Compare generated Pascal/DFM/FMX output to the expected output or expected patterns.
3. Compare generated report items to expected issue categories.
4. Compare generated uses clauses to expected units.
5. Assert that false-positive fixtures produce no Windows-message conversion and no Windows-message unit injection.
6. Fail the contract run on unexpected `Winapi.Messages`, malformed commented blocks, missing report items, or leaked unsupported message code.

Minimum expectation fields:

- `input_file`
- `expected_status`
- `expected_conversions`
- `expected_manual_reviews`
- `expected_units_added`
- `expected_units_absent`
- `expected_output_patterns`
- `forbidden_output_patterns`

Required first-pass fixture coverage:

- All files currently in `contracts/winapi_messages`.
- Uses-clause fixtures that mention `Winapi.Messages`, `Winapi.Windows`, `Messages`, or `Windows`.
- Comment/boundary fixtures that mention message APIs, message constants, or conversion continuation behavior.
- Component/event fixtures for `message WM_*` handlers and `WndProc` overrides.
