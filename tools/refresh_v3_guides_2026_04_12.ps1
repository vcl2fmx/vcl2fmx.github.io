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
    'what the current v2 build knows about standard component, property, and event coverage' `
    'The live Component Map, Property Map, and Event Map pages are now backed by the same current mapper knowledge used during conversion. That makes them the best quick-reference view of what the current live v3.0 build knows about standard component, property, and event coverage.'
  Replace-ParagraphContaining $userDoc `
    'The v2 main window is a tabbed workspace' `
    'The current v3.0 main window is a tabbed workspace. Dashboard shows the latest run summary and quick actions, Project Scan holds the path and scope controls, Rules controls the four specialized conversion families, Conversion Output shows the live log and report status, and the mapping pages are current reference screens for coverage and review. The converter still does its real work behind the scenes, but the operator needs to use the front end carefully because path mistakes, stale output folders, and poorly scoped runs can create misleading results.'
  Replace-ParagraphContaining $userDoc `
    'Read the log before opening the output in Delphi. When the HTML report exists' `
    'Read the log before opening the output in Delphi. When the HTML report exists, use Open Report or Print Report directly from the converter, and use Open Output Folder when you need the generated files immediately.'
  foreach ($toc in $userDoc.TablesOfContents) { $toc.Update() | Out-Null }
  foreach ($field in $userDoc.Fields) { $field.Update() | Out-Null }
  $userDoc.Save()
  $userDoc.Close()
  $userDoc = $null

  $engineeringDoc = $word.Documents.Open($EngineeringGuidePath)
  Replace-ParagraphContaining $engineeringDoc `
    'MainForm is responsible for operator workflow, progress output, and status visibility' `
    'MainForm is responsible for operator workflow, progress output, and status visibility. Conversion logic should remain in the engine, parser, integration, and mapping units unless the user experience itself needs to change. The current live v3.0 interface is a tabbed operator workspace with Dashboard, Project Scan, mapping reference pages, Issues, and Rules. Open Report, Print Report, and Open Output Folder remain UI shell actions, while the four rule toggles are passed into explicit engine options rather than treated as decorative markers.'
  Replace-ParagraphContaining $engineeringDoc `
    'Timestamped snapshots are recommended so each converter iteration is preserved independently' `
    'Timestamped snapshots are recommended so each converter iteration is preserved independently. This makes regression tracking easier and prevents accidental overwriting of known-good backup states. Before a public release, run tools\run_release_readiness_audit.ps1 and treat any blocker as a release stop rather than as a documentation-only reminder.'
  Replace-ParagraphContaining $engineeringDoc `
    'Converter.Core.Types.pas is the vocabulary layer of the converter' `
    'Converter.Core.Types.pas is the vocabulary layer of the converter. It defines the issue model, the mapping model, the conversion options container, and the conversion context object used to carry state across the run. The current live v3.0 options container carries explicit per-run flags for Critical Areas, Data Aware, ThirdParty, and WinAPI passes. Keep the UI, manuals, and code in sync around those real engine flags, and do not describe a hidden or legacy field as an operator-ready option until the runtime path actually honors it.'
  foreach ($toc in $engineeringDoc.TablesOfContents) { $toc.Update() | Out-Null }
  foreach ($field in $engineeringDoc.Fields) { $field.Update() | Out-Null }
  $engineeringDoc.Save()
  $engineeringDoc.Close()
  $engineeringDoc = $null

  Write-Output 'V3_GUIDES_REFRESHED'
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
