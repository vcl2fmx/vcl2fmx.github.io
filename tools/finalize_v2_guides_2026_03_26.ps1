$ErrorActionPreference = 'Stop'

$userGuidePath$userGuidePath = $UserGuidePath
$engineeringGuidePath$engineeringGuidePath = $EngineeringGuidePath

function Clean-CellText {
  param($Cell)
  return (($Cell.Range.Text -replace "[`r`a]", '').Trim())
}

function Set-ParagraphText {
  param(
    $Document,
    [int]$Index,
    [string]$Text
  )

  if ($Index -lt 1 -or $Index -gt $Document.Paragraphs.Count) {
    throw "PARAGRAPH INDEX OUT OF RANGE: $Index"
  }

  $Document.Paragraphs.Item($Index).Range.Text = $Text + "`r"
}

function Update-TableRowInTable {
  param(
    $Document,
    [int]$TableIndex,
    [string]$Label,
    [string[]]$NewValues
  )

  if ($TableIndex -lt 1 -or $TableIndex -gt $Document.Tables.Count) {
    throw "TABLE INDEX OUT OF RANGE: $TableIndex"
  }

  $table = $Document.Tables.Item($TableIndex)
  if ($table.Columns.Count -ne $NewValues.Count) {
    throw "TABLE COLUMN COUNT MISMATCH in table $TableIndex"
  }

  for ($r = 2; $r -le $table.Rows.Count; $r++) {
    if ((Clean-CellText $table.Cell($r, 1)) -eq $Label) {
      for ($c = 1; $c -le $table.Columns.Count; $c++) {
        $table.Cell($r, $c).Range.Text = $NewValues[$c - 1]
      }
      return
    }
  }

  throw "ROW '$Label' NOT FOUND IN TABLE $TableIndex"
}

$word = $null
$userDoc = $null
$engineeringDoc = $null

try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0

  $userDoc = $word.Documents.Open($userGuidePath)
  Set-ParagraphText $userDoc 116 'Open the VCL2FMXConverter project in Delphi.'
  Set-ParagraphText $userDoc 117 'Build the converter and confirm the build completes cleanly.'
  Set-ParagraphText $userDoc 118 'Run the converter from the IDE.'
  Set-ParagraphText $userDoc 119 'Verify that the tabbed main window opens and that the source project, output folder, files-to-convert, include-subfolders, and rule controls are available.'
  Set-ParagraphText $userDoc 120 'After a run, confirm that Open Report, Print Report, and Open Output Folder become available when output artifacts exist. A clean MSBuild target run can confirm project plumbing, but if the installed Delphi edition does not support command-line compilation, the trusted validation path is still an IDE open, build, and run pass.'
  Set-ParagraphText $userDoc 121 ''
  Set-ParagraphText $userDoc 122 ''
  Set-ParagraphText $userDoc 217 'Read the log before opening the output in Delphi. When the HTML report exists, the converter can open or print it directly; otherwise use the text report in the output directory.'
  Update-TableRowInTable $userDoc 6 'Conversion report' @(
    'Conversion reports',
    'Text and HTML summaries of the run.',
    'Use Open Report or Print Report from the converter after the run, and keep the files for diagnostics and engineering review.'
  )

  foreach ($toc in $userDoc.TablesOfContents) {
    $toc.Update() | Out-Null
  }
  foreach ($field in $userDoc.Fields) {
    $field.Update() | Out-Null
  }
  $userDoc.Save()
  $userDoc.Close()
  $userDoc = $null

  $engineeringDoc = $word.Documents.Open($engineeringGuidePath)
  Set-ParagraphText $engineeringDoc 254 'MainForm is responsible for operator workflow, progress output, and status visibility. Conversion logic should remain in the engine, parser, integration, and mapping units unless the user experience itself needs to change. The current live v3.0 interface is a tabbed operator workspace with Dashboard, Project Scan, mapping reference pages, Issues, and Rules. Open Report, Print Report, and Open Output Folder remain UI shell actions, while the four rule toggles are passed into explicit engine options rather than treated as decorative markers.'
  Set-ParagraphText $engineeringDoc 452 'Provide shared types, issue objects, mapping records, and the run context so the rest of the converter can exchange structured information. The current live v3.0 options container carries explicit per-run flags for Critical Areas, Data Aware, ThirdParty, and WinAPI passes. Keep the UI, manuals, and code in sync around those real engine flags, and do not describe a hidden or legacy field as an operator-ready option until the runtime path actually honors it.'

  foreach ($toc in $engineeringDoc.TablesOfContents) {
    $toc.Update() | Out-Null
  }
  foreach ($field in $engineeringDoc.Fields) {
    $field.Update() | Out-Null
  }
  $engineeringDoc.Save()
  $engineeringDoc.Close()
  $engineeringDoc = $null

  Write-Output 'V2_GUIDES_FINALIZED'
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


