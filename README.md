# VCL2FMXConverter v6.0 Navigator

![VCL2FMXConverter](assets/vcl2fmx-logo.png)

VCL2FMXConverter is an open-source Delphi FireMonkey application that automates much of the repetitive work involved in converting Delphi VCL projects to FMX. It analyzes Pascal and DFM source, applies conservative component and code mappings, creates an FMX-oriented project, and reports the work that still requires developer review.

The original VCL project remains the source of truth. Generated output is written to a separate folder and should always be compiled, reviewed, and tested before use.

## Quick links

- [Local project website](index.html)
- [Downloads and documentation](downloads.html)
- [Navigator User Guide](docs/pdf/VCL2FMXConverter_v6_0_Navigator_User_Guide.pdf)
- [Navigator Engineering Guide](docs/pdf/VCL2FMXConverter_v6_0_Navigator_Engineering_Guide.pdf)
- [Rules, Component, Property, and Event Maps](docs/pdf/VCL2FMXConverter_v6_0_Navigator_Rules_Component_Property_Event_Maps.pdf)
- [Converter Runtime Flow](docs/pdf/VCL2FMXConverter_v6_0_Navigator_Converter_Runtime_Flow.pdf)

## Highlights in v6.0 Navigator

- Designer-owned Navigator workspace with a per-iteration build identity
- Pascal, DFM, and Delphi project analysis
- FMX project, form, and source generation
- Component, property, and event mapping
- Compatibility, autofix, LiveBindings, and runtime-normalization passes
- Data-aware, WinAPI, Windows-message, GDI, and third-party review support
- Deterministic text, HTML, and `vcl2fmx.report.v1` JSON reports from one report model
- 22 schema-validated JSON mapping packs containing 493 disciplined rules
- Mapping-gap export as a valid starter mapping pack
- 227 executable conversion contracts, including compilation of eligible generated fixtures
- 66 regression guards and 63 release-readiness acceptance checks
- Complete Navigator user and engineering guides with companion PDFs

## Requirements

- Windows
- Embarcadero Delphi/RAD Studio with FireMonkey support
- Delphi 12 or later; the current project is built with Delphi 13.1. Very old Delphi projects, such as Delphi 3-era source, may need manual modernization before conversion.

The primary project file is `VCL2FMXConverter.dproj`, and the program entry point is `VCL2FMXConverter.dpr`.

## Build

### RAD Studio

Open `VCL2FMXConverter.dproj`, select a Windows target and configuration, then build or run the project normally.

### Command line

From a RAD Studio command prompt:

```bat
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
msbuild VCL2FMXConverter.dproj /t:Build /p:Config=Release /p:Platform=Win32
```

Generated binaries and compiler output are intentionally excluded from Git.

## Basic conversion workflow

1. Back up the original VCL project.
2. Build and start VCL2FMXConverter.
3. Select the source project and a separate output folder.
4. Choose the required conversion rules and run the conversion.
5. Read the generated HTML report.
6. Open the generated FMX project in Delphi, compile it, and test real workflows.

VCL and FMX use different rendering, event, focus, platform, and component models. A successful conversion is a strong migration starting point, not a guarantee of identical runtime behavior.

## Validation

The repository includes focused conversion contracts and broader regression checks. Run these from PowerShell:

```powershell
.\tools\run_conversion_contracts.ps1 -ProjectRoot . -EnforceCoverage -CompileGenerated
.\tools\run_regression_guards.ps1 -ProjectRoot . -FailOnBlockers
.\tools\run_release_readiness_audit.ps1 -ProjectRoot . -FailOnBlockers
```

The contract runner builds its local test harness as needed. Generated test output and executables remain ignored.

## Repository layout

```text
.
|-- VCL2FMXConverter.dpr / .dproj   Main Delphi project and entry point
|-- MainForm.pas / .fmx             Editable FireMonkey main form
|-- Converter.*.pas                 Converter engine, parser, mapper, and rewrite units
|-- contracts/                      Executable conversion fixtures and expectations
|-- mapping_packs/                  Editable JSON rules for third-party components
|-- samples/                        Focused sample projects and payloads
|-- tests/                          Regression fixtures and expected output
|-- tools/                          Build, test, audit, packaging, and documentation tools
|-- docs/guides/                    Editable Word and HTML documentation sources
|-- docs/pdf/                       Companion PDF documentation
|-- docs/Help/                      Help Doc Creator-compatible help content
|-- assets/                         Website stylesheet and branding assets
|-- index.html / downloads.html     Local static website
|-- CONTRIBUTING.md                 Contribution workflow
|-- SECURITY.md                     Private vulnerability reporting guidance
|-- LICENSE                         Apache License 2.0
|-- .gitignore                      Generated and local-only exclusions
`-- .gitattributes                  Text and binary handling rules
```

## Repository hygiene

The repository excludes Delphi build output, IDE-local state, recovery folders, generated source-distribution archives, local databases, logs, Office lock files, and temporary files. Release ZIP files belong in GitHub Releases rather than in Git history.

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md) before proposing code, mapping-pack, test, or documentation changes. Report security-sensitive issues privately as described in [SECURITY.md](SECURITY.md).

## License

VCL2FMXConverter is licensed under the [Apache License, Version 2.0](LICENSE).

Copyright (c) 2026 Tommy Martin.
