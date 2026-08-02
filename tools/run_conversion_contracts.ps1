[CmdletBinding()]
param(
  [string]$ProjectRoot,
  [string]$FixtureRoot,
  [string]$OutputRoot,
  [string]$ConverterExe,
  [switch]$EnforceCoverage,
  [switch]$CompileGenerated,
  [string]$Dcc32Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}

$ProjectRoot = (Resolve-Path $ProjectRoot).Path

if ([string]::IsNullOrWhiteSpace($FixtureRoot)) {
  $FixtureRoot = Join-Path $ProjectRoot 'contracts'
}
$FixtureRoot = (Resolve-Path $FixtureRoot).Path

$usesTemporaryOutputRoot = [string]::IsNullOrWhiteSpace($OutputRoot)
if ($usesTemporaryOutputRoot) {
  $OutputRoot = Join-Path $env:TEMP (
    'VCL2FMXContracts_{0}' -f ([Guid]::NewGuid().ToString('N')))
}
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$outputRootLeaf = Split-Path -Leaf $OutputRoot
if (($OutputRoot -eq [System.IO.Path]::GetPathRoot($OutputRoot)) -or
    ($OutputRoot.TrimEnd('\') -eq $ProjectRoot.TrimEnd('\')) -or
    [string]::IsNullOrWhiteSpace($outputRootLeaf)) {
  throw "Unsafe contract output root rejected: $OutputRoot"
}

if ([string]::IsNullOrWhiteSpace($ConverterExe)) {
  $ConverterExe = Join-Path $ProjectRoot 'tools\RunConversionEngine.exe'
}

if (-not (Test-Path -LiteralPath $ConverterExe)) {
  throw "Converter executable not found: $ConverterExe"
}

$ConverterExe = (Resolve-Path $ConverterExe).Path
$runnerSourceFiles = @(
  Get-ChildItem -LiteralPath $ProjectRoot -File |
    Where-Object { ($_.Name -like 'Converter.*.pas') -or ($_.Name -eq 'VCL2FMXConverter.dpr') }
  Get-Item -LiteralPath (Join-Path $ProjectRoot 'tools\RunConversionEngine.dpr')
)
$converterExeInfo = Get-Item -LiteralPath $ConverterExe
$newerRunnerSources = @(
  $runnerSourceFiles |
    Where-Object { $_.LastWriteTimeUtc -gt $converterExeInfo.LastWriteTimeUtc } |
    Sort-Object LastWriteTimeUtc -Descending
)
if ($newerRunnerSources.Count -gt 0) {
  $newestSource = $newerRunnerSources[0]
  throw ('Stale contract runner rejected. Rebuild {0}; source {1} is newer ({2:o}) than the executable ({3:o}).' -f
    $ConverterExe,
    $newestSource.FullName,
    $newestSource.LastWriteTimeUtc,
    $converterExeInfo.LastWriteTimeUtc)
}

$runnerHash = (Get-FileHash -LiteralPath $ConverterExe -Algorithm SHA256).Hash
$newestRunnerSource = $runnerSourceFiles | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
$runStartedUtc = [DateTime]::UtcNow
Write-Output 'Contract runner provenance:'
Write-Output ('  Started UTC: {0:o}' -f $runStartedUtc)
Write-Output ('  Executable: {0}' -f $ConverterExe)
Write-Output ('  Executable UTC: {0:o}' -f $converterExeInfo.LastWriteTimeUtc)
Write-Output ('  Executable SHA-256: {0}' -f $runnerHash)
Write-Output ('  Newest source: {0}' -f $newestRunnerSource.FullName)
Write-Output ('  Newest source UTC: {0:o}' -f $newestRunnerSource.LastWriteTimeUtc)

function Assert-UnderOutputRoot {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $rootWithSlash = $OutputRoot.TrimEnd('\') + '\'
  if (-not ($fullPath.StartsWith($rootWithSlash, [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "Refusing to use path outside contract output root: $fullPath"
  }
  return $fullPath
}

function ConvertTo-RelativePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $uriRoot = [System.Uri]::new($ProjectRoot.TrimEnd('\') + '\')
  $uriPath = [System.Uri]::new(([System.IO.Path]::GetFullPath($Path)))
  return [System.Uri]::UnescapeDataString($uriRoot.MakeRelativeUri($uriPath).ToString()).Replace('/', '\')
}

function Get-JsonArray {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object.PSObject.Properties[$Name]) {
    return @()
  }

  $value = $Object.$Name
  if ($null -eq $value) {
    return @()
  }

  return @($value)
}

function Read-TextFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $bytes = [System.IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -eq 0) {
    return ''
  }

  if (($bytes.Length -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)) {
    return [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
  }

  if (($bytes.Length -ge 2) -and ($bytes[0] -eq 0xFF) -and ($bytes[1] -eq 0xFE)) {
    return [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
  }

  if (($bytes.Length -ge 2) -and ($bytes[0] -eq 0xFE) -and ($bytes[1] -eq 0xFF)) {
    return [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
  }

  try {
    $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
    return $strictUtf8.GetString($bytes)
  }
  catch {
    return [System.Text.Encoding]::Default.GetString($bytes)
  }
}

function Normalize-ReportArtifact {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text,
    [Parameter(Mandatory = $true)]
    [string]$CaseRoot
  )

  $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
  $normalized = [regex]::Replace(
    $normalized, [regex]::Escape($CaseRoot.Replace('\', '\\')),
    '<CASE_ROOT>',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $normalized = [regex]::Replace(
    $normalized, [regex]::Escape($CaseRoot), '<CASE_ROOT>',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $normalized = [regex]::Replace(
    $normalized, [regex]::Escape($ProjectRoot.Replace('\', '\\')),
    '<PROJECT_ROOT>',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $normalized = [regex]::Replace(
    $normalized, [regex]::Escape($ProjectRoot), '<PROJECT_ROOT>',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $normalized = [regex]::Replace(
    $normalized, '(?m)^Total time:.*$', 'Total time: <DURATION>')
  $normalized = [regex]::Replace(
    $normalized,
    '(<div class="label">Run time</div><div class="value">).*?(</div>)',
    '$1<DURATION>$2')
  $normalized = [regex]::Replace(
    $normalized, 'Generated \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}',
    'Generated <TIMESTAMP>')
  $normalized = [regex]::Replace(
    $normalized, '\[\d{2}:\d{2}:\d{2}\]', '[TIME]')
  $normalized = [regex]::Replace(
    $normalized, '(?m)(Conversion completed in ).*$',
    '$1<DURATION>')
  return $normalized
}

function Get-TextSha256 {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text
  )

  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Text)
    return ([System.BitConverter]::ToString(
      $sha256.ComputeHash($bytes))).Replace('-', '')
  }
  finally {
    $sha256.Dispose()
  }
}

function Test-TextPattern {
  param(
    [string]$Text,
    [string]$Pattern
  )

  return [regex]::IsMatch($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

function Get-CaseName {
  param(
    [string]$InputFile
  )

  $relative = ConvertTo-RelativePath -Path $InputFile
  return ($relative -replace '[:\\\/\. ]+', '_').Trim('_')
}

function Get-PascalUnitName {
  param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath
  )

  $text = Read-TextFile -Path $InputPath
  $match = [regex]::Match($text, '(?im)^\s*unit\s+([A-Za-z_][A-Za-z0-9_]*)\s*;')
  if ($match.Success) {
    return $match.Groups[1].Value
  }

  return [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
}

function Resolve-Dcc32Path {
  if (-not [string]::IsNullOrWhiteSpace($Dcc32Path)) {
    if (-not (Test-Path -LiteralPath $Dcc32Path -PathType Leaf)) {
      throw "dcc32.exe not found: $Dcc32Path"
    }
    return (Resolve-Path $Dcc32Path).Path
  }

  $command = Get-Command dcc32.exe -ErrorAction SilentlyContinue
  if ($null -ne $command) {
    return $command.Source
  }

  foreach ($candidate in @(
    'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe',
    'C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc32.exe',
    'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\dcc32.exe',
    'C:\Program Files (x86)\Embarcadero\Studio\21.0\bin\dcc32.exe'
  )) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      return $candidate
    }
  }

  throw 'CompileGenerated was requested, but dcc32.exe could not be found. Pass -Dcc32Path with the compiler path.'
}

function Invoke-GeneratedCompile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$CaseOutput,
    [Parameter(Mandatory = $true)]
    [string]$CaseRoot,
    [Parameter(Mandatory = $true)]
    [string]$CompilerPath
  )

  $projects = @(Get-ChildItem -LiteralPath $CaseOutput -Recurse -File -Filter '*.dpr' -ErrorAction SilentlyContinue)
  if ($projects.Count -eq 0) {
    return 'No generated .dpr found to compile.'
  }

  $compileRoot = Join-Path $CaseRoot 'compile'
  $binDir = Join-Path $compileRoot 'bin'
  $dcuDir = Join-Path $compileRoot 'dcu'
  New-Item -ItemType Directory -Path $binDir -Force | Out-Null
  New-Item -ItemType Directory -Path $dcuDir -Force | Out-Null

  $failures = New-Object 'System.Collections.Generic.List[string]'
  foreach ($project in $projects) {
    $searchDirs = New-Object 'System.Collections.Generic.List[string]'
    $searchDirs.Add($CaseOutput) | Out-Null
    foreach ($directory in Get-ChildItem -LiteralPath $CaseOutput -Recurse -Directory -ErrorAction SilentlyContinue) {
      $searchDirs.Add($directory.FullName) | Out-Null
    }
    $searchPath = [string]::Join(';', $searchDirs)

    $args = @(
      '-Q',
      '-B',
      '-M',
      ('-E' + $binDir),
      ('-N0' + $dcuDir),
      ('-U' + $searchPath),
      ('-I' + $searchPath),
      $project.FullName
    )

    $output = & $CompilerPath @args 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
      $summary = ($output | Select-Object -Last 12) -join ' '
      $failures.Add("Generated project failed to compile: $(ConvertTo-RelativePath -Path $project.FullName). $summary") | Out-Null
    }
  }

  if ($failures.Count -gt 0) {
    return [string]::Join('; ', $failures)
  }

  return ''
}

function Invoke-ContractCase {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ExpectationPath
  )

  $expectationText = Read-TextFile -Path $ExpectationPath
  $expectation = $expectationText | ConvertFrom-Json

  if ($null -eq $expectation.PSObject.Properties['input_file']) {
    throw "Expectation is missing input_file: $ExpectationPath"
  }

  $inputPath = Join-Path $ProjectRoot $expectation.input_file
  if (-not (Test-Path -LiteralPath $inputPath)) {
    return [pscustomobject]@{
      Status = 'Fail'
      Case = ConvertTo-RelativePath -Path $ExpectationPath
      Details = "Input file not found: $($expectation.input_file)"
    }
  }

  $caseName = Get-CaseName -InputFile $inputPath
  $caseRoot = Assert-UnderOutputRoot (Join-Path $OutputRoot $caseName)
  $caseSource = Join-Path $caseRoot 'source'
  $caseOutput = Join-Path $caseRoot 'output'

  if (Test-Path -LiteralPath $caseRoot) {
    $resolvedCaseRoot = Assert-UnderOutputRoot $caseRoot
    Remove-Item -LiteralPath $resolvedCaseRoot -Recurse -Force
  }

  New-Item -ItemType Directory -Path $caseSource -Force | Out-Null
  New-Item -ItemType Directory -Path $caseOutput -Force | Out-Null

  $copyCaseDirectory = ($null -ne $expectation.PSObject.Properties['copy_case_directory']) -and
    ([bool]$expectation.copy_case_directory)

  if ($copyCaseDirectory) {
    $caseInputDirectory = Split-Path -Parent $inputPath
    Get-ChildItem -LiteralPath $caseInputDirectory -Force | ForEach-Object {
      Copy-Item -LiteralPath $_.FullName -Destination $caseSource -Recurse -Force
    }
  }
  else {
    Copy-Item -LiteralPath $inputPath -Destination (Join-Path $caseSource (Split-Path -Leaf $inputPath)) -Force
  }

  $inputDirectory = Split-Path -Parent $inputPath
  foreach ($includeFile in Get-ChildItem -LiteralPath $inputDirectory -Recurse -File -Filter '*.inc' -ErrorAction SilentlyContinue) {
    $includeRootUri = [System.Uri]::new($inputDirectory.TrimEnd('\') + '\')
    $includeFileUri = [System.Uri]::new($includeFile.FullName)
    $relativeInclude = [System.Uri]::UnescapeDataString($includeRootUri.MakeRelativeUri($includeFileUri).ToString()).Replace('/', '\')
    $targetInclude = Join-Path $caseSource $relativeInclude
    $targetIncludeDirectory = Split-Path -Parent $targetInclude
    if (-not (Test-Path -LiteralPath $targetIncludeDirectory)) {
      New-Item -ItemType Directory -Path $targetIncludeDirectory -Force | Out-Null
    }
    Copy-Item -LiteralPath $includeFile.FullName -Destination $targetInclude -Force
  }

  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputPath)
  foreach ($companionExt in @('.dfm', '.res', '.inc')) {
    $companion = Join-Path (Split-Path -Parent $inputPath) ($baseName + $companionExt)
    if (Test-Path -LiteralPath $companion) {
      Copy-Item -LiteralPath $companion -Destination (Join-Path $caseSource (Split-Path -Leaf $companion)) -Force
    }
  }

  if ([System.IO.Path]::GetExtension($inputPath).Equals('.pas', [System.StringComparison]::OrdinalIgnoreCase)) {
    $unitName = Get-PascalUnitName -InputPath $inputPath
    $dprText = @"
program ContractHarness;

uses
  System.StartUpCopy,
  FMX.Forms,
  $unitName in '$baseName.pas';

begin
  Application.Initialize;
  Application.Run;
end.
"@
    [System.IO.File]::WriteAllText((Join-Path $caseSource 'ContractHarness.dpr'), $dprText, [System.Text.UTF8Encoding]::new($true))
  }

  $engineArgs = @()
  foreach ($arg in Get-JsonArray -Object $expectation -Name 'engine_args') {
    $engineArgs += [string]$arg
  }

  $caseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  & $ConverterExe $caseSource $caseOutput @engineArgs
  $exitCode = $LASTEXITCODE
  $caseStopwatch.Stop()
  $durationMs = $caseStopwatch.ElapsedMilliseconds

  $generatedParts = New-Object 'System.Collections.Generic.List[string]'
  foreach ($file in Get-ChildItem -LiteralPath $caseOutput -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object {
        ($_.Extension -in @('.pas', '.fmx', '.dpr', '.inc', '.json')) -and
        -not (($_.Extension -eq '.json') -and
          ($_.Name -like '*Report*.json'))
      }) {
    $generatedParts.Add((Read-TextFile -Path $file.FullName)) | Out-Null
  }
  $generatedText = [string]::Join("`n", $generatedParts)

  $reportParts = New-Object 'System.Collections.Generic.List[string]'
  foreach ($file in Get-ChildItem -LiteralPath $caseOutput -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object {
        ($_.Name -like '*Report*.txt') -or
        ($_.Name -like '*Report*.html')
      }) {
    $reportParts.Add((Read-TextFile -Path $file.FullName)) | Out-Null
  }
  $reportText = [string]::Join("`n", $reportParts)
  $textReportPath = Join-Path $caseOutput 'VCL_to_FMX_Conversion_Report.txt'
  $htmlReportPath = Join-Path $caseOutput 'VCL_to_FMX_Conversion_Report.html'
  $textReport = if (Test-Path -LiteralPath $textReportPath -PathType Leaf) {
    Read-TextFile -Path $textReportPath
  }
  else {
    ''
  }
  $htmlReport = if (Test-Path -LiteralPath $htmlReportPath -PathType Leaf) {
    Read-TextFile -Path $htmlReportPath
  }
  else {
    ''
  }

  $failures = New-Object 'System.Collections.Generic.List[string]'

  foreach ($reportGolden in @(
    [pscustomobject]@{
      Field = 'expected_normalized_text_report_sha256'
      File = $textReportPath
      Label = 'text'
    },
    [pscustomobject]@{
      Field = 'expected_normalized_html_report_sha256'
      File = $htmlReportPath
      Label = 'HTML'
    },
    [pscustomobject]@{
      Field = 'expected_normalized_json_report_sha256'
      File = Join-Path $caseOutput 'VCL_to_FMX_Conversion_Report.json'
      Label = 'JSON'
    }
  )) {
    if (($null -ne $expectation.PSObject.Properties[$reportGolden.Field]) -and
        -not [string]::IsNullOrWhiteSpace([string]$expectation.($reportGolden.Field))) {
      if (-not (Test-Path -LiteralPath $reportGolden.File -PathType Leaf)) {
        $failures.Add("Expected $($reportGolden.Label) report for normalized golden comparison.") | Out-Null
        continue
      }

      $normalizedReport = Normalize-ReportArtifact `
        -Text (Read-TextFile -Path $reportGolden.File) -CaseRoot $caseRoot
      $actualHash = Get-TextSha256 -Text $normalizedReport
      $expectedHash = ([string]$expectation.($reportGolden.Field)).ToUpperInvariant()
      if ($actualHash -ne $expectedHash) {
        $failures.Add(
          "Normalized $($reportGolden.Label) report SHA-256 mismatch: $actualHash != $expectedHash.") | Out-Null
      }
    }
  }

  foreach ($reportPatternSet in @(
    [pscustomobject]@{
      Field = 'expected_text_report_patterns'
      Text = $textReport
      Label = 'text'
    },
    [pscustomobject]@{
      Field = 'expected_html_report_patterns'
      Text = $htmlReport
      Label = 'HTML'
    }
  )) {
    foreach ($pattern in Get-JsonArray -Object $expectation -Name $reportPatternSet.Field) {
      if (-not (Test-TextPattern -Text $reportPatternSet.Text -Pattern ([string]$pattern))) {
        $failures.Add("Expected $($reportPatternSet.Label) report pattern not found: $pattern") | Out-Null
      }
    }
  }

  foreach ($orderedPatternSet in @(
    [pscustomobject]@{
      Field = 'expected_text_report_ordered_patterns'
      Text = $textReport
      Label = 'text'
    },
    [pscustomobject]@{
      Field = 'expected_html_report_ordered_patterns'
      Text = $htmlReport
      Label = 'HTML'
    }
  )) {
    $searchStart = 0
    foreach ($pattern in Get-JsonArray -Object $expectation -Name $orderedPatternSet.Field) {
      $patternRegex = [regex]::new(
        [string]$pattern,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
      $patternMatch = $patternRegex.Match($orderedPatternSet.Text, $searchStart)
      if (-not $patternMatch.Success) {
        $failures.Add(
          "Expected $($orderedPatternSet.Label) report ordered pattern not found after offset ${searchStart}: $pattern") |
          Out-Null
        break
      }
      $searchStart = $patternMatch.Index + $patternMatch.Length
    }
  }

  foreach ($parityCheck in Get-JsonArray -Object $expectation -Name 'expected_text_html_parity') {
    $label = if (($null -ne $parityCheck.PSObject.Properties['label']) -and
        -not [string]::IsNullOrWhiteSpace([string]$parityCheck.label)) {
      [string]$parityCheck.label
    }
    else {
      'unnamed parity check'
    }
    if (($null -eq $parityCheck.PSObject.Properties['text_pattern']) -or
        -not (Test-TextPattern -Text $textReport -Pattern ([string]$parityCheck.text_pattern))) {
      $failures.Add("Text/HTML parity '$label' is missing from the text report.") | Out-Null
    }
    if (($null -eq $parityCheck.PSObject.Properties['html_pattern']) -or
        -not (Test-TextPattern -Text $htmlReport -Pattern ([string]$parityCheck.html_pattern))) {
      $failures.Add("Text/HTML parity '$label' is missing from the HTML report.") | Out-Null
    }
  }

  if (($null -ne $expectation.PSObject.Properties['max_duration_ms']) -and
      ($durationMs -gt [int64]$expectation.max_duration_ms)) {
    $failures.Add("Conversion exceeded max_duration_ms ($durationMs > $($expectation.max_duration_ms)).") | Out-Null
  }

  $noGeneratedSourceFiles = (($null -ne $expectation.PSObject.Properties['expected_no_generated_source_files']) -and
      ([bool]$expectation.expected_no_generated_source_files)) -or
    (($null -ne $expectation.PSObject.Properties['expected_no_output_files']) -and
      ([bool]$expectation.expected_no_output_files))
  if ($noGeneratedSourceFiles) {
    $artifactFiles = @(Get-ChildItem -LiteralPath $caseOutput -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object {
        ($_.Extension -in @('.pas', '.fmx', '.dpr', '.inc', '.dfm')) -and
        ($_.Name -notlike '*Report*')
      })
    if ($artifactFiles.Count -gt 0) {
      $failures.Add("Expected no converted artifact files, but found $($artifactFiles.Count).") | Out-Null
    }
  }

  if (($null -ne $expectation.PSObject.Properties['expected_report_files']) -and
      ([bool]$expectation.expected_report_files)) {
    $reportFiles = @(Get-ChildItem -LiteralPath $caseOutput -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { ($_.Name -like '*Report*.txt') -or ($_.Name -like '*Report*.html') })
    if ($reportFiles.Count -eq 0) {
      $failures.Add('Expected at least one conversion report file.') | Out-Null
    }
  }

  foreach ($auxiliaryFileName in Get-JsonArray -Object $expectation -Name 'expected_auxiliary_files') {
    $auxiliaryFiles = @(Get-ChildItem -LiteralPath $caseOutput -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -eq [string]$auxiliaryFileName })
    if ($auxiliaryFiles.Count -eq 0) {
      $failures.Add("Expected auxiliary output file '$auxiliaryFileName' was not found.") | Out-Null
    }
    elseif ([System.IO.Path]::GetExtension([string]$auxiliaryFileName) -ieq '.json') {
      try {
        $null = Read-TextFile -Path $auxiliaryFiles[0].FullName | ConvertFrom-Json
      }
      catch {
        $failures.Add(
          "Auxiliary JSON '$auxiliaryFileName' is not parseable: $($_.Exception.Message)") |
          Out-Null
      }
    }
  }

  foreach ($auxiliaryCheck in Get-JsonArray -Object $expectation -Name 'expected_auxiliary_patterns') {
    if (($null -eq $auxiliaryCheck.PSObject.Properties['file']) -or
        [string]::IsNullOrWhiteSpace([string]$auxiliaryCheck.file)) {
      $failures.Add('An expected_auxiliary_patterns entry has no file name.') | Out-Null
      continue
    }
    $auxiliaryFiles = @(Get-ChildItem -LiteralPath $caseOutput -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -eq [string]$auxiliaryCheck.file })
    if ($auxiliaryFiles.Count -eq 0) {
      $failures.Add(
        "Auxiliary pattern target '$($auxiliaryCheck.file)' was not found.") |
        Out-Null
      continue
    }
    $auxiliaryText = Read-TextFile -Path $auxiliaryFiles[0].FullName
    foreach ($pattern in Get-JsonArray -Object $auxiliaryCheck -Name 'patterns') {
      if (-not (Test-TextPattern -Text $auxiliaryText -Pattern ([string]$pattern))) {
        $failures.Add(
          "Auxiliary file '$($auxiliaryCheck.file)' is missing pattern '$pattern'.") |
          Out-Null
      }
    }
  }

  $jsonReportFiles = @(Get-ChildItem -LiteralPath $caseOutput -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like '*Report*.json' })
  foreach ($jsonReportFile in $jsonReportFiles) {
    try {
      $jsonReport = Read-TextFile -Path $jsonReportFile.FullName | ConvertFrom-Json
      if ([string]$jsonReport.schemaVersion -cne 'vcl2fmx.report.v1') {
        $failures.Add(
          "JSON report '$($jsonReportFile.Name)' has an unsupported schemaVersion.") |
          Out-Null
      }
      foreach ($requiredReportField in @(
          'summary', 'issues', 'manualGroups', 'mappingPacks',
          'mappingUsages', 'conversionLog')) {
        if ($null -eq $jsonReport.PSObject.Properties[$requiredReportField]) {
          $failures.Add(
            "JSON report '$($jsonReportFile.Name)' is missing $requiredReportField.") |
            Out-Null
        }
      }
      if (($null -ne $jsonReport.PSObject.Properties['summary']) -and
          ([int]$jsonReport.summary.visibleIssues -lt 0)) {
        $failures.Add(
          "JSON report '$($jsonReportFile.Name)' has a negative visibleIssues count.") |
          Out-Null
      }
    }
    catch {
      $failures.Add(
        "JSON report '$($jsonReportFile.Name)' is not parseable: $($_.Exception.Message)") |
        Out-Null
    }
  }

  if (($null -ne $expectation.PSObject.Properties['expected_output_encoding']) -and
      -not [string]::IsNullOrWhiteSpace([string]$expectation.expected_output_encoding)) {
    $encodingName = [string]$expectation.expected_output_encoding
    if ($encodingName -eq 'utf8-bom') {
      $encodingFiles = @(Get-ChildItem -LiteralPath $caseOutput -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @('.pas', '.fmx', '.dpr', '.dpk', '.dfm', '.inc') })
      foreach ($encodingFile in $encodingFiles) {
        $encodingBytes = [System.IO.File]::ReadAllBytes($encodingFile.FullName)
        if (($encodingBytes.Length -lt 3) -or
            ($encodingBytes[0] -ne 0xEF) -or
            ($encodingBytes[1] -ne 0xBB) -or
            ($encodingBytes[2] -ne 0xBF)) {
          $failures.Add("Expected UTF-8 BOM in generated file '$($encodingFile.Name)'.") | Out-Null
        }
      }
      if ($encodingFiles.Count -eq 0) {
        $failures.Add('Expected at least one generated source file for UTF-8 BOM validation.') | Out-Null
      }
    }
    else {
      $failures.Add("Unsupported expected_output_encoding '$encodingName'.") | Out-Null
    }
  }

  $expectedStatus = if ($null -ne $expectation.PSObject.Properties['expected_status']) { [string]$expectation.expected_status } else { 'converted' }
  if ($expectedStatus -eq 'converted') {
    if (($exitCode -ne 0) -and ($exitCode -ne 2)) {
      $failures.Add("Expected converted status but converter exited $exitCode.") | Out-Null
    }
  }
  elseif ($expectedStatus -eq 'success') {
    if ($exitCode -ne 0) {
      $failures.Add("Expected success status but converter exited $exitCode.") | Out-Null
    }
  }
  elseif ($expectedStatus -eq 'failure') {
    if ($exitCode -eq 0) {
      $failures.Add('Expected failure status but converter exited 0.') | Out-Null
    }
  }
  else {
    $failures.Add("Unknown expected_status '$expectedStatus'.") | Out-Null
  }

  foreach ($unitName in Get-JsonArray -Object $expectation -Name 'expected_units_added') {
    $pattern = '\b' + [regex]::Escape([string]$unitName) + '\b'
    if (-not (Test-TextPattern -Text $generatedText -Pattern $pattern)) {
      $failures.Add("Expected generated unit '$unitName' was not found.") | Out-Null
    }
  }

  foreach ($unitName in Get-JsonArray -Object $expectation -Name 'expected_units_absent') {
    $pattern = '\b' + [regex]::Escape([string]$unitName) + '\b'
    if (Test-TextPattern -Text $generatedText -Pattern $pattern) {
      $failures.Add("Forbidden generated unit '$unitName' was found.") | Out-Null
    }
  }

  foreach ($pattern in Get-JsonArray -Object $expectation -Name 'expected_output_patterns') {
    if (-not (Test-TextPattern -Text $generatedText -Pattern ([string]$pattern))) {
      $failures.Add("Expected generated-output pattern not found: $pattern") | Out-Null
    }
  }

  foreach ($pattern in Get-JsonArray -Object $expectation -Name 'forbidden_output_patterns') {
    if (Test-TextPattern -Text $generatedText -Pattern ([string]$pattern)) {
      $failures.Add("Forbidden generated-output pattern found: $pattern") | Out-Null
    }
  }

  foreach ($pattern in Get-JsonArray -Object $expectation -Name 'expected_report_patterns') {
    if (-not (Test-TextPattern -Text $reportText -Pattern ([string]$pattern))) {
      $failures.Add("Expected report pattern not found: $pattern") | Out-Null
    }
  }

  foreach ($pattern in Get-JsonArray -Object $expectation -Name 'forbidden_report_patterns') {
    if (Test-TextPattern -Text $reportText -Pattern ([string]$pattern)) {
      $failures.Add("Forbidden report pattern found: $pattern") | Out-Null
    }
  }

  $skipGeneratedCompile = ($null -ne $expectation.PSObject.Properties['skip_generated_compile']) -and
    ([bool]$expectation.skip_generated_compile)
  if ($CompileGenerated -and -not $skipGeneratedCompile) {
    $compileProblem = Invoke-GeneratedCompile -CaseOutput $caseOutput -CaseRoot $caseRoot -CompilerPath $script:Dcc32ResolvedPath
    if (-not [string]::IsNullOrWhiteSpace($compileProblem)) {
      $failures.Add($compileProblem) | Out-Null
    }
  }

  if ($failures.Count -eq 0) {
    return [pscustomobject]@{
      Status = 'Pass'
      Case = $expectation.input_file
      Details = "Output: $(ConvertTo-RelativePath -Path $caseOutput)"
    }
  }

  return [pscustomobject]@{
    Status = 'Fail'
    Case = $expectation.input_file
    Details = [string]::Join('; ', $failures)
  }
}

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

if ($CompileGenerated) {
  $script:Dcc32ResolvedPath = Resolve-Dcc32Path
}

$expectationFiles = @(Get-ChildItem -LiteralPath $FixtureRoot -Recurse -File -Filter '*.expected.json')
if ($expectationFiles.Count -eq 0) {
  throw "No contract expectation files found under $FixtureRoot"
}

$results = New-Object 'System.Collections.Generic.List[object]'
foreach ($expectationFile in $expectationFiles) {
  $results.Add((Invoke-ContractCase -ExpectationPath $expectationFile.FullName)) | Out-Null
}

  if ($EnforceCoverage) {
  $expectedInputs = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($expectationFile in $expectationFiles) {
    $expectation = Read-TextFile -Path $expectationFile.FullName | ConvertFrom-Json
    if ($null -ne $expectation.PSObject.Properties['input_file']) {
      [void]$expectedInputs.Add((Join-Path $ProjectRoot $expectation.input_file))
      $copyCaseDirectory = ($null -ne $expectation.PSObject.Properties['copy_case_directory']) -and
        ([bool]$expectation.copy_case_directory)
      if ($copyCaseDirectory) {
        $inputPath = Join-Path $ProjectRoot $expectation.input_file
        $inputDirectory = Split-Path -Parent $inputPath
        foreach ($coveredFixture in Get-ChildItem -LiteralPath $inputDirectory -Recurse -File | Where-Object { $_.Extension -in @('.pas', '.dpr') }) {
          [void]$expectedInputs.Add($coveredFixture.FullName)
        }
      }
    }
  }

  foreach ($fixture in Get-ChildItem -LiteralPath $FixtureRoot -Recurse -File | Where-Object { $_.Extension -in @('.pas', '.dpr') }) {
    if (-not $expectedInputs.Contains($fixture.FullName)) {
      $results.Add([pscustomobject]@{
        Status = 'Fail'
        Case = ConvertTo-RelativePath -Path $fixture.FullName
        Details = 'Missing sibling .expected.json contract expectation.'
      }) | Out-Null
    }
  }
}

$passCount = @($results | Where-Object { $_.Status -eq 'Pass' }).Count
$failCount = @($results | Where-Object { $_.Status -eq 'Fail' }).Count

foreach ($result in $results) {
  Write-Output ('[{0}] {1} - {2}' -f $result.Status.ToUpperInvariant(), $result.Case, $result.Details)
}

Write-Output ('Summary: {0} pass, {1} fail' -f $passCount, $failCount)

if ($failCount -gt 0) {
  throw "Conversion contract run failed with $failCount failing case(s)."
}

if ($usesTemporaryOutputRoot -and
    $OutputRoot.StartsWith($env:TEMP.TrimEnd('\') + '\',
      [System.StringComparison]::OrdinalIgnoreCase) -and
    ((Split-Path -Leaf $OutputRoot) -like 'VCL2FMXContracts_*') -and
    (Test-Path -LiteralPath $OutputRoot)) {
  Remove-Item -LiteralPath $OutputRoot -Recurse -Force
}
