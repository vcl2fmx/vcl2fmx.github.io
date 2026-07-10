$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$docs = @(
  (Join-Path $projectRoot 'docs\guides\VCL2FMXConverter_v5_0_User_Guide.docx'),
  (Join-Path $projectRoot 'docs\guides\VCL2FMXConverter_v5_0_Engineering_Guide.docx')
)

$word = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  foreach ($path in $docs) {
    $doc = $null
    try {
      $doc = $word.Documents.Open($path)
      $ps = $doc.Sections.Item(1).PageSetup
      $text = $doc.Content.Text
      [pscustomobject]@{
        File = [IO.Path]::GetFileName($path)
        Length = (Get-Item -LiteralPath $path).Length
        LeftMargin = [Math]::Round($ps.LeftMargin, 2)
        RightMargin = [Math]::Round($ps.RightMargin, 2)
        TopMargin = [Math]::Round($ps.TopMargin, 2)
        BottomMargin = [Math]::Round($ps.BottomMargin, 2)
        HasV5 = ($text -like '*v5.0*') -or ($text -like '*Version 5.0*')
        HasContracts = ($text -like '*Contracts in v5.0*') -or ($text -like '*v5.0 Conversion Contract System*')
        StaleV418 = ($text -like '*v4.1.8*')
      }
    }
    finally {
      if ($doc -ne $null) {
        $doc.Close($false) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
      }
    }
  }
}
finally {
  if ($word -ne $null) {
    $word.Quit() | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
  }
  [gc]::Collect()
  [gc]::WaitForPendingFinalizers()
}
