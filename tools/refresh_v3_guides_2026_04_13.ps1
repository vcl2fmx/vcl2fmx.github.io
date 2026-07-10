$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')

function Replace-ParagraphContaining {
  param(
    $Document,
    [string]$Needle,
    [string]$ReplaceText
  )

  $range = $Document.Content
  $find = $range.Find
  $find.ClearFormatting()
  $find.Text = $Needle
  if ($find.Execute()) {
    $range.Expand(4) | Out-Null
    $range.Text = $ReplaceText + "`r"
    return
  }

  throw "PARAGRAPH NOT FOUND: $Needle"
}

$word = $null
$userDoc = $null
$engineeringDoc = $null

try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0

  $userDoc = $word.Documents.Open($UserGuidePath)
  Replace-ParagraphContaining $userDoc `
    'Pay special attention to the final run status.' `
    'Pay special attention to the final run status. The current v3.0 report flow distinguishes Blocking issues present, Manual review required, and Clean conversion, and the generated report now calls out a recommended next step, files needing attention, and files with conversion errors. Treat blocking issues as stop conditions even if files were generated. Informational messages about external project assets are different: they warn that companion files may still need manual copying or relocation before runtime testing.'
  $userDoc.Save()
  $userDoc.Close()
  $userDoc = $null

  $engineeringDoc = $word.Documents.Open($EngineeringGuidePath)
  Replace-ParagraphContaining $engineeringDoc `
    'Timestamped snapshots are recommended so each converter iteration is preserved independently.' `
    'Timestamped snapshots are recommended so each converter iteration is preserved independently. This makes regression tracking easier and prevents accidental overwriting of known-good backup states. Before a public release, run tools\run_release_readiness_audit.ps1 and tools\run_regression_guards.ps1. Treat any blocker as a release stop rather than as a documentation-only reminder. The release audit covers shipped-tree cleanliness such as local paths, debug leftovers, packaging assets, and license presence, while the regression guards watch converter invariants that should remain true as internals evolve.'
  Replace-ParagraphContaining $engineeringDoc `
    'Converter.Core.Integration.pas is the global rewrite engine and the highest-leverage unit in the project.' `
    'Converter.Core.Integration.pas is the global rewrite engine and the highest-leverage unit in the project. It repairs uses clauses, injects helper routines, adapts runtime behavior, preserves startup semantics, stabilizes event timing, and applies category-wide FMX normalization rules discovered during real-world testing. Recent stabilization work in this unit also preserves and chains existing handlers when generated FMX support needs to hook lifecycle or data-aware behavior, instead of overwriting those handlers blindly.'
  Replace-ParagraphContaining $engineeringDoc `
    'Important newer generic behaviors in this unit include TMemo.Clear to Lines.Clear rewrites' `
    'Important newer generic behaviors in this unit include TMemo.Clear to Lines.Clear rewrites, Position and Value normalization for numeric slider-style controls, preservation and reinjection of Winapi.MMSystem for waveOut-style code, public TThread.Queue and TThread.Synchronize call normalization, plain ShowMessage preservation, minimize-instead-of-tray behavior for converted hide-to-tray handlers, helper injection for generated TRadioGroup and TFontDialog compatibility classes, and generated chaining around existing OnDestroy, OnCalcFields, and dataset AfterOpen handlers where FMX cleanup, calc fields, or grid refresh logic must be injected.'
  Replace-ParagraphContaining $engineeringDoc `
    'Converter.Advanced.DataAware.pas exists because VCL data-aware controls do not map cleanly to FMX.' `
    'Converter.Advanced.DataAware.pas exists because VCL data-aware controls do not map cleanly to FMX. It classifies DB-aware controls, identifies appropriate binding strategies, and supports the integration layer in deciding whether a control becomes a direct FMX control, a LiveBindings-driven control, a grid bridge, or a special-case combo/navigator path. The current v3.0 path now uses normalized class matching with mapper-backed ancestry instead of loose substring checks, which keeps DB-aware detection tighter and more trustworthy across derived component classes.'
  Replace-ParagraphContaining $engineeringDoc `
    'Converter.Project.Generator.pas makes the final output openable and runnable in Delphi.' `
    'Converter.Project.Generator.pas makes the final output openable and runnable in Delphi. It locates original project files, transforms DPR and DPROJ content, adapts FMX startup semantics, and copies or regenerates the project artifacts needed to load the converted application. The current v3.0 path now breaks DPR startup handling into smaller helper routines for startup normalization, splash-sequence detection, Application.Run placement, and immediate CreateForm/Show cleanup so that startup fixes remain easier to reason about.'
  Replace-ParagraphContaining $engineeringDoc `
    'This unit now also carries more responsibility for practical project portability.' `
    'This unit now also carries more responsibility for practical project portability. It should preserve the source Application.CreateForm list where appropriate, normalize namespace settings for FMX, copy companion assets that the project actually needs, ensure that serious unsupported conditions become blocking results in the report rather than misleading successful conversions, and keep public source distributions clean enough to ship with a root LICENSE.txt and without local-machine release noise.'
  $engineeringDoc.Save()
  $engineeringDoc.Close()
  $engineeringDoc = $null

  Write-Output 'V3_GUIDES_REFRESHED_2026_04_13'
}
finally {
  if ($userDoc -ne $null) {
    try { $userDoc.Close($false) | Out-Null } catch { }
  }
  if ($engineeringDoc -ne $null) {
    try { $engineeringDoc.Close($false) | Out-Null } catch { }
  }
  if ($word -ne $null) {
    try { $word.Quit() | Out-Null } catch { }
  }
}
