$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')

$userGuidePath = $UserGuidePath
$engineeringGuidePath = $EngineeringGuidePath

function Normalize-WordText {
  param([string]$Text)
  return ((($Text -replace "[`r`a]", ' ') -replace '\s+', ' ').Trim())
}

function Replace-ExactText {
  param(
    $Document,
    [string]$FindText,
    [string]$ReplaceText
  )

  foreach ($paragraph in $Document.Paragraphs) {
    if ((Normalize-WordText $paragraph.Range.Text) -eq $FindText) {
      $paragraph.Range.Text = $ReplaceText + "`r"
      return
    }
  }

  throw "TEXT NOT FOUND: $FindText"
}

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

function Append-ToParagraphContaining {
  param(
    $Document,
    [string]$Needle,
    [string]$AppendText
  )

  if ($Document.Content.Text.Contains($AppendText)) {
    return
  }

  $range = $Document.Content
  $find = $range.Find
  $find.ClearFormatting()
  $find.Text = $Needle
  if ($find.Execute()) {
    $range.Expand(4) | Out-Null
    $paragraphText = Normalize-WordText $range.Text
    $range.Text = $paragraphText + ' ' + $AppendText + "`r"
    return
  }

  throw "APPEND MARKER NOT FOUND: $Needle"
}

function Clean-CellText {
  param($Cell)
  return (($Cell.Range.Text -replace "[`r`a]", '').Trim())
}

function Update-TableRow {
  param(
    $Document,
    [string[]]$Labels,
    [string[]]$NewValues
  )

  foreach ($table in $Document.Tables) {
    for ($r = 2; $r -le $table.Rows.Count; $r++) {
      $label = Clean-CellText $table.Cell($r, 1)
      if ($Labels -contains $label) {
        if ($table.Columns.Count -ne $NewValues.Count) {
          throw "TABLE COLUMN COUNT MISMATCH for row '$label'"
        }

        for ($c = 1; $c -le $table.Columns.Count; $c++) {
          $table.Cell($r, $c).Range.Text = $NewValues[$c - 1]
        }
        return
      }
    }
  }

  throw "TABLE ROW NOT FOUND: $($Labels -join ', ')"
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

  Replace-ParagraphContaining $userDoc `
    'The main window is intentionally simple' `
    'The current v3.0 main window is a tabbed workspace. Dashboard shows the latest run summary and quick actions, Project Scan holds the path and scope controls, Rules controls the four specialized conversion families, Conversion Output shows the live log and report status, and the mapping pages are current reference screens for coverage and review. The converter still does its real work behind the scenes, but the operator needs to use the front end carefully because path mistakes, stale output folders, and poorly scoped runs can create misleading results.'

  Replace-ParagraphContaining $userDoc `
    'Set recursion and backup options as needed' `
    'Set the include-subfolders option and the four rule toggles as needed. For a full run, leave the rule toggles enabled unless you are intentionally isolating one conversion family.'

  Replace-ParagraphContaining $userDoc `
    'The log is named VCL_to_FMX_Conversion_Report.txt' `
    'Read the log before opening the output in Delphi. When the HTML report exists, the converter can open or print it directly; otherwise use the text report in the output directory.'

  Replace-ParagraphContaining $userDoc `
    'written conversion report' `
    'Every conversion run should be reviewed through two channels: the live log in the converter UI and the generated report files in the output folder. When the HTML report exists, the Open Report and Print Report buttons use it first. These are not optional extras; they are part of the operating workflow.'

  Replace-ParagraphContaining $userDoc `
    'later workspace backups do not recurse' `
    'Keep zipped milestone backups out of the live converter workspace so later workspace backups do not recurse by mistake and grow uncontrollably. Put them in a separate folder, removable drive, or other storage outside the live workspace.'

  Update-TableRow $userDoc @('Backup storage') @(
    'Backup storage',
    'Contains milestone snapshots or archived converter states outside the live converter workspace. Use separate storage so backups do not pollute the source or output trees.'
  )

  Update-TableRow $userDoc @('Source path') @(
    'Source project',
    'Points at the original VCL project or source root.',
    'This is the source of truth the converter will scan.'
  )

  Update-TableRow $userDoc @('Target path') @(
    'Output folder',
    'Points at the output directory for generated FMX artifacts.',
    'Treat this as disposable and regenerable output, not as your only copy of the application.'
  )

  Update-TableRow $userDoc @('File type combo') @(
    'Files to convert',
    'Chooses PAS only, DFM only, or both.',
    'Use narrower scopes for focused retests, and use both for full conversions.'
  )

  Update-TableRow $userDoc @('Recursive') @(
    'Include subfolders',
    'Controls whether subdirectories are scanned.',
    'Leave it enabled for complete projects unless you intentionally want to limit the run.'
  )

  Update-TableRow $userDoc @('Backup', 'Report and output actions') @(
    'Report and output actions',
    'Open the generated report, print it when the registered handler supports printing, or open the output folder directly from the converter.',
    'Use these after a run so you can review or print results without manually browsing the output tree.'
  )

  Update-TableRow $userDoc @('Critical / DataAware / ThirdParty / WinAPI') @(
    'Critical Areas / Data Aware / 3rd Party / WinAPI',
    'Per-run rule toggles that enable or disable the corresponding conversion families.',
    'Leave these enabled for a normal full pass, and only turn one off when you are intentionally isolating behavior for a focused retest.'
  )

  Update-TableRow $userDoc @('Convert button') @(
    'Convert Project',
    'Starts the conversion process.',
    'Only press this after source, output, scope, and rule choices are correct.'
  )

  Update-TableRow $userDoc @('Memo log') @(
    'Issues log',
    'Displays progress and key messages while also supporting report review from the Issues page.',
    'Read it after every run; it is the first indicator of what happened.'
  )

  Update-TableRow $userDoc @('Conversion report', 'Conversion reports') @(
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

  Append-ToParagraphContaining $engineeringDoc `
    'MainForm is responsible for operator workflow' `
    'The current live v3.0 interface is a tabbed operator workspace with Dashboard, Project Scan, mapping reference pages, Issues, and Rules. Open Report, Print Report, and Open Output Folder remain UI shell actions, while the four rule toggles are passed into explicit engine options rather than treated as decorative markers.'

  Append-ToParagraphContaining $engineeringDoc `
    'Provide shared types, issue objects' `
    'The current live v3.0 options container carries explicit per-run flags for Critical Areas, Data Aware, ThirdParty, and WinAPI passes. Keep the UI, manuals, and code in sync around those real engine flags, and do not describe a hidden or legacy field as an operator-ready option until the runtime path actually honors it.'

  foreach ($toc in $engineeringDoc.TablesOfContents) {
    $toc.Update() | Out-Null
  }
  foreach ($field in $engineeringDoc.Fields) {
    $field.Update() | Out-Null
  }
  $engineeringDoc.Save()
  $engineeringDoc.Close()
  $engineeringDoc = $null

  Write-Output 'V2_GUIDES_UPDATED'
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


