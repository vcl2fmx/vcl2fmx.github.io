[CmdletBinding()]
param(
  [string]$ProjectRoot,
  [string]$PackFolder,
  [string]$ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$schemaVersion = 'vcl2fmx.mapping-pack.v1'
$validModes = @('conservative', 'detection')
$validActions = @('convert', 'partial', 'manual_review', 'detect_only', 'preserve')

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

if ([string]::IsNullOrWhiteSpace($PackFolder)) {
  $PackFolder = Join-Path $ProjectRoot 'mapping_packs'
}
if (-not (Test-Path -LiteralPath $PackFolder -PathType Container)) {
  throw "Mapping-pack folder not found: $PackFolder"
}
$PackFolder = (Resolve-Path -LiteralPath $PackFolder).Path

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
  $reportDir = Join-Path $env:TEMP 'VCL2FMXConverter\mapping_pack_validation'
  New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
  $ReportPath = Join-Path $reportDir (
    'MAPPING_PACK_VALIDATION_{0}.txt' -f (Get-Date -Format 'yyyy-MM-dd_HHmmss'))
}

$errors = New-Object 'System.Collections.Generic.List[string]'
$packIds = @{}
$classOwners = @{}
$files = @(Get-ChildItem -LiteralPath $PackFolder -File -Filter '*.json' |
  Sort-Object Name)
$ruleCount = 0

function Add-ValidationError {
  param([string]$FileName, [string]$Message)
  $errors.Add(('{0}: {1}' -f $FileName, $Message)) | Out-Null
}

function Get-ObjectProperty {
  param([object]$Object, [string]$Name)
  if ($null -eq $Object) {
    return $null
  }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $null
  }
  return $property.Value
}

foreach ($file in $files) {
  try {
    $pack = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 |
      ConvertFrom-Json

    $schema = [string](Get-ObjectProperty $pack 'schema')
    if ($schema -cne $schemaVersion) {
      Add-ValidationError $file.Name (
        'schema must be exactly "{0}"' -f $schemaVersion)
    }

    foreach ($field in @(
      'pack_name', 'pack_id', 'vendor', 'version', 'description', 'mode')) {
      if ([string]::IsNullOrWhiteSpace(
          [string](Get-ObjectProperty $pack $field))) {
        Add-ValidationError $file.Name "missing or blank $field"
      }
    }

    $packId = [string](Get-ObjectProperty $pack 'pack_id')
    $packIdKey = $packId.ToUpperInvariant()
    if (-not [string]::IsNullOrWhiteSpace($packId)) {
      if ($packIds.ContainsKey($packIdKey)) {
        Add-ValidationError $file.Name (
          'pack_id duplicates {0}' -f $packIds[$packIdKey])
      }
      else {
        $packIds[$packIdKey] = $file.Name
      }
    }

    $version = [string](Get-ObjectProperty $pack 'version')
    if ($version -notmatch '^\d+\.\d+\.\d+$') {
      Add-ValidationError $file.Name 'version must use major.minor.patch'
    }

    $mode = ([string](Get-ObjectProperty $pack 'mode')).ToLowerInvariant()
    if ($validModes -notcontains $mode) {
      Add-ValidationError $file.Name (
        'mode must be one of: {0}' -f ($validModes -join ', '))
    }

    $rulesProperty = $pack.PSObject.Properties['rules']
    $rules = if ($null -eq $rulesProperty) { @() } else { @($rulesProperty.Value) }
    if ($rules.Count -eq 0) {
      Add-ValidationError $file.Name 'rules must be a non-empty array'
      continue
    }

    $localClasses = @{}
    for ($ruleIndex = 0; $ruleIndex -lt $rules.Count; $ruleIndex++) {
      $rule = $rules[$ruleIndex]
      $location = 'rule {0}' -f ($ruleIndex + 1)
      $vclClass = [string](Get-ObjectProperty $rule 'vcl_class')
      $action = ([string](Get-ObjectProperty $rule 'action')).ToLowerInvariant()
      $confidenceValue = Get-ObjectProperty $rule 'confidence'

      if ([string]::IsNullOrWhiteSpace($vclClass)) {
        Add-ValidationError $file.Name "$location has no vcl_class"
        continue
      }
      if ($vclClass -notmatch '^[A-Za-z_][A-Za-z0-9_.]*$') {
        Add-ValidationError $file.Name (
          "$location has invalid vcl_class ""$vclClass""")
      }

      $classKey = $vclClass.ToUpperInvariant()
      if ($localClasses.ContainsKey($classKey)) {
        Add-ValidationError $file.Name (
          "$location duplicates vcl_class ""$vclClass"" within the pack")
      }
      else {
        $localClasses[$classKey] = $true
      }
      if ($classOwners.ContainsKey($classKey)) {
        Add-ValidationError $file.Name (
          "$location duplicates vcl_class ""$vclClass"" from " +
          $classOwners[$classKey])
      }
      else {
        $classOwners[$classKey] = $file.Name
      }

      if ($validActions -notcontains $action) {
        Add-ValidationError $file.Name (
          "$location uses unsupported action ""$action""")
      }

      $confidence = 0
      if (($null -eq $confidenceValue) -or
          (-not [int]::TryParse([string]$confidenceValue, [ref]$confidence)) -or
          ($confidence -lt 0) -or ($confidence -gt 100)) {
        Add-ValidationError $file.Name (
          "$location confidence must be an integer from 0 through 100")
      }

      foreach ($mappingProperty in @('properties', 'property_maps',
          'events', 'event_maps')) {
        $mappingRows = Get-ObjectProperty $rule $mappingProperty
        if ($null -eq $mappingRows) {
          continue
        }
        foreach ($row in @($mappingRows)) {
          if ($null -eq $row) {
            Add-ValidationError $file.Name (
              "$location contains a null $mappingProperty row")
          }
        }
      }
      $ruleCount++
    }
  }
  catch {
    Add-ValidationError $file.Name $_.Exception.Message
  }
}

$report = New-Object System.Text.StringBuilder
[void]$report.AppendLine('VCL2FMXConverter Mapping-Pack Validation')
[void]$report.AppendLine(('Schema: {0}' -f $schemaVersion))
[void]$report.AppendLine(('Folder: {0}' -f $PackFolder))
[void]$report.AppendLine(('Packs: {0}' -f $files.Count))
[void]$report.AppendLine(('Rules: {0}' -f $ruleCount))
[void]$report.AppendLine(('Errors: {0}' -f $errors.Count))
[void]$report.AppendLine('')
if ($errors.Count -eq 0) {
  [void]$report.AppendLine('PASS: all mapping packs satisfy the schema and uniqueness rules.')
}
else {
  foreach ($validationError in $errors) {
    [void]$report.AppendLine(('ERROR: {0}' -f $validationError))
  }
}

$reportDirectory = Split-Path -Parent $ReportPath
if (-not [string]::IsNullOrWhiteSpace($reportDirectory)) {
  New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
}
[IO.File]::WriteAllText($ReportPath, $report.ToString(),
  (New-Object System.Text.UTF8Encoding($true)))

Write-Output ('Mapping-pack validation report: ' + $ReportPath)
Write-Output ('Summary: {0} pack(s), {1} rule(s), {2} error(s)' -f
  $files.Count, $ruleCount, $errors.Count)

if ($errors.Count -gt 0) {
  exit 1
}
