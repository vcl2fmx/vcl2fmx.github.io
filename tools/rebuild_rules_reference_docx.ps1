$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')
$html = $GenericRulesReferenceHtmlPath
$docx = $GenericRulesReferenceDocxPath
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
  $doc = $word.Documents.Open($html)
  try {
    $wdFormatXMLDocument = 16
    $doc.SaveAs([ref][object]$docx, [ref][object]$wdFormatXMLDocument) | Out-Null
  }
  finally {
    $doc.Close($true) | Out-Null
  }
}
finally {
  $word.Quit() | Out-Null
}
Write-Output 'DOCX_REBUILT'
