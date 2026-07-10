param(
  [string]$HtmlPath,
  [string]$DocxPath
)

$word = $null
$doc = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  $doc = $word.Documents.Open($HtmlPath)
  $doc.SaveAs([ref]$DocxPath, [ref]16)
}
finally {
  if ($doc -ne $null) { $doc.Close([ref]0) }
  if ($word -ne $null) { $word.Quit() }
}
