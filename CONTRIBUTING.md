# Contributing to VCL2FMXConverter

Thank you for helping improve VCL2FMXConverter. Changes should be general enough to help multiple Delphi projects and conservative enough to avoid silently changing unsupported behavior.

## Before starting

- Search existing issues and documentation for the behavior.
- Keep the original VCL project and generated FMX output in separate folders.
- Do not include proprietary source code, credentials, customer data, or third-party files without redistribution permission.
- Reduce a real-world problem to the smallest practical fixture before changing converter logic.

## Development environment

- Windows
- Delphi 12 or later with FireMonkey support
- Delphi 13.1 is the current development toolchain
- PowerShell for repository test and audit scripts

Open `VCL2FMXConverter.dproj` in RAD Studio to edit and build the application. The main form is stored in `MainForm.fmx` and remains editable in the IDE.

## Change workflow

1. Create a focused branch.
2. Add or update a contract, sample, or regression fixture that demonstrates the issue.
3. Make the smallest general converter change that solves the demonstrated pattern.
4. Run the focused test, then the full contract and regression checks.
5. Update the relevant guide or mapping reference when user-visible behavior changes.
6. Keep generated executables, DCUs, logs, output folders, Office lock files, and distribution archives out of the commit.

## Validation

```powershell
.\tools\run_conversion_contracts.ps1 -ProjectRoot .
.\tools\run_regression_guards.ps1 -ProjectRoot . -FailOnBlockers
.\tools\run_release_readiness_audit.ps1 -ProjectRoot . -FailOnBlockers
```

When a change affects generated Delphi projects, also open representative generated output in RAD Studio and test the affected runtime workflow.

## Mapping packs

Mapping-pack changes belong in `mapping_packs/`. Keep JSON valid, document approximations and manual-review behavior, and avoid claiming safe automatic conversion when a component needs redesign.

## Pull-request checklist

- The change addresses one clear problem or feature.
- New conversion behavior has a repeatable fixture or contract.
- Existing contracts and regression guards pass.
- User-facing behavior and limitations are documented.
- No generated, local, confidential, or licensed third-party artifacts are included accidentally.
