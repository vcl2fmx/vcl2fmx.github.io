# VCL2FMXConverter v5 Conversion Contracts

This folder contains the executable conversion contracts for VCL2FMXConverter v5.
These are no longer passive samples: the contract runner uses them to verify
converter behavior after structural changes.

In the public source-distribution zip, the contracts are included as the
authoritative fixture and expectation set. The internal runner scripts and
`RunConversionEngine.exe` are not included in that compile-only distribution.

## How Contracts Work

Each contract fixture is a small VCL input case, usually a `.pas` or `.dpr`
file, paired with a matching `.expected.json` file.

Example:

```text
contracts\components_and_events\19_form_centering_float_rounding.pas
contracts\components_and_events\19_form_centering_float_rounding.expected.json
```

The converter runs against the fixture. The runner then checks the generated
Pascal, FMX, DFM, and report output against the expectation file.

Contracts are test fixtures for the converter. They are not loaded during a
normal user conversion, and user source files are not compared against every
contract.

## Running Contracts

From the project root:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\tools\run_conversion_contracts.ps1 -EnforceCoverage
```

Default behavior:

- Fixture root: `contracts`
- Output root: `tests\conversion_contract_output`
- Runner executable: `tools\RunConversionEngine.exe`

`-EnforceCoverage` requires every discovered `.pas` and `.dpr` fixture to have
an expectation file or be covered by a project-level expectation.

Current verified status after the image-API contract expansion:

```text
Summary: 194 pass, 0 fail
```

## Expectation Fields

Common fields in `.expected.json` files:

- `input_file`: source fixture path relative to the project root.
- `expected_status`: expected conversion status, usually `converted`.
- `expected_conversions`: expected conversion categories.
- `expected_manual_reviews`: expected manual-review categories.
- `expected_units_added`: units that must appear in generated output.
- `expected_units_absent`: units that must not appear in generated output.
- `expected_output_patterns`: regex patterns that must appear in generated output.
- `forbidden_output_patterns`: regex patterns that must not appear in generated output.
- `expected_report_patterns`: regex patterns that must appear in conversion reports.
- `forbidden_report_patterns`: regex patterns that must not appear in conversion reports.
- `copy_case_directory`: optional project-level fixture mode that copies the whole
  fixture folder before conversion.
- `skip_generated_compile`: optional flag for fixtures that intentionally preserve
  missing/manual-review dependencies and should not be compiled when the runner is
  invoked with `-CompileGenerated`.

The contract runner checks generated-output patterns only against generated
Pascal/FMX/DPR output, and report patterns only against report text. This keeps
source excerpts in reports from accidentally satisfying or failing generated-code
assertions.

`-CompileGenerated` asks the runner to compile generated DPR output with `dcc32`
for compile-ready fixtures. The runner adds generated subfolders to the compiler
unit and include search paths so copied include files can be resolved.

## Contract Folders

- `colors`: VCL and FMX color constants, UI constants, modal results, dialog units,
  and color-helper edge cases. 15 expectations.
- `comments_and_boundaries`: comments, string literals, disabled blocks, routine
  boundaries, initialization/finalization boundaries, and message false positives.
  21 expectations.
- `components_and_events`: component declarations, events, form lifecycle,
  coordinate conversion, media, images, status bars, and custom-component cases.
  24 expectations.
- `data_aware`: DB-aware controls, runtime datasource access, lookup controls,
  navigator behavior, and dataset-binding review cases. 8 expectations.
- `dfm_fidelity`: DFM/FMXL object, event, and property fidelity checks.
  3 expectations.
- `dfm_pairs`: paired Pascal/DFM form fixtures for FMX generation behavior.
  7 expectations.
- `dry_run_preview`: dry-run preview behavior and no-artifact guarantees.
  1 expectation.
- `encoding`: UTF-8, whitespace, long-line, and include-directive encoding cases.
  4 expectations.
- `graphics`: VCL Canvas and WinAPI GDI drawing cases, including FMX canvas
  conversion and visual-review reporting. 7 expectations.
- `include_analysis`: Pascal include-file analysis, including beside-source,
  subfolder, missing, outside-tree, nested, recursive, VCL uses, Winapi message,
  conditional, UTF-8 include, and commented-out include directive cases.
  11 expectations.
- `livebindings`: existing LiveBindings and generated binding edge cases.
  6 expectations.
- `pascal_structure`: Pascal structure parsing, methods, helpers, attributes, and
  message-handler rules. 4 expectations.
- `project_files`: DPR and startup/project-resource behavior. 5 expectations.
- `project_integration`: mini-project contracts that exercise include, Windows
  messaging, uses cleanup, DFM/FMXL, and report-shape workflows as whole projects.
  6 expectations.
- `reporting`: leftover-code detection and manual-review report formatting.
  4 expectations.
- `semantic_resolution`: cross-unit and missing-implementation semantic checks.
  2 expectations.
- `third_party`: third-party and unknown component mapping behavior.
  4 expectations.
- `uses_clause`: uses-clause cleanup, Windows/VCL unit preservation and removal,
  conditional uses blocks, and leftover `Vcl.Themes` cleanup. 22 expectations.
- `winapi_messages`: Windows messaging APIs, message constants, message records,
  `WndProc`, message declarations, system commands, common control-message families,
  and false-positive guards. 40 expectations.

## Important Current Rules

- Include files are analyzed first and copied through; they are not automatically
  inlined into generated output.
- Windows message handling is category-based. Unsupported or risky behavior must
  produce explicit report items instead of silently remaining active.
- `WM_SYSCOMMAND` handlers remain manual-review unless a direct standalone case is
  safe to convert.
- GDI drawing contracts require FMX canvas conversion where safe and still require
  visual-review reporting.
- Form-centering and other integer-coordinate assignments must be rounded when FMX
  floating-point dimensions are involved.
- False positives in comments, strings, domain methods, and unrelated identifiers
  must not inject Windows units or report items.

## After Changing Converter Rules

Use this sequence:

```powershell
& 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\DCC32.EXE' -B -Q '-$O+' '-EWin32\Release' '-N0dcu\Win32\Release' VCL2FMXConverter.dpr
& 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\DCC32.EXE' -B -Q '-UC:\New Delphi Projects\VCL2FMXConverterV5' '-EC:\New Delphi Projects\VCL2FMXConverterV5\tools' '-N0C:\New Delphi Projects\VCL2FMXConverterV5\tools\dcu' RunConversionEngine.dpr
powershell.exe -ExecutionPolicy Bypass -File .\tools\run_conversion_contracts.ps1 -EnforceCoverage
powershell.exe -ExecutionPolicy Bypass -File .\tools\run_regression_guards.ps1 -FailOnBlockers
```

The contract suite should remain green before trusting a converter change.
