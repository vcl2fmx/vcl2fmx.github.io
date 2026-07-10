$ProjectRoot = Split-Path -Parent $PSScriptRoot
$root = Split-Path -Parent $ProjectRoot
$out = Join-Path $ProjectRoot 'CORPUS_FULL_LAYER_AUDIT_2026-03-22.txt'
$excludeDirPatterns = @(
  '\\FMX ',
  '\\VCL2FMXConverter',
  '\\Old files\\',
  '\\backup',
  '\\recovery_generic',
  '\\ - VCLToFMX - Output',
  '\\Portable',
  '\\Backup Copy'
)

function Include-Path([string]$path) {
  foreach($pat in $excludeDirPatterns){ if($path -match $pat){ return $false } }
  return $true
}

$projects = Get-ChildItem $root -Directory | Where-Object { Include-Path $_.FullName } | Sort-Object Name
$componentCounts = @{}
$projectData = @()

foreach($proj in $projects){
  $dfms = Get-ChildItem $proj.FullName -Recurse -File -Include *.dfm | Where-Object { Include-Path $_.FullName -and $_.Name -notlike '* - Copy.*' }
  $pases = Get-ChildItem $proj.FullName -Recurse -File -Include *.pas | Where-Object { Include-Path $_.FullName -and $_.Name -notlike '* - Copy.*' }
  $dprs = Get-ChildItem $proj.FullName -File -Include *.dpr,*.dproj

  $components = New-Object System.Collections.Generic.List[string]
  foreach($dfm in $dfms){
    $matches = Select-String -Path $dfm.FullName -Pattern '^\s*(object|inherited)\s+\w+\s*:\s*(\w+)' -AllMatches
    foreach($m in $matches){
      $cls = $m.Matches[0].Groups[2].Value
      $components.Add($cls)
      if(-not $componentCounts.ContainsKey($cls)){ $componentCounts[$cls] = 0 }
      $componentCounts[$cls]++
    }
  }

  $allText = ''
  foreach($pas in $pases){ $allText += [IO.File]::ReadAllText($pas.FullName) + "`n" }
  foreach($dfm in $dfms){ $allText += [IO.File]::ReadAllText($dfm.FullName) + "`n" }

  $projectData += [pscustomobject]@{
    Name = $proj.Name
    Path = $proj.FullName
    Dfms = $dfms.Count
    Pases = $pases.Count
    Dprs = $dprs.Count
    Components = ($components | Sort-Object -Unique)
    HasFontDialog = ($allText -match '\bTFontDialog\b')
    HasColorDialog = ($allText -match '\bTColorDialog\b')
    HasPaintBox = ($allText -match '\bTPaintBox\b')
    HasPngImage = ($allText -match '\bTPngImage\b|Vcl\.Imaging\.pngimage')
    HasCustomPaint = ($allText -match '\bCanvas\.|\bDrawText\(|\bLineTo\(|\bMoveTo\(|\bFillRect\(|\bRoundRect\(|\bBrush\.Style\b|\bPen\.Color\b|\bPen\.Width\b')
    HasRadioChecked = ($allText -match '\bTRadioButton\b|\.Checked\b|Checked\s*=\s*True')
    HasTrackbar = ($allText -match '\bTTrackBar\b')
    HasNumberBox = ($allText -match '\bTNumberBox\b')
    HasSpinEdit = ($allText -match '\bTSpinEdit\b')
    HasColorBox = ($allText -match '\bTColorBox\b')
    HasTrayIcon = ($allText -match '\bTTrayIcon\b')
    HasApdComPort = ($allText -match '\bTApdComPort\b')
    HasThreadQueue = ($allText -match '\bTThread\.(Queue|Synchronize)\b')
    HasWaveAudio = ($allText -match '\bHWAVEOUT\b|\bwaveOut\w+\b|\bTWaveHdr\b|\bTWaveFormatEx\b')
  }
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('FULL LAYER CORPUS AUDIT - 2026-03-22')
[void]$sb.AppendLine('====================================')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Projects scanned: ' + $projectData.Count)
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Top source components:')
foreach($item in $componentCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 40){
  [void]$sb.AppendLine(('  {0,-20} {1,4}' -f $item.Key, $item.Value))
}
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Project risk patterns:')
foreach($p in $projectData){
  $flags = @()
  foreach($name in 'HasFontDialog','HasColorDialog','HasPaintBox','HasPngImage','HasCustomPaint','HasRadioChecked','HasTrackbar','HasNumberBox','HasSpinEdit','HasColorBox','HasTrayIcon','HasApdComPort','HasThreadQueue','HasWaveAudio'){
    if($p.$name){ $flags += $name.Replace('Has','') }
  }
  [void]$sb.AppendLine("- $($p.Name): " + ($(if($flags.Count){ $flags -join ', ' } else { 'No flagged risk patterns' })))
}
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Projects needing the SVG/Morse-class generic checks first:')
foreach($p in $projectData | Where-Object { $_.HasFontDialog -or $_.HasColorDialog -or $_.HasPaintBox -or $_.HasPngImage -or $_.HasCustomPaint -or $_.HasWaveAudio -or $_.HasNumberBox }){
  [void]$sb.AppendLine("- $($p.Name)")
}

Set-Content -Path $out -Value $sb.ToString() -Encoding UTF8
Write-Output $out
