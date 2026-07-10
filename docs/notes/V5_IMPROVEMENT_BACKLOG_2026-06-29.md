# VCL2FMXConverter v5.0 Vanguard Improvement Backlog

Revision date: June 29, 2026

This note records the first five improvement-planning steps after the v5.0 Vanguard baseline. It is an inventory and prioritization note only. It does not authorize a code change by itself.

## 1. Baseline

Current baseline backup:

`D:\VCL2FMXConverterV5 Backup\VCL2FMXConverterV5_Baseline_2026-06-28_162413.zip`

Current source-distribution location:

`C:\New Delphi Projects\VCL2FMXConverterV5\Source Distributions`

Compile verification completed on June 29, 2026:

- `VCL2FMXConverter.dpr` compiled to `Win32\Release`.
- `tools\RunConversionEngine.dpr` compiled to `tools`.
- Full contract suite: 192 pass, 0 fail.
- Regression guards: 0 blockers, 0 warnings, 41 pass items.

## 2. Improvement Backlog

The next work should stay contract-first. Each automatic conversion improvement should start with a sample input and an expectation file, then the converter should be changed only enough to make that contract pass.

Candidate backlog:

1. Expand high-value VCL component/property mappings that repeatedly appear in real projects.
2. Reduce unnecessary manual-review noise where the converter already made a safe FMX choice.
3. Improve compile-blocker cleanup for leftover VCL image APIs and VCL-only property assignments.
4. Continue Windows-message conversion refinement, but keep unsafe behavior reported.
5. Add more DFM/FMXL fidelity checks for omitted event handlers, visual properties, and shape conversions.
6. Add mapping-pack authoring suggestions when a third-party component is detected but not mapped.
7. Improve report grouping so users can see blocking, warning, and manual-review counts without confusion.
8. Keep dry-run and real-run reports comparable by using the same issue-counting rules.

## 3. Current Contract Coverage

Current executable contract count: 192 expectations.

Coverage by contract area:

| Area | Expectations |
| --- | ---: |
| colors | 15 |
| comments_and_boundaries | 20 |
| components_and_events | 23 |
| data_aware | 8 |
| dfm_fidelity | 3 |
| dfm_pairs | 7 |
| dry_run_preview | 1 |
| encoding | 4 |
| graphics | 7 |
| include_analysis | 11 |
| livebindings | 6 |
| pascal_structure | 4 |
| project_files | 5 |
| project_integration | 6 |
| reporting | 4 |
| semantic_resolution | 2 |
| third_party | 4 |
| uses_clause | 22 |
| winapi_messages | 40 |

Best-covered areas:

- Windows message detection and reporting.
- Uses-clause cleanup.
- Component/event conversion basics.
- Comment and boundary protection.

Areas that are intentionally thinner and should be expanded:

- DFM/FMXL fidelity checks.
- Semantic resolution.
- Third-party mapping assistance.
- Dry-run preview behavior.
- Project integration behavior.

## 4. Real-World Report Mining

Reports reviewed:

- `C:\New Delphi Projects\Carillon7_2_4 - Portable - orig_FMX Output\VCL_to_FMX_Conversion_Report.txt`
- `C:\New Delphi Projects\RealTimeClock - FMX Output\VCL_to_FMX_Conversion_Report.txt`
- `C:\New Delphi Projects\GPS Control 1_20 - FMX Output\VCL_to_FMX_Conversion_Report.txt`

Repeated or useful findings:

| Project | Report Status | Notable Items |
| --- | --- | --- |
| Carillon legacy | Blocking issues present | Potential integer division on FMX size values |
| RealTimeClock | Blocking issues present | Unsupported `RoundedCorners`, VCL window buffering, leftover VCL `Picture` API |
| GPS Control | Manual review required | Unsupported `TEllipse.Shape`, VCL `TShape.Shape` assignment |

The current reports show that the converter is already reporting the risk categories, but several items are candidates for quieter or more automatic handling:

- `TEllipse.Shape` should usually be quiet because FMX `TEllipse` already represents the shape.
- VCL `TShape.Shape` assignment can often be reduced to a targeted review item rather than broad manual code review.
- FMX size math and `div` handling should stay contract-protected because it has caused real compile failures.
- VCL `Picture` API cleanup should be treated as a compile-readiness improvement.

## 5. Ranked Improvement Set

Priority 1: Compile-readiness fixes

- Add contracts for leftover VCL image APIs such as `Picture`, `Graphic`, `Bitmap`, and `Canvas` references in generated Pascal.
- Convert safe image-load/save/assign patterns to FMX equivalents.
- Report only when the source operation cannot be safely translated.

Priority 2: Noisy shape/property reporting

- Add contracts for `TShape.Shape`, `TEllipse.Shape`, `TRectangle.Shape`, and related VCL shape properties.
- Make already-correct FMX substitutions quieter.
- Keep warnings only when the visual result may differ.

Priority 3: DFM/FMXL fidelity expansion

- Add contracts for omitted event handlers, omitted visual properties, and child-object ordering.
- Treat lost event bindings as warnings or blockers depending on whether generated code still references the handler.

Priority 4: Third-party mapping assistance

- Add contracts for known-but-unmapped third-party controls.
- Emit mapping-pack suggestion data instead of only a generic unsupported-component warning.
- Preserve the existing mapping packs as the first source of truth.

Priority 5: Dry-run/report consistency

- Add contracts that compare dry-run and real-run issue totals for the same project.
- Keep issue-count rules identical unless the report clearly labels dry-run-only or real-run-only findings.

Stop point:

After these five planning steps, the next work should be selected explicitly before implementation begins.
