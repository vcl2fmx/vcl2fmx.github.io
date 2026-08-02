# VCL2FMXConverter v6.0 Navigator — Build 022 Validation Record

Date: August 2, 2026

Build 022 closes the three non-blocking loose ends from Claude's Round 3
review and resolves the remaining Build 021 timing question under an isolated
compiler-backed contract run.

## Corrections

- Renamed all 22 bundled mapping-pack files to stable, version-neutral names.
  Schema identity and semantic versioning remain inside each JSON pack.
- Corrected the V5 paths in the contract-running instructions.
- Documented the fast structural contract command separately from the full
  compiler-backed release command.
- Added `-CompileGenerated -EnforceCoverage` to the acceptance release gate.
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
- Win32 Release build: succeeded; file version 6.0.0.22.
- Win64 Release build: succeeded; file version 6.0.0.22.

## Release artifacts

- Win32 executable: 13,360,640 bytes; SHA-256
  `F0BE7AC8B8C1B4F8B508B50041DCCEB9C476BFF71C9405959876283863F9424C`.
- Win64 executable: 18,890,752 bytes; SHA-256
  `8E249F4267FF8AC0AB256D1B224B5C599D81D4D019F7F26752BE15A476657641`.
- Source distribution:
  `VCL2FMXConverter_v6_0_Navigator_Build022_Source_Distribution_2026-08-02_170228.zip`;
  852,789 bytes; SHA-256
  `F6062F771B5A3CE0BCDE77945347AF5309A939A825C0C4F10361158C47ECB8E2`.
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
manual step. The acceptance gate now invokes the full contract suite with both
coverage enforcement and generated-code compilation. The faster non-compiling
contract command remains available for ordinary inner-loop development.

No GitHub push was performed.
