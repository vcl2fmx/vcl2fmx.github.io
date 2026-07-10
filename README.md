# VCL2FMXConverter v5.0

VCL2FMXConverter v5.0 is a Delphi FireMonkey application for converting Delphi VCL projects toward FMX-style source, form, and project structures.

The project is intended for Delphi developers who need help modernizing VCL applications, reviewing conversion gaps, and generating FMX-oriented output while preserving the original project as the source of truth.

## Features

- VCL project and source parsing
- DFM and Pascal analysis
- Component mapping support
- FMX project generation helpers
- Compatibility rewrite and autofix passes
- LiveBindings and runtime-normalization support
- Advanced handling for data-aware controls, WinAPI usage, critical areas, and selected third-party patterns
- Sample projects, mapping packs, contracts, tools, tests, and documentation included in the repository

## Project Type

This is a Delphi FireMonkey (FMX) desktop application.

Primary project file:

```text
VCL2FMXConverter.dproj
```

Program entry point:

```text
VCL2FMXConverter.dpr
```

## Build Requirements

- Windows
- Embarcadero Delphi / RAD Studio with FireMonkey support
- The project is configured with Windows build targets including Win32 and Win64

Open `VCL2FMXConverter.dproj` in RAD Studio, select the desired Windows target, and build the project.

## Repository Layout

```text
.
??? VCL2FMXConverter.dpr / .dproj   Main Delphi project files
??? MainForm.pas / .fmx             Main application form
??? Converter.*.pas                 Converter engine, parser, mapper, rewrite, and generator units
??? src/                            Additional Delphi source organized by module
??? contracts/                      Schema/contracts used by converter workflows
??? mapping_packs/                  Component mapping data
??? samples/                        Sample projects and payloads
??? tests/                          Test and regression assets
??? tools/                          Build, test, and maintenance scripts
??? docs/                           Project documentation and branding assets
??? .gitignore                      Files intentionally excluded from Git
??? .gitattributes                  Git text/binary handling rules
```

## Files Not Included in Git

This repository intentionally excludes generated and local-only files such as:

- Delphi build output: `*.dcu`, `*.exe`, `Win32/`, `Win64/`, `Debug/`, `Release/`, `dcu/`
- Delphi local state: `*.local`, `*.identcache`, `__history/`, `__recovery/`
- Generated source distribution folders and archives
- Local databases, logs, and temporary files

## License

VCL2FMXConverter is licensed under the Apache License, Version 2.0. See the `LICENSE` file for details.

Copyright (c) Tommy Martin.

## Author

Tommy Martin
