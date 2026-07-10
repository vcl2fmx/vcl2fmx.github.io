# V3 Packaging And Distribution Audit

Date: 2026-04-12
Roadmap item: `#2` Packaging/distribution audit and cleanup
Status: Completed

## Scope

This audit reviewed the live V3 converter tree for packaging and distribution consistency across:

- project metadata
- version markers
- document outputs
- guide graphics
- release-facing file naming

## Original Findings

### 1. Project packaging contained hardcoded local logo paths

File: `VCL2FMXConverter.dproj`

Original problem:

- `UWP_DelphiLogo44` pointed to `C:\Downloads\vcl2fmx.png`
- `UWP_DelphiLogo150` pointed to `C:\Downloads\vcl2fmx.png`
- deployment entry at line `197` also pointed to `C:\Downloads\vcl2fmx.png`

Resolution:

- Restored the logo properties to generic `$(BDS)` default UWP artwork paths.
- Removed the custom deployment entry that referenced the local `C:\Downloads` file.

### 2. Project version metadata was internally inconsistent

File: `VCL2FMXConverter.dproj`

Original problem:

- `VerInfo_Keys` reported `FileVersion=3.0.0.0` and `ProductVersion=3.0.0.0`
- `VerInfo_MajorVer` still reported `2`

Resolution:

- Updated `VerInfo_MajorVer` to `3` so the V3 metadata is internally consistent.

### 3. Live guide outputs were still stored under V2-style names

Original problem:

- live guide DOCX files used `2_0` naming
- live PDF outputs used `v2_0` naming

Resolution:

- Renamed the live guide DOCX outputs to non-versioned release-facing names.
- Renamed the live PDF outputs to non-versioned release-facing names.

### 4. Guide build paths and actual guide files did not line up

File: `tools\doc_paths.ps1`

Original problem:

- `doc_paths.ps1` expected generic guide output names
- the live files on disk still used older V2-style names

Resolution:

- Brought the live guide filenames into alignment with the build helper paths.
- Updated the guide graphic path variables to the new non-versioned SVG names.

### 5. Guide graphics still carried V2 naming and visible V2 text

Original problem:

- both SVG filenames still used `v2_0`
- both SVG files still rendered visible `v2.0` text

Resolution:

- Renamed both guide graphic SVGs to non-versioned names.
- Updated the visible title text in both graphics from `v2.0` to `v3.0`.

### 6. OldDocs remained inside the live guides tree

Original problem:

- `docs\guides\OldDocs` was still inside the release-facing guides area

Resolution:

- Moved `OldDocs` to `docs\archive\OldDocs` so historical documents no longer sit in the live guides folder.

### 7. Older release zips in `docs\Distribution Zip Files` must not be repackaged

Original problem:

- previously built release archives can sit inside `docs\Distribution Zip Files`
- those older zips are historical release outputs, not source content for the next public package

Resolution:

- the source-distribution build script now excludes `docs\Distribution Zip Files` from future source-release zips
- release packaging should always be built fresh from the live V3 tree, not by redistributing an older zip stored inside the workspace

## Result

The packaging/distribution cleanup completed successfully.

Current release-facing improvements now in place:

1. `VCL2FMXConverter.dproj` no longer contains the hardcoded `C:\Downloads\vcl2fmx.png` path.
2. The V3 project metadata now reports a consistent major version.
3. Live guide DOCX and PDF outputs now use cleaner non-versioned names.
4. Guide graphics now use non-versioned filenames and display `v3.0`.
5. Historical docs were moved out of the live guides folder into `docs\archive`.
6. Older release zips stored in `docs\Distribution Zip Files` are now treated as historical packaging artifacts and are excluded from future source-distribution builds.

## Relationship To Release Audit

This audit complements the release-readiness audit in `docs\notes\release_audits`.

- The release audit is the blocker scan.
- This packaging audit was the consistency and presentation scan.

After this cleanup pass, the release-readiness blocker count dropped from `6` to `3`.
The remaining blockers are IDE artifacts and the `Win32` build-output directory.
