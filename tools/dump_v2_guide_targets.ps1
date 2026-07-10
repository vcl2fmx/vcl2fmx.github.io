$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')

$word = $null

function Clean-WordText {
  param([string]$Text)
  return ($Text -replace "[`r`a]", '').Trim()
}

try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0

  $userDoc = $word.Documents.Open(
    $UserGuidePath,
    $false,
    $true
  )

  try {
    Write-Output 'USER_GUIDE_PARAGRAPHS'
    foreach ($p in $userDoc.Paragraphs) {
      $text = Clean-WordText $p.Range.Text
      if ($text -match '4\. Building and Launching the Converter|5\. Main Window and Control-by-Control Walkthrough|8\. Running a Conversion|9\. Reading the Log and the Conversion Report|10\. Understanding the Output Folder and Files|Open the migrated project|Set recursion and backup options as needed|Every conversion run should be reviewed|The main window is intentionally simple') {
        Write-Output $text
      }
    }

    Write-Output 'USER_GUIDE_TABLE_3'
    $table = $userDoc.Tables.Item(3)
    for ($r = 1; $r -le $table.Rows.Count; $r++) {
      $cells = @()
      for ($c = 1; $c -le $table.Columns.Count; $c++) {
        $cells += '[' + (Clean-WordText $table.Cell($r, $c).Range.Text) + ']'
      }
      Write-Output ($cells -join ' ')
    }

    Write-Output 'USER_GUIDE_TABLE_6'
    $table = $userDoc.Tables.Item(6)
    for ($r = 1; $r -le $table.Rows.Count; $r++) {
      $cells = @()
      for ($c = 1; $c -le $table.Columns.Count; $c++) {
        $cells += '[' + (Clean-WordText $table.Cell($r, $c).Range.Text) + ']'
      }
      Write-Output ($cells -join ' ')
    }
  }
  finally {
    $userDoc.Close()
  }

  $engDoc = $word.Documents.Open(
    $EngineeringGuidePath,
    $false,
    $true
  )

  try {
    Write-Output 'ENGINEERING_GUIDE_PARAGRAPHS'
    foreach ($p in $engDoc.Paragraphs) {
      $text = Clean-WordText $p.Range.Text
      if ($text -match '5\.2 UI Responsibilities|MainForm is responsible|Collect options, launch conversion, and report progress|Converter\.Core\.Types\.pas is the vocabulary layer|Provide shared types, issue objects, mapping records, and the run context') {
        Write-Output $text
      }
    }
  }
  finally {
    $engDoc.Close()
  }
}
finally {
  if ($word -ne $null) {
    $word.Quit()
  }
}