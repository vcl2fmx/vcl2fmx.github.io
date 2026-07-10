$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$userGuide = Join-Path $projectRoot 'docs\guides\VCL2FMXConverter_v5_0_User_Guide.docx'

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
  $doc = $word.Documents.Open($userGuide)

  if ($doc.Content.Text -notlike '*Conversion Contracts in v5.0*') {
    $sel = $word.Selection
    $sel.HomeKey(6) | Out-Null
    $find = $sel.Find
    $find.ClearFormatting()
    $find.Text = 'Appendix A. Quick Start Checklist'
    $find.Forward = $true
    $find.Wrap = 0
    if ($find.Execute()) {
      $sel.SetRange($sel.Start, $sel.Start)
    }
    else {
      $sel.EndKey(6) | Out-Null
    }
    $sel.InsertBreak(7)
    Add-Paragraph $sel '17. Conversion Contracts in v5.0' 'Heading 1'
    Add-Paragraph $sel 'Version 5.0 adds an executable conversion-contract system. Contracts are small Delphi fixture projects and units that describe a known conversion problem, the expected generated Pascal/FMX output, and the expected conversion report behavior. They are not loaded during a normal user conversion. They are run by the engineering test runner before release so the converter does not silently lose behavior that was already fixed.'
    Add-Paragraph $sel 'For operators, contracts matter because they explain why v5.0 is more disciplined than earlier releases. The converter is no longer trusted merely because one project looks good. Each structural rule should have a small fixture, an expectation file, and a regression guard that proves the rule still works after later changes.'
    Add-Table $doc $sel @('Contract Area','What It Protects') @(
      @('Include analysis','Beside-source, subfolder, nested, recursive, missing, outside-tree, conditional, commented, and UTF-8 Pascal include directives.'),
      @('Windows messaging','SendMessage, PostMessage, Perform, WndProc, message declarations, WM/CM/CN/common-control families, WM_USER, false positives, and system-command handling.'),
      @('Uses cleanup','Removal of unused VCL and Winapi units, including conditional/protected uses blocks and the former Vcl.Themes leftover case.'),
      @('DFM/FMXL generation','TMemo/TStrings collection preservation, TStringGrid event ordering, accented text, and paired Pascal/DFM form behavior.'),
      @('Graphics and GDI','Safe FMX canvas substitutions where possible, plus visual-review reporting when drawing code still needs human verification.'),
      @('Project integration','Whole-project fixtures that exercise include copying, report shape, Windows messaging, uses cleanup, DFM/FMXL behavior, and generated output together.')
    )
    Add-Paragraph $sel 'The current v5.0 contract set contains 175 expectations. The final release-candidate run passed with 175 passing and 0 failing contracts. Regression guards also passed with 0 blockers and 0 warnings.'
    Add-Paragraph $sel 'A normal conversion does not compare each user file against every contract. Contracts are engineering fixtures used by the test runner. User source files are converted by the parser, mapper, rewrite, integration, and project-generation rules. The contracts verify those rules ahead of time.'
    Add-Paragraph $sel 'When a real project exposes a new reusable pattern, the preferred v5.0 workflow is to add or strengthen a contract first, then update the converter until that contract passes. This keeps the fix useful for the wider user base instead of becoming a project-only workaround.'
  }

  $doc.Save() | Out-Null
  Write-Output 'USER_CONTRACTS_SECTION_ADDED'
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
