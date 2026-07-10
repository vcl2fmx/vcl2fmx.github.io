$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')

$outDir = Join-Path $NotesRoot 'guide_inspect'
$out = Join-Path $outDir 'user_ranges.txt'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$word=New-Object -ComObject Word.Application
$word.Visible=$false
$word.DisplayAlerts=0
try {
  $doc=$word.Documents.Open($UserGuidePath,$false,$true)
  try {
    $lines=@()
    foreach($range in @(@(108,116),@(150,160),@(207,220),@(240,246),@(245,253),@(284,301))) {
      $lines += ('--- {0}-{1} ---' -f $range[0],$range[1])
      for($i=$range[0]; $i -le $range[1]; $i++) {
        $p=$doc.Paragraphs.Item($i).Range
        $text=($p.Text -replace '[\r\a]',' ').Trim()
        if($text -eq '') { continue }
        $style=''; try { $style=[string]$p.Style.NameLocal } catch { $style=[string]$p.Style }
        $lines += ('{0:D4}|{1}|{2}' -f $i,$style,$text)
      }
    }
    Set-Content -LiteralPath $out -Value $lines -Encoding UTF8
    Get-Content -LiteralPath $out
  } finally { $doc.Close($false) | Out-Null }
} finally { $word.Quit() | Out-Null }