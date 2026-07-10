$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$guidesRoot = Join-Path $projectRoot 'docs\guides'
$engineeringGuide = Join-Path $guidesRoot 'VCL2FMXConverter_v5_0_Engineering_Guide.docx'

function Replace-AllText {
  param($Document, [string]$FindText, [string]$ReplaceText)
  $find = $Document.Content.Find
  $find.ClearFormatting()
  $find.Replacement.ClearFormatting()
  $find.Execute($FindText, $false, $false, $false, $false, $false, $true, 1, $false, $ReplaceText, 2) | Out-Null
}

function Add-Paragraph {
  param($Selection, [string]$Text, [string]$Style = 'Normal')
  $Selection.Style = $Style
  $Selection.TypeText($Text)
  $Selection.TypeParagraph()
}

function Add-Table {
  param($Document, $Selection, [string[]]$Headers, [object[][]]$Rows)
  $table = $Document.Tables.Add($Selection.Range, $Rows.Count + 1, $Headers.Count)
  try { $table.Style = 'Table Grid' } catch {}
  for ($c = 0; $c -lt $Headers.Count; $c++) {
    $cell = $table.Cell(1, $c + 1)
    $cell.Range.Text = $Headers[$c]
    $cell.Range.Bold = $true
  }
  for ($r = 0; $r -lt $Rows.Count; $r++) {
    for ($c = 0; $c -lt $Headers.Count; $c++) {
      $table.Cell($r + 2, $c + 1).Range.Text = [string]$Rows[$r][$c]
    }
  }
  try { $table.AutoFitBehavior(2) | Out-Null } catch {}
  $Selection.SetRange($table.Range.End, $table.Range.End)
  $Selection.TypeParagraph()
}

$word = $null
$doc = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  $doc = $word.Documents.Open($engineeringGuide)

  foreach ($pair in @(
    @('VCL2FMXConverter v4.1.8', 'VCL2FMXConverter v5.0'),
    @('Version 4.1.8', 'Version 5.0'),
    @('version 4.1.8', 'version 5.0'),
    @('v4.1.8', 'v5.0'),
    @('V4.1.8', 'V5.0'),
    @('Updated June 14, 2026', 'Revision date: June 25, 2026'),
    @('June 14, 2026', 'June 25, 2026')
  )) {
    Replace-AllText -Document $doc -FindText $pair[0] -ReplaceText $pair[1]
  }

  if ($doc.Content.Text -notlike '*v5.0 Conversion Contract System*') {
    $sel = $word.Selection
    $sel.HomeKey(6) | Out-Null
    $find = $sel.Find
    $find.ClearFormatting()
    $find.Text = 'Appendix A. File Inventory'
    $find.Forward = $true
    $find.Wrap = 0
    if ($find.Execute()) {
      $sel.SetRange($sel.Start, $sel.Start)
    }
    else {
      $sel.EndKey(6) | Out-Null
    }
    $sel.InsertBreak(7)
    Add-Paragraph $sel '15. v5.0 Conversion Contract System' 'Heading 1'
    Add-Paragraph $sel 'The v5.0 contract system is the central engineering safeguard for structural converter changes. A contract is a small Delphi source fixture paired with a .expected.json file. The fixture demonstrates a known conversion problem or behavior family; the expectation file declares the required output patterns, forbidden output patterns, report patterns, unit additions/removals, and status expectations.'
    Add-Paragraph $sel 'Contracts are not used during ordinary user conversions. They are executable regression fixtures for the converter itself. The normal converter pipeline still parses and rewrites user projects directly through the file manager, parsers, mapper, integration layer, advanced modules, and project generator. The contracts prove that those rule families continue to behave as intended.'
    Add-Table $doc $sel @('Contract Folder','Engineering Coverage') @(
      @('include_analysis','Pascal include directives, source-subfolder resolution, missing includes, outside-tree warnings, nested analysis, recursion guards, conditional directives, commented directives, Winapi/VCL/message usage inside includes, and UTF-8 include text.'),
      @('winapi_messages','SendMessage, PostMessage, DispatchMessage, PeekMessage, GetMessage, Perform, WM/CM/CN/common-control families, TWM/TCM records, WndProc, message declarations, WM_USER/custom offsets, false positives, and system-command policy.'),
      @('uses_clause','VCL/Winapi unit removal and preservation, implementation-only Windows unit handling, conditional/protected uses blocks, and the former leftover Vcl.Themes case.'),
      @('graphics','VCL Canvas and GDI conversions to FMX canvas calls where reliable, plus explicit visual-review reporting for drawing code that still requires human inspection.'),
      @('project_integration','Whole-project fixtures for include copying, report shape, Windows messaging, uses cleanup, DFM/FMXL behavior, and generated compile-ready scenarios.')
    )
    Add-Paragraph $sel 'The final v5.0 release-candidate contract run contains 175 expectations and passed with 175 passing and 0 failing. Regression guards passed separately with 0 blockers and 0 warnings. The runner also supports -CompileGenerated for compile-ready project fixtures and skip_generated_compile for fixtures that intentionally preserve missing/manual-review dependencies.'
    Add-Paragraph $sel 'When a beta project reveals a reusable issue, the preferred engineering workflow is: reduce the problem to a fixture, add or strengthen the expected JSON, verify that the contract fails for the current behavior, fix the converter globally, then rerun the focused contract, the full contract suite, regression guards, and a real project pass.'
  }

  $doc.Save() | Out-Null
  Write-Output 'ENGINEERING_DOC_REPAIRED'
}
finally {
  if ($doc -ne $null) {
    try { $doc.Close($true) | Out-Null } catch {}
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null } catch {}
  }
  if ($word -ne $null) {
    try { $word.Quit() | Out-Null } catch {}
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null } catch {}
  }
  [gc]::Collect()
  [gc]::WaitForPendingFinalizers()
}
