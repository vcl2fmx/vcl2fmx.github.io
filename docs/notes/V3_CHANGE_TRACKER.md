# V3 Change Tracker

This file is the working record of converter-side changes made for V3.0.
It should be updated as meaningful V3 work is completed.
Target application projects may be inspected for diagnosis, but fixes belong in the converter.

## Current Focus

- Active roadmap item: `#24` stabilization phase
- Status: Roadmap items `#11`, `#13`, `#16`, and `#17` are complete, roadmap items `#18`, `#19`, `#20`, and `#21` now have safe pass-1 converter fixes in place, roadmap items `#22` and `#23` are deferred to keep V3 release risk lower, roadmap item `#24` is now active with stabilization pass 1 complete, roadmap item `#7` was intentionally skipped because sample-project regression harness code would not add product-wide value, roadmap item `#8` pass 1 is complete, and roadmap item `#5` was intentionally skipped to avoid sample-specific or local-path maintenance code in the converter.
- Latest release audit report: `docs\notes\release_audits\RELEASE_READINESS_AUDIT_2026-04-14_140105.txt`
- Latest packaging audit report: `docs\notes\V3_PACKAGING_DISTRIBUTION_AUDIT_2026-04-12.md`
- Latest guide refresh script: `tools\refresh_v3_guides_2026_04_13.ps1`
- Latest regression guard report: `docs\notes\regression_guards\REGRESSION_GUARDS_2026-04-14_150639.txt`
- Latest source distribution script: `tools\build_source_distribution_zip.ps1`
- Latest verified source distribution zip: `E:\VCL2FMSV3 Backup\VCL2FMXConverter_v3_0_Source_Distribution_2026-04-13_144757.zip`

## Completed Changes

### 2026-04-12

1. Versioning and release cleanup
- Updated version markers from `2.0.1` to `3.0` in `MainForm.fmx` and `VCL2FMXConverter.dproj`.
- Aligned live rules-reference wording in `tools\build_generic_rules_reference_html.ps1` and the generated HTML snapshot.
- Removed the stray `grid_binding_debug.log` artifact from the live tree.

2. File scanning and engine flow
- Switched `Converter.Core.FileManager.pas` to streaming incremental enumeration.
- Added deterministic sorting and exposed `FileCount`.
- Updated `Converter.Core.Engine.pas` to use `FileCount` instead of resetting and rescanning just to total files.

3. Main form reference-page cleanup and UI background refresh
- Extracted shared page-shell helpers in `MainForm.pas` for component/property/event mapping pages.
- Replaced the hero circle/orb background accents in `MainForm.fmx` with diagonal ribbon accents while keeping the same blue base color.
- Updated `MainForm.pas` component fields from `HeroOrbLarge` and `HeroOrbSmall` to `HeroAccentRibbonLarge` and `HeroAccentRibbonSmall`.

4. Integration refactor and stability fixes
- Extracted helper passes from `Converter.Core.Integration.pas`, including `FixMalformedFieldEndings`, `MarkUnsupportedPascalRoutinesForReview`, `HandleTrayStartupRewrite`, `RewriteCanvasGeometryLine`, and `RestoreNonUnsupportedManualReviewSignatures`.
- Added supporting typed-member and declared-type discovery helpers used by `ApplyAutomaticFixes`.
- Fixed unsupported-routine depth tracking so a manual-review message handler does not swallow later valid methods in generated units.

5. Mapper and data-aware architecture work
- Added a normalized class-name index and derived-match cache in `Converter.Mapper.Component.pas`.
- Made `FindBestMatch` pure/cached and added side-effecting `EnsureBestMatch` for callers that intentionally mutate/log.
- Updated mapper resolution paths and `Converter.Parser.DFM.pas` call sites to use `EnsureBestMatch` where appropriate.
- Replaced substring-based class detection in `Converter.Advanced.DataAware.pas` with normalized class matching and mapper-backed ancestry checks where available.

6. Compile-restoration fixes
- Removed the duplicated `AddUniqueString` declaration in `Converter.Mapper.Component.pas` that caused parser-cascade compile errors.
- Restored design-time field/component alignment after the main-form background rename so the converter compiles and opens cleanly.

7. Release-readiness guardrail foundation (`#1` complete)
- Added `tools\run_release_readiness_audit.ps1`.
- The audit currently checks for IDE artifacts, build-output directories, local absolute path references, and debug leftovers.
- Verified that `-FailOnBlockers` works as a real release gate.

8. Packaging/distribution audit (`#2` audit complete)
- Added `docs\notes\V3_PACKAGING_DISTRIBUTION_AUDIT_2026-04-12.md`.
- Recorded the packaging inconsistencies across project metadata, version fields, guide outputs, guide graphics, and release-facing file naming.

9. Packaging/distribution cleanup (`#2` fix pass complete)
- Normalized `VCL2FMXConverter.dproj` by removing the hardcoded `C:\Downloads\vcl2fmx.png` usage and restoring generic UWP logo paths.
- Updated the V3 project metadata so `VerInfo_MajorVer` is now `3`.
- Renamed live guide DOCX outputs, guide graphics, and PDF outputs to cleaner non-versioned names.
- Updated guide graphics so they now display `v3.0`.
- Moved `docs\guides\OldDocs` to `docs\archive\OldDocs`.
- Verified the release audit blocker count dropped from `6` to `3`.

10. Documentation refresh (`#3` complete)
- Updated the guide source scripts so future rebuilds use current live `v3.0` wording for the UI, mapping-reference pages, and options-container behavior.
- Added a release-readiness audit note to the engineering guide source.
- Created `tools\refresh_v3_guides_2026_04_12.ps1` to refresh the live guide `.docx` files in place through Word automation while preserving formatting, graphics, and layout.
- Refreshed the live User Guide and Engineering Guide successfully and verified the updated wording inside the `.docx` package XML.

### 2026-04-13

11. Warning/reporting output improvements (`#4` pass 1 complete)
- Updated `Converter.Core.Engine.pas` so text and HTML reports now show clearer status wording, a recommended next step, files needing attention, and files with conversion errors.
- Added shared filtering inside `GenerateReport` so actionable detailed issues and grouped manual-review output use the same inclusion logic.
- Upgraded file-conversion, Pascal-conversion, DFM-conversion, and fatal-session issue records to include problem types, recommendations, and blocking flags where appropriate.
- Updated completion messaging in `Converter.Core.Engine.pas` and `MainForm.pas` so the UI status and summary text now point the operator toward the next action.
- Improved `Converter.Project.Generator.pas` messages for external asset references and companion-file copy warnings so they explain what was skipped and what to do next.

12. Generic regression guards for recent refactors (`#6` pass 1 complete)
- Added `tools\run_regression_guards.ps1` as a maintainer-only source audit for recent converter refactors with no sample-project or local-path dependencies.
- The guard checks mapper lookup purity/caching boundaries, DFM parser use of `EnsureBestMatch`, normalized data-aware class matching, integration helper wiring, streaming file enumeration, and report/UI wording markers.
- The initial run produced `docs\notes\regression_guards\REGRESSION_GUARDS_2026-04-13_090545.txt` with `0` blockers, `0` warnings, and `22` pass items.
- Roadmap item `#5` was intentionally skipped because sample-specific validation machinery was not aligned with product-wide value and would have added maintainer clutter without improving shipped conversion behavior.

13. Licensing/distribution coverage for V3 downloads
- Added root `LICENSE.txt` with the live website licensing coverage notice plus the full Apache 2.0 license text.
- Added `tools\build_source_distribution_zip.ps1` so future V3 source distribution zips are built from a clean staged copy that includes `LICENSE.txt` and excludes IDE/build artifacts.
- Updated `tools\run_release_readiness_audit.ps1` so a missing root `LICENSE.txt` is treated as a release blocker.
- Verified the clean source distribution zip `E:\VCL2FMSV3 Backup\VCL2FMXConverter_v3_0_Source_Distribution_2026-04-13_144757.zip` contains `VCL2FMXConverterV3\LICENSE.txt`.

14. Generated-output compile-quality checks (`#8` pass 1 complete)
- Extended `Converter.Core.Engine.pas` output auditing so generated Pascal now flags leftover `Vcl.*` unit references, leftover `{$R *.DFM}` directives, VCL-style `message` method declarations, and generated Pascal files that do not end with `end.`.
- Kept this pass converter-only by reusing the existing generated-output audit/report path instead of adding any runtime code to converted projects.

15. Mapper cache invalidation and purity boundary audit (`#11` complete)
- Added `RegisterResolvedMapping` in `Converter.Mapper.Component.pas` so persisted best-match promotion now flows through one mapper mutation path instead of open-coded cache/index updates.
- Tightened mapper cache invalidation so any material mapping-database change clears all derived pure-lookup cache entries, preventing stale cached best matches after persisted mappings are added.
- Removed redundant open-coded lookup-cache clearing from `LoadMappings` and kept the rebuild path as the single post-load index/cache reset.

16. Manual-review tagging precision (`#13` complete)
- Added `IsUnsupportedMessageHandlerSignature` in `Converter.Core.Integration.pas` so message-handler tagging now keys off explicit signature patterns instead of broad string checks.
- Reused that helper in both `MarkUnsupportedPascalRoutinesForReview` and `RestoreNonUnsupportedManualReviewSignatures` so tagging and signature restoration follow the same unsupported-routine rules.
- Removed dead navigator-state branches from the unsupported-routine state machine to keep manual-review tagging narrower and easier to reason about.

17. Generated-code de-bloat (`#16` complete)
- Reduced generated setup noise in `Converter.Core.Integration.pas` by removing runtime-only `Stored := False;` emissions for generated columns, panels, edits, labels, and the generated startup timer.
- Removed the redundant generated `ClearColumns;` line from the grid-column creation block when columns are only emitted for an empty grid.
- Kept this pass behavior-neutral by trimming only lines that do not change runtime behavior for code-created controls.

18. Reference tab stability fix
- Fixed the property/event mapping reference path in `Converter.Mapper.Component.pas` by returning `ResolvePropertyMapping` and `ResolveEventMapping` to the pure `FindBestMatch` lookup path.
- This prevents the property/event reference tabs from invalidating a cached mapping object mid-build when those pages resolve rules for display, which was causing IDE-time access violations in the Property Mapping and Event Mapping tabs.

19. DPR startup transformation hardening (`#17` complete)
- Broke `Converter.Project.Generator.pas` DPR startup handling into named helper routines for startup-line normalization, `Application.Run` discovery, splash-sequence detection, and immediate `CreateForm`/`Show` cleanup.
- Kept the existing startup conversion behavior while making the splash/deferred-create path smaller and easier to reason about.

20. Lifecycle shutdown handler preservation (`#18` pass 1 complete)
- Updated `Converter.Core.Integration.pas` so generated cleanup now preserves and chains an existing form `OnDestroy` handler when the converter has to inject a generated destroy wrapper.
- The generated wrapper now runs FMX cleanup first, then calls the original `OnDestroy` handler instead of skipping cleanup whenever a project already assigned `OnDestroy`.

21. Data-aware calc-field handler preservation (`#19` pass 1 complete)
- Updated `Converter.Core.Integration.pas` so generated grid display-field support now preserves and chains an existing dataset `OnCalcFields` handler instead of only wiring the generated handler when no prior handler existed.
- Added cleanup restoration for externally owned datasets so generated `OnCalcFields` wrapping does not leave a dead form handler attached after shutdown.

22. Grid AfterOpen handler preservation (`#20` pass 1 complete)
- Updated `Converter.Core.Integration.pas` so generated grid refresh now preserves and chains an existing dataset `AfterOpen` handler instead of skipping the generated refresh hook whenever a project already assigned `AfterOpen`.
- Added cleanup restoration for externally owned datasets so generated `AfterOpen` wrapping does not leave a dead form handler attached after shutdown.

23. WinAPI manual-review degradation hardening (`#21` pass 1 complete)
- Updated `Converter.Advanced.WinAPI.pas` so Windows file APIs now flow through the existing downgrade path instead of being left half-live in generated FMX code.
- Updated the process/thread/sync downgrade path so unsupported WinAPI calls are converted into explicit FMX manual-review comments with the original code preserved underneath.

24. Stabilization pass 1 (`#24` in progress)
- Deferred roadmap items `#22` and `#23` to keep V3 release risk lower and avoid late deep refactors in the highest-risk converter unit.
- Removed the remaining live-tree release blockers: `VCL2FMXConverter.dproj.local`, `VCL2FMXConverter.identcache`, and `Win32`.
- Reran the release-readiness audit and reached a clean baseline with `0` blockers, `0` warnings, and `0` info items.
- Reran the regression guards and aligned the mapper mutation assertion with the current `RegisterResolvedMapping` helper-based implementation, restoring a clean `0` blocker / `0` warning baseline.

25. Guide text refresh after stabilization work
- Updated `tools\build_user_guide_docx.ps1` so the user guide now explains the current v3.0 run-status wording and report metrics more clearly.
- Updated `tools\build_engineering_guide_docx.ps1` so the engineering guide now reflects the release-readiness audit, regression guards, handler-preservation work in integration, normalized data-aware class matching, and the smaller-helper DPR startup transformation.
- Added `tools\refresh_v3_guides_2026_04_13.ps1` and refreshed the live guide `.docx` files in place through Word automation without rebuilding the TOC, preserving existing formatting, graphics, arrows, and layout.

26. Pascal conversion crash hardening during data-aware prep
- Hardened `Converter.Advanced.DataAware.pas` recursive DFM walkers and DBGrid column scanning against nil component, child, and collection-item entries during pre-conversion binding analysis.
- Updated `PrepareFormDataBindings` in `Converter.Core.Integration.pas` to clear partial data-binding and grid-handler state if DFM-backed binding preparation fails, preventing a prepass exception from cascading into a later Pascal conversion access violation.

27. Playlist Pascal conversion regression fix
- Identified a same-day stabilization regression in `Converter.Core.Integration.pas`: the new `OriginalAfterOpenHandlerFields` dictionary used by generated grid `AfterOpen` preservation code was declared and later freed, but was never created.
- Added the missing dictionary initialization in `InjectLiveBindings`, which should stop DBGrid/data-aware forms like `Playlist.pas` from failing Pascal conversion with an immediate nil-object access violation in the generated `AfterOpen` preservation path.

28. Project metadata asset import fix
- Updated `Converter.Project.Generator.pas` so rooted or out-of-tree asset references found in generated project metadata are copied into the FMX output tree and rewritten to shipped relative paths instead of being left as external-machine references.
- The generated `.dproj` and `.deployproj` files now rewrite supported asset references to the imported FMX output path, while the companion-file scan falls back to a warning only when an asset still cannot be staged.
29. Converter build compatibility and false-positive manual-review fix
- Updated Converter.Project.Generator.pas so source-relative asset rewriting now uses ExtractRelativePath and a Delphi-compatible StringReplace(...) form instead of APIs/signatures unsupported by this compiler version.
- Updated Converter.Core.Integration.pas so unsupported-signature detection only carries context onto the next line when a declaration truly continues, which stops ordinary methods like AssignSeasonalGroupToSelectedRows from being wrongly commented out as FMX manual review when followed by a message-handler declaration.








36. Companion executable copy and report-warning dedup
- Updated Converter.Project.Generator.pas so the project companion-file pass now deduplicates repeated missing-asset warnings before they reach the report, preventing identical rows from inflating warning totals.
- Added a narrow runtime-companion scan over source Pascal units so referenced executables such as fmpeg.exe are discovered and copied from the source tree into the FMX output when present.
- This specifically covers Windows helper executables stored under the source project tree, such as SpeechEndFlagger\Win32\Debug\ffmpeg.exe, without patching target-app code.

37. Generator compile-compatibility fix for companion executable staging
- Corrected the new companion-file pass in Converter.Project.Generator.pas so it now uses Delphi-compatible indexed loops instead of unsupported `for..in` control flow over the executable candidate lists.
- Reworked the pass to use a valid nested `try/except` inside an outer `try/finally`, fixing the compiler errors introduced by the previous invalid `except/finally` structure while preserving the same warning/copy behavior.




## Current Known Release Blockers

Based on `docs\notes\release_audits\RELEASE_READINESS_AUDIT_2026-04-14_140105.txt`:

- None.

## Backup Milestones

- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_pre-continue_2026-04-12_130241`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_compile-restored_2026-04-12_144719`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_2026-04-12_170303.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_release-guardrails-complete_2026-04-12_211508.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_packaging-audit-complete_2026-04-12_212048.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_packaging-cleanup-complete_2026-04-12_212625.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_documentation-refresh-complete_2026-04-12_213812.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_warning-reporting-pass1_2026-04-13_082218.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_regression-guards-pass1_2026-04-13_090654.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_license-distribution-complete_2026-04-13_144910.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_compile-quality-checks-pass1_2026-04-13_180928.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_mapper-cache-audit-complete_2026-04-13_181734.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_manual-review-tagging-complete_2026-04-13_182316.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_generated-code-debloat-complete_2026-04-13_194130.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_reference-tab-stability-fix_2026-04-13_194732.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_dpr-lifecycle-dataaware-pass_2026-04-13_200351.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_grid-winapi-pass_2026-04-13_201427.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_stabilization-pass1_2026-04-13_202150.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_guides-refresh_2026-04-13_203248.zip`

- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_playlist-pascal-crash-fix_2026-04-13_204703.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_playlist-afteropen-init-fix_2026-04-13_211509.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_project-asset-import-fix_2026-04-13_213443.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_generator-manualreview-fixes_2026-04-13_215136.zip`

- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_pre-rollback_2026-04-14_135740.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_folder-picker-simple-fix_2026-04-14_142500.zip`
- `E:\VCL2FMSV3 Backup\VCL2FMXConverterV3_generator-compilefix_2026-04-14_150639.zip`

## Tracking Rule

- Update this file whenever a meaningful converter-side change is made for V3.
- Prefer short, factual entries over long narrative notes.
- Keep target-app observations out unless they directly explain a converter fix.
- For converter patches affecting VCL/FMX APIs, events, or properties, check official Embarcadero documentation first and record the result instead of patching from assumption.

## 2026-04-14

- Added `docs\notes\CONVERTER_PATCH_GUARDRAILS_2026-04-14.md` to require Embarcadero DocWiki review before future API/event/property converter patches.
- Kept FMX `TForm.OnDblClick` out of generated `.fmx` files and added a generated FMX form mouse-up adapter so documented FMX form mouse events can preserve VCL root-form double-click behavior such as `frmClock.FormDblClick`.
- Consulted Embarcadero DocWiki pages for this fix: `FMX.Forms.TForm_Events`, `FMX.Forms.TCommonCustomForm_Events`, and `FMX.Forms.TFrame.OnDblClick`.
- Corrected the new root-form double-click helper to use Delphi-safe `while` loop searches instead of mutating a `for` loop variable, fixing the converter compile error in `Converter.Core.Integration.pas`.
- Moved the root-form double-click rewrite to the final Pascal stage so later parser/integration passes do not misplace the generated `OnMouseUp` hookup above method `var` blocks.
- Updated numeric math cleanup so documented FMX `Single` targets such as `Font.Size` and `Position.X/.Y` no longer keep VCL-style `div` expressions in generated Pascal.
- Consulted Embarcadero DocWiki pages for the numeric math cleanup: `FMX.Controls.TControl.Width`, `FMX.Controls.TControl.Height`, and `API:FMX.Types.TPosition_Properties`.
- Corrected the numeric math cleanup so float-target `div` rewrites rebuild the full assignment line instead of only changing the right-hand side in memory.
- Replaced the fragile line-index insertion for generated root-form double-click hookup with a full `FormCreate` body rewrite so the generated `OnMouseUp` hookup is inserted after `begin`, not above local `var` sections.
- Reworked root-form double-click conversion again so it no longer patches `FormCreate` at all: root VCL `OnDblClick` now converts to a generated FMX `OnMouseUp` adapter method, which keeps the generated Pascal cleaner and avoids illegal method-body insertion.
- Corrected root-form `OnMouseMove` handling after reviewing Embarcadero DocWiki: FMX forms do support `OnMouseMove`, so the converter now keeps that event live and rewrites the generated handler signature from VCL `Integer` coordinates to FMX `Single` coordinates.
- Consulted Embarcadero DocWiki pages for this root-form event correction: `FMX.Forms.TForm.OnMouseMove`, `FMX.Forms.TCommonCustomForm.OnMouseMove`, `FMX.Forms.TForm_Events`, and `System.Classes.TThread.Queue`.
- Corrected the generated FMX root-form `OnMouseUp` adapter declaration after runtime testing: the adapter now stays in the form's streamed event-method section instead of `private`, so FMX form loading can resolve `GeneratedRootFormMouseUpDblClick` successfully.
- Consulted Embarcadero documentation on RTTI/method lookup for this runtime correction: the streaming system uses `TObject.MethodAddress`, so streamed event handlers must remain discoverable by name at load time.











- Corrected VCL label autosize preservation for FMX conversion: centered/right-justified `TLabel` controls now keep the VCL default autosize behavior unless the source explicitly disables it, preventing fixed-width FMX labels like `lblClock` from stretching and truncating dynamically centered text.
- Consulted Embarcadero DocWiki for this layout fix: VCL `TLabel.AutoSize` defaults to True, while FMX `TLabel.AutoSize` defaults to False, so VCL default behavior must be preserved explicitly during conversion.
- Corrected FMX anchoring for auto-sized VCL labels: the converter now omits inherited VCL anchor sets on auto-sized labels so FMX does not stretch centered text controls like the RealTimeClock date label when the form is maximized.
- Consulted Embarcadero DocWiki for this layout fix: FMX `TControl.Anchors` stretches controls when opposite edges are anchored, so auto-sized labels must keep the default FMX anchors instead of preserving all-sides VCL anchors.
- Corrected direct FMX font-size rewrites in generated Pascal: VCL-style `Control.Font.Size := ...` assignments now convert through a helper that clears `TStyledSetting.Size` before setting the FMX text size, preventing runtime size changes from being ignored on labels such as `lblWind`.
- Consulted Embarcadero DocWiki for this runtime text fix: FMX `StyledSettings` can cause `TextSettings.Font.Size` values to be ignored while `Size` remains style-controlled.
- Preserved VCL `Font.Style` during FMX text conversion so headings like the RealTimeClock date/time labels keep bold styling instead of falling back to the FMX styled default weight.
- Applied VCL label autosize preservation even when the source label has no explicit font properties, so runtime-sized labels like `lblWind` now receive the same FMX auto-size/word-wrap setup as the other weather labels.
- Added an FMX text-height sync helper for runtime font-size rewrites: when the converter updates an auto-sized single-line text control's font size in generated Pascal, it now also restores a VCL-like control height so layout code that depends on `Label.Height` preserves the original vertical spacing more closely.
- Consulted Embarcadero DocWiki for this spacing fix: FMX `TLabel.AutoSize` with `WordWrap=False` expands width but not height, unlike the VCL behavior this project depends on for vertical layout calculations.
- Corrected the compile break in `Converter.Core.Integration.pas` from the new spacing helper: the generated helper now uses fully qualified `TypInfo` calls instead of relying on an out-of-scope `EnsureUsesUnit` call in the converter source.
- Corrected generated helper references for the RealTimeClock spacing pass: the FMX runtime helper now calls `System.TypInfo.IsPublishedProp` and `System.TypInfo.GetOrdProp` explicitly instead of emitting unresolved bare `TypInfo` identifiers.
- Simplified the RealTimeClock spacing helper to a direct FMX `TLabel` path instead of RTTI-based `TypInfo` calls, removing the generated-app compile errors while keeping the label-height spacing correction.
- Replaced generic FMX label-height inflation with a targeted runtime-layout rewrite for converted VCL text stacking math: when generated Pascal positions controls using `PreviousLabel.Height` in vertical `Top` / `Position.Y` assignments, the converter now substitutes a helper that uses each source label's original VCL height-to-font ratio from the DFM, preserving spacing without changing unrelated FMX label behavior.
- Consulted Embarcadero DocWiki for this runtime-layout fix: FMX font sizes are point-based while VCL label layout math depends on control heights, so the converter now translates VCL-style label stacking using source DFM text metrics rather than trusting raw FMX auto-size height.
- Expanded the folder-picker dialog rewrite for VCL `TFileOpenDialog` controls using `fdoPickFolders`: generated FMX browse handlers now also rewrite wrapped assignments like `NormalizeDir(dlgFolder.FileName)` instead of only the bare `Target := dlgFolder.FileName` pattern, so directory-oriented apps keep using `SelectDirectory` correctly.
- Consulted Embarcadero DocWiki for this folder-dialog fix: FMX directory picking should use `FMX.Dialogs.SelectDirectory`, while VCL source projects may still normalize or wrap the selected path before storing it.
- Preserved Windows serial-port `CreateFile(...)` opens in generated FMX output when the converter can see serial-device indicators such as `PortPath`, `ComPort`, `SerialPort`, or a `\\.\` device path, preventing COM-port reader apps from losing their handle-open call while still leaving ordinary file `CreateFile` uses under manual review.
- Consulted Embarcadero documentation for this serial fix: RAD Studio does not provide built-in serial communication support, so valid Windows serial API usage must remain available in Windows-targeted FMX conversions instead of being blanket-downgraded.
- Stopped converting RTL `TCriticalSection` declarations and instance usage into FMX manual-review comments; the converter now only flags raw WinAPI `EnterCriticalSection` / `LeaveCriticalSection` calls, preserving valid `System.SyncObjs.TCriticalSection` code in generated output.
- Consulted Embarcadero DocWiki for this synchronization fix: `System.SyncObjs.TCriticalSection` is a supported RTL synchronization class and should remain live in FMX projects rather than being commented out.
- Expanded Windows process-call preservation for FMX output to keep `TerminateProcess` and `GetExitCodeProcess` live alongside `CreateProcess` and `WaitForSingleObject`, avoiding partial process-runner breakage in Windows-targeted converted apps.
- Consulted official API documentation for this process fix: these WinAPI process-control calls remain valid for Windows-targeted applications and should not be blanket-downgraded when the converter is preserving the rest of the same process pipeline.
- Suppressed code-side `TFileOpenDialog.Options` assignments containing `fdoPickFolders` once a source dialog is being converted through the generated FMX folder-picker helper, preventing unsupported `fdo...` constants from leaking into FMX Pascal after folder selection has already been adapted to `SelectDirectory`.
- Consulted Embarcadero DocWiki for this dialog-options fix: `fdoPickFolders` is a VCL `TFileOpenDialog` option, while the FMX folder-selection path is `FMX.Dialogs.SelectDirectory`, so those option assignments must not survive unchanged in generated FMX code.
- Preserved Windows named-pipe `CreateFile(...)` opens and `WriteFile(...)` calls in generated FMX output, preventing pipe-based utilities from losing their comm-resource open/write path while still leaving more ambiguous file APIs on manual review.
- Consulted Embarcadero and platform documentation for this pipe fix: RAD Studio exposes Windows comm-resource APIs through `Winapi.Windows`, and named pipes are valid Windows communication resources that should remain live in Windows-targeted FMX conversions instead of being downgraded like ordinary cross-platform file I/O.
- Qualified generated FMX `MessageDlg` button values with `TMsgDlgBtn.*` so single-button and explicit-button dialog calls no longer emit bare `mb...` identifiers that are invalid under the FMX/System.UITypes dialog API surface.
- Consulted Embarcadero DocWiki for this dialog-button fix: FMX `MessageDlg` consumes `TMsgDlgButtons = set of TMsgDlgBtn`, so generated button tokens must match the `System.UITypes.TMsgDlgBtn` enum rather than relying on VCL-style bare identifiers.
- Tightened the FMX `div` rewrite so it only converts integer division when the right-hand expression actually mixes in FMX float-backed operands such as `.Width`, `.Height`, `.Left`, `.Top`, `.Position.X/.Y`, `Font.Size`, or `Screen.Width/Height`; pure integer `div` math used for row/column indexing is now left untouched.
- Consulted Embarcadero DocWiki for this numeric fix: FMX control size/position and font-size properties are floating-point based, so mixed expressions like `(ScreenWidth - AForm.Width) div 2` must become real division, while integer-only layout math should preserve `div` semantics to avoid changing working conversions.
- Hardened the companion-file pass so referenced helper executables are selected deterministically, missing referenced executables now generate explicit warnings in the conversion report, and successfully staged executables generate explicit runtime-deployment notes instead of being copied silently.
- Expanded project companion reporting to scan the source tree for likely runtime support files such as `.dll`, `.lib`, and `.sf2`, then surface them as actionable report entries so release packaging can review what may need to ship beside the built executable or in a support folder.
- Corrected the companion support-file scan to use a Delphi-safe local indexed loop inside the nested generator routine, preventing the report enhancement from tripping `E1019 For loop control variable must be simple local variable` during converter compilation.
- Tightened companion-executable discovery so the report only flags explicit `.exe` references or real command-line starters such as `ffmpeg -...`, instead of overmatching ordinary quoted strings and inflating warning counts with fake missing-executable notices.
- Reworked companion-file reporting around actual file inventory instead of Pascal string guessing: the converter now scans the source root and existing build-output folders (`Win32`, `Win64`, `Debug`, `Release`, `deploy`) for `.exe`, `.dll`, `.lib`, and `.sf2` files, reports their real locations, and stages the best runtime candidates from those real file locations into the FMX output.
- Corrected the inventory-based runtime report so it excludes the primary project executable itself before generating report rows, preventing entries such as `Carillon.exe` from being listed as a runtime support file beside the existing built executable.
- Tightened the inventory-based companion report so files that are actually staged into the FMX output are no longer also listed separately as merely “found beside an existing built executable”; staged files now appear once, under the staged-runtime note, while unstaged support files continue to be reported by location.
- Corrected external `TDataSource.OnDataChange` cleanup in generated FMX binding code: when the converter wraps an existing datasource `OnDataChange` handler, shutdown now restores that original handler instead of forcing the external datasource back to `nil`.
- Preserved valid Windows `ShellExecute(...)` shell-launch calls in generated FMX output instead of downgrading them to comments, restoring help/document launch behavior for Windows-targeted FMX utilities while still leaving non-shell cross-platform concerns on the report path.
- Consulted Embarcadero documentation for this shell-launch fix: RAD Studio help guidance explicitly uses `ShellExecute` to open HTML Help and related documents, and the `Winapi` API documentation confirms Windows shell functionality is exposed through Delphi's Winapi units for Windows-targeted applications.
- Corrected `TDBEdit.Field.DisplayText` translation for FMX manual bindings: when source code explicitly refreshes an edit from its bound field's `DisplayText`, the converter now emits a generated helper that looks up the edit's registered manual binding and returns the real `TField.DisplayText` instead of degrading the code to `Edit.Text := Edit.Text`.
- Consulted Embarcadero documentation for this binding-display fix: `TField.DisplayText` is the value shown in a data-aware control and honors `OnGetText`, so converted FMX manual-binding refresh code must preserve `DisplayText` semantics rather than collapsing them to the edit's current text.
- Clarified the report metric wording from `Files needing attention` to `Distinct files needing attention` in the text and HTML reports so it is obvious this number counts unique files with issues, not hidden extra issue rows.
- Reworded staged companion reporting to say `Runtime companion staged into the FMX output directory:` so the report reads more plainly and matches the actual output location.
- Corrected generated navigator cleanup so externally owned/shared `TBindNavigator.BeforeAction` handlers are restored to their original value on form teardown instead of being left pointing at a generated wrapper method on a form that is being destroyed.
- Consulted Embarcadero documentation for this navigator cleanup fix: both VCL `TDBNavigator` and FMX `TBindNavigator` expose a `BeforeAction` event that fires before navigator button behavior, so when the converter temporarily replaces that handler it must restore the original one for shared external navigators during cleanup.
- Tightened `.dpr` splash-startup detection so the converter only rewrites a startup form as a splash sequence when the code actually looks like a deliberate splash block: the show/free sequence must complete before `Application.Run`, use only splash-style interim lines (`Sleep`, `Application.ProcessMessages`, `Application.HandleMessage`, or simple form refresh/update calls), and include real splash evidence such as a splash comment, splash-related class/instance name, or an explicit delay.
- Corrected generated combo binding setup so it no longer calls popup logic during form creation; FMX combo `OnPopup` handlers are now left to fire at actual popup time, while the generated sync still initializes the visible value from the bound field without forcing a startup popup side effect.
- Preserved and restored original combo popup-close behavior by saving `OnClosePopup`, routing it through a generated wrapper that still commits the selected value to the bound field, and restoring the original `OnChange`, `OnPopup`, and `OnClosePopup` handlers during cleanup for externally owned/shared combo controls.
- Consulted Embarcadero documentation for this combo fix: FMX `TComboBox.OnPopup` occurs just before the drop-down list appears, and `OnClosePopup` is the matching close event on the combo popup surface, so invoking popup logic during form setup is incorrect and original close-popup handlers must be preserved when the converter temporarily replaces them.
- Corrected generated timer cleanup so externally owned/shared timers with no form-owned source `OnTimer` handler now preserve and restore their original `OnTimer` callback during teardown instead of being forced to `nil`; timers that were explicitly wired to a form handler in the source still shut down by clearing `OnTimer` to avoid leaving dead form-method callbacks attached.
- Consulted Embarcadero documentation for this timer cleanup fix: both VCL and FMX `TTimer` components drive their periodic work through the `OnTimer` event, so shared timers should regain their pre-conversion callback after a converted form releases them, while timers that belong to the form's own event surface must still be detached during shutdown.
- Corrected generated toggle cleanup so externally owned/shared FMX check boxes and radio buttons now restore their original `OnClick` and `OnChange` handlers during teardown instead of forcing both events to `nil`; self-owned toggles still clear the generated handlers as part of normal form shutdown.
- Consulted Embarcadero documentation for this toggle cleanup fix: FMX toggle controls such as `TCheckBox` surface click and state-change behavior through `OnClick` and `OnChange`, so when the converter temporarily reroutes those callbacks it must restore the original handlers for shared external controls during cleanup.
- Aligned integration routine detection with the Pascal parser by teaching `TConversionOrchestrator.StartsRoutine` to recognize `constructor` and `destructor` declarations, preventing constructor/destructor methods from being treated differently than ordinary routines in integration passes that scan method boundaries and unsupported-handler regions.
- Consulted Embarcadero documentation for this routine-detection fix: Delphi constructors and destructors are first-class method declarations, so converter passes that detect routine starts must treat them consistently with procedures and functions.
- Corrected `ConvertMessageAPI` and `ConvertGDIAPI` so `SendMessage` and `InvalidateRect` downgrades no longer splice `// ...` fragments into live Pascal statements; those paths now replace the whole statement with multiline manual-review comments, avoiding invalid inline-comment output.
- Consulted Embarcadero documentation for this WinAPI inline-fix: Windows message handling and repaint behavior live in the `Winapi.Messages` and FMX control APIs, so when the converter cannot keep a call live it must emit a safe whole-line review block rather than corrupting the surrounding Pascal syntax.
- Corrected `AddPlatformConditionals` so it now wraps only the contiguous WinAPI review-comment block in a balanced `{$IFDEF MSWINDOWS}` ... `{$ENDIF}` pair and no longer inserts `{$ELSE}` around the next live Pascal statement, which previously risked structurally invalid conditional blocks.
- Consulted Embarcadero documentation for this conditional-compilation fix: Delphi compiler directives such as `{$IFDEF}` and `{$ENDIF}` are comments with special syntax and must be inserted where comments are structurally valid, so converter-generated platform guards must wrap complete review blocks rather than splitting active statements.
- Added a documentation-preservation guardrail: future guide updates must preserve the original Word-authored graphics, formatting, `==>` markers, and TOC structure instead of replacing the guides with stripped-down regenerated documents.

