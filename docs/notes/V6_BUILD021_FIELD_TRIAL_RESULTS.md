# VCL2FMXConverter v6.0 Navigator — Build 021 Validation Record

Last changed: August 2, 2026

Build 021 is the first Navigator iteration whose contract gate compiles every
eligible generated fixture in an isolated staging workspace.

## Release gate

- 227 executable conversion contracts
- Compiler validation for every eligible generated fixture
- 64 regression guards
- 62 release-readiness acceptance checks
- 22 mapping packs and 493 rules validated against `vcl2fmx.mapping-pack.v1`
- Win32 Release build
- Win64 Release build
- Manual-review spill guard
- Mapping-pack smoke guard
- French beta field-regression guard
- Mapping-pack negative schema suite

## Intentional generated-compile exclusions

A contract may skip generated compilation only when the fixture intentionally
represents malformed Pascal, a missing or external dependency, dry-run output
that is not written, or a manual-review-only construct that is intentionally
not buildable. The expectation file must declare the skip explicitly.

## Build 021 corrections found by compiled contracts

- Valid conditional uses-clause comma placement
- Normalization of bare implementation units
- Required FMX list, tree, tab, and action-list units
- Required System UI, types, classes, and utility units
- Case-insensitive DFM geometry and caption property handling
- FMX-compatible alpha-blend and dialog-border translations
- FMX-compatible canvas text and rectangle helpers
- Isolated compile staging with unit and form-resource filename alignment

The generated project remains a migration starting point. A clean converter
gate does not replace compilation, runtime testing, visual review, data review,
or platform testing of the user's converted application.

## Verified artifacts

- Win32 Release SHA-256:
  `A85AB12AD41452EC5D3085095D8C131729889B684B5ECE579EC8EF4AC3FB9335`
- Win64 Release SHA-256:
  `9D5847D2AEE7030EB92BE7E23B979B8732E5C1E87270064E385D58BE071DE741`
- Source distribution:
  `VCL2FMXConverter_v6_0_Navigator_Build021_Source_Distribution_2026-08-02_133819.zip`
- Source distribution SHA-256:
  `BABB8C2BF8F1EC1DD6DB9F3784D0509B09FCB5603B37F677D5C4738D82E21FBF`

No files were pushed to GitHub.
