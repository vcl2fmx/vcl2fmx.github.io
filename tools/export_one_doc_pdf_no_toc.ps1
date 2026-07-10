param(
  [Parameter(Mandatory = $true)]
  [string]$InputPath,
  [Parameter(Mandatory = $true)]
  [string]$PdfPath
)

$ErrorActionPreference = 'Stop'
$inputFull = (Resolve-Path -LiteralPath $InputPath).Path
$pdfFull = [IO.Path]::GetFullPath($PdfPath)
New-Item -ItemType Directory -Path (Split-Path -Parent $pdfFull) -Force | Out-Null

$word = $null
$doc = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  $doc = $word.Documents.Open($inputFull)
  $doc.ExportAsFixedFormat($pdfFull, 17) | Out-Null
  Write-Output $pdfFull
}
finally {
  if ($doc -ne $null) {
    try { $doc.Close($false) | Out-Null } catch {}
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null } catch {}
  }
  if ($word -ne $null) {
    try { $word.Quit() | Out-Null } catch {}
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null } catch {}
  }
  [gc]::Collect()
  [gc]::WaitForPendingFinalizers()
}
