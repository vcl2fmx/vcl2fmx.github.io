param(
  [Parameter(Mandatory = $true)]
  [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')

function Fit-TableToPage {
  param($Table)
  try { $Table.Rows.Alignment = 0 } catch {}
  try { $Table.Rows.LeftIndent = 0 } catch {}
  try { $Table.AllowAutoFit = $true } catch {}
  try { $Table.PreferredWidthType = 2 } catch {}
  try { $Table.PreferredWidth = 100 } catch {}
  try { $Table.AutoFitBehavior(2) | Out-Null } catch {}
}

& (Join-Path $PSScriptRoot 'build_engineering_guide_docx.ps1') -OutputPath $OutputPath

$word = $null
$doc = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  $doc = $word.Documents.Open($OutputPath)
  $sel = $word.Selection
  $find = $sel.Find
  $find.ClearFormatting()
  $find.Text = 'Appendix A. File Inventory'
  if ($find.Execute()) {
    $sel.SetRange($sel.Start, $sel.Start)
  }
  else {
    $sel.EndKey(6) | Out-Null
  }

  $doc.Styles.Item('Heading 1').ParagraphFormat.KeepWithNext = $true
  $doc.Styles.Item('Heading 2').ParagraphFormat.KeepWithNext = $true

  $sel.InsertBreak(7)
  $sel.Style = 'Heading 1'
  $sel.TypeText('16. Project Overview Integration')
  $sel.TypeParagraph()
  $sel.Style = 'Normal'
  $sel.TypeText('This section incorporates the key narrative from VCL2FMX_Delphi_Conversion_Project_Overview.docx so the engineering guide reflects both the converter architecture and the actual development history that shaped it.')
  $sel.TypeParagraph()
  $sel.TypeText('The overview document explains that the project began as an attempt to migrate a VCL-based Delphi application to FMX for mobile use, that early manual or partially assisted attempts were not sufficient, and that the scale of component mapping, event translation, and framework mismatch made a converter-based approach necessary.')
  $sel.TypeParagraph()
  $sel.TypeText('It also captures an important historical lesson: the converter became practical only after many iterative test cycles against a large real-world application. That experience is why this guide emphasizes global fixes, repeatable validation, and disciplined separation between converter logic and generated output.')
  $sel.TypeParagraph()

  $table = $doc.Tables.Add($sel.Range, 5, 3)
  try { $table.Style = 'Table Grid' } catch {}
  $table.Range.Font.Name = 'Segoe UI'
  $table.Range.Font.Size = 9.5
  $headers = @('Overview Topic','What the Overview Adds','Why It Matters to Engineers')
  for ($c = 0; $c -lt 3; $c++) {
    $cell = $table.Cell(1, $c + 1)
    $cell.Range.Text = $headers[$c]
    $cell.Range.Bold = $true
    $cell.Range.Font.Color = 16777215
    $cell.Shading.BackgroundPatternColor = 8404992
  }
  $rows = @(
    @('Project background','Records how the converter originated from a failed direct migration attempt.','Explains why architecture and automation were prioritized.'),
    @('AI-assisted development','Describes why Codex materially improved development speed and coverage.','Shows how AI fit into a real Delphi engineering workflow.'),
    @('Iterative testing','Documents that many test runs were required for stability.','Confirms that repeated regeneration and validation are part of the method, not a sign of failure.'),
    @('Manual finish work','Notes that the converter handles most but not all migration work.','Sets realistic expectations for future users and maintainers.')
  )
  for ($r = 0; $r -lt $rows.Count; $r++) {
    for ($c = 0; $c -lt 3; $c++) {
      $table.Cell($r + 2, $c + 1).Range.Text = [string]$rows[$r][$c]
    }
  }
  Fit-TableToPage $table
  $sel.SetRange($table.Range.End, $table.Range.End)
  $sel.TypeParagraph(); $sel.TypeParagraph()

  $sel.InsertBreak(7)
  $sel.Style = 'Heading 1'
  $sel.TypeText('17. Codex Capabilities, Constraints, and Professional Use')
  $sel.TypeParagraph()
  $sel.Style = 'Normal'
  $sel.TypeText('In this project, Codex functioned as an AI-assisted coding agent working inside the local converter workspace. It reviewed source files, interpreted generated output, proposed global converter improvements, created documentation, and supported an iterative debug-and-test cycle. That made it especially useful for migration work where many defects repeat as patterns rather than as isolated one-off mistakes.')
  $sel.TypeParagraph()
  $sel.TypeText('Codex is most valuable when it is used to improve the converter itself rather than to hand-fix one generated target file permanently. That discipline turns each fix into a reusable rule that can benefit future projects as well as the current one.')
  $sel.TypeParagraph()

  $table2 = $doc.Tables.Add($sel.Range, 6, 3)
  try { $table2.Style = 'Table Grid' } catch {}
  $table2.Range.Font.Name = 'Segoe UI'
  $table2.Range.Font.Size = 9.5
  $headers2 = @('Codex Aspect','Practical Value in This Project','Boundary or Limitation')
  for ($c = 0; $c -lt 3; $c++) {
    $cell = $table2.Cell(1, $c + 1)
    $cell.Range.Text = $headers2[$c]
    $cell.Range.Bold = $true
    $cell.Range.Font.Color = 16777215
    $cell.Shading.BackgroundPatternColor = 8404992
  }
  $rows2 = @(
    @('Repository awareness','Could inspect local code, generated files, reports, and scripts.','Still depends on the local environment and permissions it is given.'),
    @('Global editing','Could improve converter rules instead of only patching one target unit.','Global changes still require Delphi validation to prove correctness.'),
    @('Documentation','Could draft manuals, diagrams, and project narratives quickly.','A human still needs to review tone, completeness, and any product claims.'),
    @('Iterative debugging','Could follow long sessions and preserve useful summarized context.','It is still possible to overfit a speculative fix if testing is skipped.'),
    @('Local execution','Could read files and run allowed commands in the workspace.','It cannot replace the Delphi IDE, actual end-user workflow testing, or all GUI-only actions.')
  )
  for ($r = 0; $r -lt $rows2.Count; $r++) {
    for ($c = 0; $c -lt 3; $c++) {
      $table2.Cell($r + 2, $c + 1).Range.Text = [string]$rows2[$r][$c]
    }
  }
  Fit-TableToPage $table2
  $sel.SetRange($table2.Range.End, $table2.Range.End)
  $sel.TypeParagraph(); $sel.TypeParagraph()

  $sel.Style = 'Heading 2'
  $sel.TypeText('17.2 Recommended Professional Practices When Using Codex')
  $sel.TypeParagraph()
  $sel.Style = 'Normal'
  $sel.Range.ListFormat.ApplyBulletDefault()
  foreach ($line in @(
    'Prefer precise requests for global converter fixes over one-off target-file patches.',
    'Use compiler and runtime evidence to guide the next fix rather than guessing repeatedly.',
    'Keep milestone backups so major improvements can be preserved and compared.',
    'Treat visual polish and structural/runtime correctness as separate phases.',
    'Check official OpenAI documentation periodically because Codex product surfaces and availability can change.'
  )) {
    $sel.TypeText($line)
    $sel.TypeParagraph()
  }
  $sel.Range.ListFormat.RemoveNumbers()
  $sel.TypeParagraph()

  $sel.Style = 'Heading 2'
  $sel.TypeText('17.3 Additional References')
  $sel.TypeParagraph()
  $sel.Style = 'Normal'
  foreach ($line in @(
    ('Project overview document: ' + $ProjectOverviewPath),
    'OpenAI Codex product page: https://openai.com/codex/',
    'OpenAI Codex documentation overview: https://platform.openai.com/docs/codex/overview',
    'OpenAI Help Center article on Codex availability: https://help.openai.com/en/articles/11369540'
  )) {
    $sel.TypeText($line)
    $sel.TypeParagraph()
  }

  if ($doc.TablesOfContents.Count -gt 0) {
    $doc.TablesOfContents.Item(1).Update() | Out-Null
  }
  $doc.Save()
}
finally {
  if ($doc -ne $null) {
    try { $doc.Close($true) | Out-Null } catch { }
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null } catch { }
  }
  if ($word -ne $null) {
    try { $word.Quit() | Out-Null } catch { }
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null } catch { }
  }
  [gc]::Collect()
  [gc]::WaitForPendingFinalizers()
}




