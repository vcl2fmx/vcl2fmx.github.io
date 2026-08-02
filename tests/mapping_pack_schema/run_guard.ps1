[CmdletBinding()]
param(
  [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$validator = Join-Path $ProjectRoot 'tools\validate_mapping_packs.ps1'
if (-not (Test-Path -LiteralPath $validator -PathType Leaf)) {
  throw "Mapping-pack validator not found: $validator"
}

$workRoot = Join-Path $env:TEMP (
  'VCL2FMXMappingSchema_{0}' -f ([Guid]::NewGuid().ToString('N')))
$encoding = New-Object System.Text.UTF8Encoding($true)
$failures = New-Object 'System.Collections.Generic.List[string]'

function Write-PackFile {
  param([string]$Folder, [string]$Name, [string]$Content)
  New-Item -ItemType Directory -Path $Folder -Force | Out-Null
  [IO.File]::WriteAllText((Join-Path $Folder $Name), $Content, $encoding)
}

function Invoke-ExpectedFailure {
  param([string]$CaseName, [string]$ExpectedPattern)
  $folder = Join-Path $workRoot $CaseName
  $report = Join-Path $folder 'validation.txt'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $validator `
    -ProjectRoot $ProjectRoot -PackFolder $folder -ReportPath $report |
    Out-Null
  if ($LASTEXITCODE -eq 0) {
    $failures.Add("$CaseName unexpectedly passed validation.") | Out-Null
    return
  }
  $reportText = if (Test-Path -LiteralPath $report) {
    [IO.File]::ReadAllText($report)
  }
  else {
    ''
  }
  if ($reportText -notmatch $ExpectedPattern) {
    $failures.Add(
      "$CaseName did not report expected pattern: $ExpectedPattern. Report: " +
      ($reportText -replace '\s+', ' ').Trim()) | Out-Null
  }
}

try {
  $missingSchemaFolder = Join-Path $workRoot 'missing_schema'
  Write-PackFile $missingSchemaFolder 'missing.json' @'
{
  "pack_name": "Missing schema",
  "pack_id": "test.missing.schema",
  "vendor": "Test",
  "version": "1.0.0",
  "description": "Invalid test pack.",
  "mode": "conservative",
  "rules": [
    {
      "vcl_class": "TTestMissingSchema",
      "action": "manual_review",
      "confidence": 0
    }
  ]
}
'@
  Invoke-ExpectedFailure 'missing_schema' 'schema must be exactly'

  $duplicateIdFolder = Join-Path $workRoot 'duplicate_id'
  Write-PackFile $duplicateIdFolder 'first.json' @'
{
  "schema": "vcl2fmx.mapping-pack.v1",
  "pack_name": "First",
  "pack_id": "test.duplicate.id",
  "vendor": "Test",
  "version": "1.0.0",
  "description": "Duplicate ID test.",
  "mode": "conservative",
  "rules": [
    {
      "vcl_class": "TFirstDuplicateId",
      "action": "manual_review",
      "confidence": 0
    }
  ]
}
'@
  Write-PackFile $duplicateIdFolder 'second.json' @'
{
  "schema": "vcl2fmx.mapping-pack.v1",
  "pack_name": "Second",
  "pack_id": "test.duplicate.id",
  "vendor": "Test",
  "version": "1.0.0",
  "description": "Duplicate ID test.",
  "mode": "conservative",
  "rules": [
    {
      "vcl_class": "TSecondDuplicateId",
      "action": "manual_review",
      "confidence": 0
    }
  ]
}
'@
  Invoke-ExpectedFailure 'duplicate_id' 'pack_id duplicates'

  $duplicateClassFolder = Join-Path $workRoot 'duplicate_class'
  Write-PackFile $duplicateClassFolder 'first.json' @'
{
  "schema": "vcl2fmx.mapping-pack.v1",
  "pack_name": "First",
  "pack_id": "test.duplicate.class.first",
  "vendor": "Test",
  "version": "1.0.0",
  "description": "Duplicate class test.",
  "mode": "conservative",
  "rules": [
    {
      "vcl_class": "TDuplicateClass",
      "action": "manual_review",
      "confidence": 0
    }
  ]
}
'@
  Write-PackFile $duplicateClassFolder 'second.json' @'
{
  "schema": "vcl2fmx.mapping-pack.v1",
  "pack_name": "Second",
  "pack_id": "test.duplicate.class.second",
  "vendor": "Test",
  "version": "1.0.0",
  "description": "Duplicate class test.",
  "mode": "conservative",
  "rules": [
    {
      "vcl_class": "TDuplicateClass",
      "action": "manual_review",
      "confidence": 0
    }
  ]
}
'@
  Invoke-ExpectedFailure 'duplicate_class' 'duplicates vcl_class'

  $confidenceFolder = Join-Path $workRoot 'invalid_confidence'
  Write-PackFile $confidenceFolder 'confidence.json' @'
{
  "schema": "vcl2fmx.mapping-pack.v1",
  "pack_name": "Confidence",
  "pack_id": "test.invalid.confidence",
  "vendor": "Test",
  "version": "1.0.0",
  "description": "Confidence test.",
  "mode": "conservative",
  "rules": [
    {
      "vcl_class": "TInvalidConfidence",
      "action": "manual_review",
      "confidence": 101
    }
  ]
}
'@
  Invoke-ExpectedFailure 'invalid_confidence' 'confidence must be an integer'

  $validReport = Join-Path $workRoot 'bundled_validation.txt'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $validator `
    -ProjectRoot $ProjectRoot -ReportPath $validReport | Out-Null
  if ($LASTEXITCODE -ne 0) {
    $failures.Add('Bundled mapping packs failed validation.') | Out-Null
  }

  if ($failures.Count -gt 0) {
    throw ($failures -join [Environment]::NewLine)
  }

  Write-Output (
    'Mapping-pack schema guard passed: bundled packs valid; missing schema, ' +
    'duplicate ID, duplicate class, and invalid confidence were rejected.')
}
finally {
  if (Test-Path -LiteralPath $workRoot) {
    $resolvedWorkRoot = (Resolve-Path -LiteralPath $workRoot).Path
    if ($resolvedWorkRoot.StartsWith($env:TEMP.TrimEnd('\') + '\',
        [StringComparison]::OrdinalIgnoreCase) -and
        ((Split-Path -Leaf $resolvedWorkRoot) -like
          'VCL2FMXMappingSchema_*')) {
      Remove-Item -LiteralPath $resolvedWorkRoot -Recurse -Force
    }
  }
}
