$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')
$docPath = $EngineeringGuidePath
$word = New-Object -ComObject Word.Application
$word.Visible = $false
try {
  $doc = $word.Documents.Open($docPath)
  $targetTable = $doc.Tables.Item(21)
  $exists = $false
  foreach($row in $targetTable.Rows){
    try {
      $cellText = ($row.Cells.Item(1).Range.Text -replace '[\r\a]','').Trim()
      if($cellText -eq 'Converter.Advanced.WinAPI.pas'){ $exists = $true; break }
    } catch {}
  }
  if(-not $exists){
    $insertAfterRow = $targetTable.Rows.Item(10)
    $newRow = $targetTable.Rows.Add($insertAfterRow)
    $newRow.Cells.Item(1).Range.Text = 'Converter.Advanced.WinAPI.pas'
    $newRow.Cells.Item(2).Range.Text = 'WinAPI-focused conversion rules, color translation, and Windows-specific normalization.'
  }
  $doc.Save()
  $doc.Close()
  'APPENDIX_A_FIXED'
}
finally {
  $word.Quit()
}