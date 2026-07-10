$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$guidesRoot = Join-Path $projectRoot 'docs\guides'
$pdfRoot = Join-Path $projectRoot 'docs\pdf'
New-Item -ItemType Directory -Path $pdfRoot -Force | Out-Null

$userGuide = Join-Path $guidesRoot 'VCL2FMXConverter_v5_0_User_Guide.docx'
$engineeringGuide = Join-Path $guidesRoot 'VCL2FMXConverter_v5_0_Engineering_Guide.docx'

function Replace-AllText {
  param($Document, [string]$FindText, [string]$ReplaceText)
  $find = $Document.Content.Find
  $find.ClearFormatting()
  $find.Replacement.ClearFormatting()
  $find.Text = $FindText
  $find.Replacement.Text = $ReplaceText
  $find.Forward = $true
  $find.Wrap = 1
  $find.Format = $false
  $find.MatchCase = $false
  $find.MatchWholeWord = $false
  $find.MatchWildcards = $false
  $find.Execute() | Out-Null
  $find.Execute($FindText, $false, $false, $false, $false, $false, $true, 1, $false, $ReplaceText, 2) | Out-Null
}

function Add-Paragraph {
  param($Selection, [string]$Text, [string]$Style = 'Normal')
  $Selection.Style = $Style
  $Selection.TypeText($Text)
  $Selection.TypeParagraph()
}

function Add-Bullets {
  param($Selection, [string[]]$Items)
  foreach ($item in $Items) {
    $Selection.Style = 'Normal'
    $Selection.Range.ListFormat.ApplyBulletDefault()
    $Selection.TypeText($item)
    $Selection.TypeParagraph()
  }
  $Selection.Range.ListFormat.RemoveNumbers()
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

function Apply-VersionReplacements {
  param($Document)
  $pairs = @(
    @('VCL2FMX Converter v4.1.8 User Guide', 'VCL2FMX Converter v5.0 User Guide'),
    @('VCL2FMXConverter v4.1.8', 'VCL2FMXConverter v5.0'),
    @('Version 4.1.8', 'Version 5.0'),
    @('version 4.1.8', 'version 5.0'),
    @('v4.1.8', 'v5.0'),
    @('V4.1.8', 'V5.0'),
    @('current v5.0 build', 'current v5.0 build'),
    @('Updated June 14, 2026', 'Revision date: June 25, 2026'),
    @('June 14, 2026', 'June 25, 2026')
  )
  foreach ($pair in $pairs) {
    Replace-AllText -Document $Document -FindText $pair[0] -ReplaceText $pair[1]
  }
}

function Insert-BeforeHeading {
  param($Word, $Document, [string]$HeadingText)
  $selection = $Word.Selection
  $selection.HomeKey(6) | Out-Null
  $find = $selection.Find
  $find.ClearFormatting()
  $find.Text = $HeadingText
  $find.Forward = $true
  $find.Wrap = 0
  if ($find.Execute()) {
    $selection.SetRange($selection.Start, $selection.Start)
  }
  else {
    $selection.EndKey(6) | Out-Null
  }
  $selection.InsertBreak(7)
  return $selection
}

function Add-UserContractsSection {
  param($Word, $Document)
  if ($Document.Content.Text -like '*Conversion Contracts in v5.0*') {
    return
  }
  $sel = Insert-BeforeHeading -Word $Word -Document $Document -HeadingText 'Appendix A. Quick Start Checklist'
  Add-Paragraph $sel '17. Conversion Contracts in v5.0' 'Heading 1'
  Add-Paragraph $sel 'Version 5.0 adds an executable conversion-contract system. Contracts are small Delphi fixture projects and units that describe a known conversion problem, the expected generated Pascal/FMX output, and the expected conversion report behavior. They are not loaded during a normal user conversion. They are run by the engineering test runner before release so the converter does not silently lose behavior that was already fixed.'
  Add-Paragraph $sel 'For operators, contracts matter because they explain why v5.0 is more disciplined than earlier releases. The converter is no longer trusted merely because one project looks good. Each structural rule should have a small fixture, an expectation file, and a regression guard that proves the rule still works after later changes.'
  Add-Table $Document $sel @('Contract Area','What It Protects') @(
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

function Add-EngineeringContractsSection {
  param($Word, $Document)
  if ($Document.Content.Text -like '*v5.0 Conversion Contract System*') {
    return
  }
  $sel = Insert-BeforeHeading -Word $Word -Document $Document -HeadingText 'Appendix A. File Inventory'
  Add-Paragraph $sel '15. v5.0 Conversion Contract System' 'Heading 1'
  Add-Paragraph $sel 'The v5.0 contract system is the central engineering safeguard for structural converter changes. A contract is a small Delphi source fixture paired with a .expected.json file. The fixture demonstrates a known conversion problem or behavior family; the expectation file declares the required output patterns, forbidden output patterns, report patterns, unit additions/removals, and status expectations.'
  Add-Paragraph $sel 'Contracts are not used during ordinary user conversions. They are executable regression fixtures for the converter itself. The normal converter pipeline still parses and rewrites user projects directly through the file manager, parsers, mapper, integration layer, advanced modules, and project generator. The contracts prove that those rule families continue to behave as intended.'
  Add-Table $Document $sel @('Contract Folder','Engineering Coverage') @(
    @('include_analysis','Pascal include directives, source-subfolder resolution, missing includes, outside-tree warnings, nested analysis, recursion guards, conditional directives, commented directives, Winapi/VCL/message usage inside includes, and UTF-8 include text.'),
    @('winapi_messages','SendMessage, PostMessage, DispatchMessage, PeekMessage, GetMessage, Perform, WM/CM/CN/common-control families, TWM/TCM records, WndProc, message declarations, WM_USER/custom offsets, false positives, and system-command policy.'),
    @('uses_clause','VCL/Winapi unit removal and preservation, implementation-only Windows unit handling, conditional/protected uses blocks, and the former leftover Vcl.Themes case.'),
    @('graphics','VCL Canvas and GDI conversions to FMX canvas calls where reliable, plus explicit visual-review reporting for drawing code that still requires human inspection.'),
    @('project_integration','Whole-project fixtures for include copying, report shape, Windows messaging, uses cleanup, DFM/FMXL behavior, and generated compile-ready scenarios.')
  )
  Add-Paragraph $sel 'The final v5.0 release-candidate contract run contains 175 expectations and passed with 175 passing and 0 failing. Regression guards passed separately with 0 blockers and 0 warnings. The runner also supports -CompileGenerated for compile-ready project fixtures and skip_generated_compile for fixtures that intentionally preserve missing/manual-review dependencies.'
  Add-Paragraph $sel 'When a beta project reveals a reusable issue, the preferred engineering workflow is: reduce the problem to a fixture, add or strengthen the expected JSON, verify that the contract fails for the current behavior, fix the converter globally, then rerun the focused contract, the full contract suite, regression guards, and a real project pass.'
}

function Repair-Document {
  param([string]$Path, [string]$Kind)
  $word = $null
  $doc = $null
  try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $doc = $word.Documents.Open($Path)
    Apply-VersionReplacements -Document $doc
    if ($Kind -eq 'User') {
      Add-UserContractsSection -Word $word -Document $doc
    }
    else {
      Add-EngineeringContractsSection -Word $word -Document $doc
    }
    if ($doc.TablesOfContents.Count -gt 0) {
      $doc.TablesOfContents.Item(1).Update() | Out-Null
    }
    $doc.Save() | Out-Null

    $pdfPath = Join-Path $pdfRoot ([IO.Path]::GetFileNameWithoutExtension($Path) + '.pdf')
    $doc.ExportAsFixedFormat($pdfPath, 17) | Out-Null
    Write-Output $pdfPath
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
}

Repair-Document -Path $userGuide -Kind 'User'
Repair-Document -Path $engineeringGuide -Kind 'Engineering'
Write-Output 'GUIDES_REPAIRED_WITH_FORMAT_PRESERVED'
