param(
  [Parameter(Mandatory = $true)]
  [string]$InputPath,
  [Parameter(Mandatory = $true)]
  [string]$PdfPath,
  [string]$HtmlPath = ''
)

$ErrorActionPreference = 'Stop'
$inputFull = (Resolve-Path -LiteralPath $InputPath).Path
$pdfFull = [IO.Path]::GetFullPath($PdfPath)
$pdfDir = Split-Path -Parent $pdfFull
New-Item -ItemType Directory -Path $pdfDir -Force | Out-Null

if ($HtmlPath -ne '') {
  $htmlFull = [IO.Path]::GetFullPath($HtmlPath)
  New-Item -ItemType Directory -Path (Split-Path -Parent $htmlFull) -Force | Out-Null
}

$word = $null
$doc = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  $doc = $word.Documents.Open($inputFull)
  if ($doc.TablesOfContents.Count -gt 0) {
    $doc.TablesOfContents.Item(1).Update() | Out-Null
    $doc.Save() | Out-Null
  }
  $doc.ExportAsFixedFormat($pdfFull, 17) | Out-Null
  if ($HtmlPath -ne '') {
    $wdFormatFilteredHTML = 10
    $doc.SaveAs([ref][object]$htmlFull, [ref][object]$wdFormatFilteredHTML) | Out-Null
  }
  Write-Output $pdfFull
  if ($HtmlPath -ne '') {
    Write-Output $htmlFull
  }
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
