$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')

$docPath = Join-Path $NotesRoot 'VCL2FMXConverter_v5_Contract_System_Overview.docx'
if (-not (Test-Path -LiteralPath $docPath)) {
  throw "Document not found: $docPath"
}

$word = $null
$doc = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  $doc = $word.Documents.Open($docPath)
  $sel = $word.Selection
  $sel.HomeKey(6) | Out-Null
  $sel.MoveDown(5, 2) | Out-Null
  $sel.TypeParagraph()
  $sel.Style = 'Normal'
  $sel.ParagraphFormat.Alignment = 1
  $sel.Font.Bold = 1
  $sel.TypeText('Version 5.0 Vanguard - Revision date: June 25, 2026')
  $sel.TypeParagraph()
  $sel.Font.Bold = 0
  $sel.ParagraphFormat.Alignment = 0
  $doc.Save() | Out-Null
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

Write-Output 'CONTRACT_OVERVIEW_REVISION_UPDATED'
