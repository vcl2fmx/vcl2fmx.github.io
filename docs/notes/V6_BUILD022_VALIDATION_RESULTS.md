# VCL2FMXConverter v6.0 Navigator — Build 022 Validation Record

Date: August 2, 2026

Build 022 closes the three non-blocking loose ends from Claude's Round 3
review and resolves the remaining Build 021 timing question under an isolated
compiler-backed contract run.

## Corrections

- Renamed all 22 bundled mapping-pack files to stable, version-neutral names.
  Schema identity and semantic versioning remain inside each JSON pack.
- Corrected the V5 paths in the contract-running instructions.
- Corrected the conversion-contract README title to identify v6.0 Navigator.
- Documented the fast structural contract command separately from the full
  compiler-backed release command.
- Added `-CompileGenerated -EnforceCoverage` to the acceptance release gate.
- Extended the acceptance release gate to build and verify both Win32 and
  Win64 Release targets.
- Added path-independent normalization for bundled mapping-pack paths in
  deterministic text, HTML, and JSON report snapshots.
- Synchronized the designer badge, form caption, source header, project version
  metadata, and README for Navigator Build 022.

## Validation results

- Mapping-pack validation: 22 packs, 493 rules, 0 errors.
- Mapping-pack negative schema guard: passed.
- Conversion contracts: 227 passed, 0 failed.
- Compiler-eligible generated fixtures: 189 compiled successfully.
- Intentional generated-compile exclusions: 38.
- Regression guards: 64 passed, 0 blockers, 0 warnings.
- Acceptance gate: 63 passed, 0 failed.
- Win32 Release build: succeeded with 0 errors and no non-hint compiler
  warnings; file version 6.0.0.22.
- Win64 Release build: succeeded with 0 errors and no non-hint compiler
  warnings; file version 6.0.0.22. Delphi H-level compiler hints remain
  informational and do not fail the release gate.

## Release artifacts

- Win32 executable: 13,360,640 bytes; SHA-256
  `00897A142F394540BF6454EF7746C8B61C0FC15B352CBCCB0687E78D6C87FC42`.
- Win64 executable: 18,890,752 bytes; SHA-256
  `DCB5508A25F53536C04DC7254945506C7286A833B27E37034FD673F3AE1E68A4`.
- Source distribution:
  `VCL2FMXConverter_v6_0_Navigator_Build022_Source_Distribution_2026-08-02_173703.zip`;
  852,798 bytes; SHA-256
  `C917B0102D93AF85E985EC55F0081C0FF08A00532BBEF79A52E8BE1A91902E6A`.
- Source archive verification: 587 entries, 22 mapping packs, no legacy
  `_v4_1` filenames, and no build-output, test, tool, documentation, EXE, or
  DCU entries.

## Build 021 timing question

The timing-sensitive
`contracts\pascal_structure\11_large_unit_analysis\LargeUnitAnalysis.pas`
fixture passed during the clean, isolated full-suite runs without changing its
15,000 millisecond budget. Claude's earlier 20,064 millisecond result is
therefore treated as machine-contention noise rather than a converter
performance regression.

## Release-gate behavior

Compiled generated-output validation is no longer an optional release-time
manual step. The acceptance gate now builds both Release architectures and
invokes the full contract suite with both coverage enforcement and
generated-code compilation. The faster non-compiling contract command remains
available for ordinary inner-loop development.

No GitHub push was performed.
