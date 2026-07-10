$ErrorActionPreference = 'Stop'

$OutputRoot = Join-Path $PSScriptRoot 'output'
$PasFiles = Get-ChildItem -Path $OutputRoot -Filter '*.pas' -Recurse -ErrorAction SilentlyContinue

if ($PasFiles.Count -eq 0) {
  throw "No converted .pas files found under $OutputRoot. Run the converter against tests\manual_review_spill\source first."
}

$Failed = $false
foreach ($File in $PasFiles) {
  $Text = Get-Content -Path $File.FullName -Raw
  $BadPatterns = @(
    '// FMX manual review: public',
    '// FMX manual review: var',
    '// FMX manual review: implementation',
    '// FMX manual review: uses',
    '// FMX manual review: {$R',
    '// FMX manual review: end.'
  )

  foreach ($Pattern in $BadPatterns) {
    if ($Text -like "*$Pattern*") {
      Write-Host "FAIL: $($File.FullName) contains $Pattern"
      $Failed = $true
    }
  }

  if ($Text -notmatch '(?m)^\s*end\.\s*$') {
    Write-Host "FAIL: $($File.FullName) does not have an active final end."
    $Failed = $true
  }
}

if ($Failed) {
  exit 1
}

Write-Host 'MANUAL_REVIEW_SPILL_GUARD_PASS'
