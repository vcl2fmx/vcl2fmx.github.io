[CmdletBinding()]
param([string]$ProjectRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

$rsvars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat'
$dcc32 = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe'
$dfmConvert = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\convert.exe'
$runnerDir = Join-Path $ProjectRoot 'tools'
$runner = Join-Path $runnerDir 'RunConversionEngine.exe'
$source = Join-Path $PSScriptRoot 'source'
$output = Join-Path $PSScriptRoot 'output'
$invalidSource = Join-Path $PSScriptRoot 'invalid_source'
$invalidOutput = Join-Path $PSScriptRoot 'invalid_output'
$binarySource = Join-Path $PSScriptRoot 'binary_source'
$binaryOutput = Join-Path $PSScriptRoot 'binary_output'
$compileDcu = Join-Path $PSScriptRoot 'compile_dcu'
$compileBin = Join-Path $PSScriptRoot 'compile_bin'

foreach ($path in @($output, $invalidOutput, $binarySource, $binaryOutput, $compileDcu, $compileBin)) {
  if (Test-Path -LiteralPath $path) {
    $resolved = (Resolve-Path -LiteralPath $path).Path
    if (-not $resolved.StartsWith($PSScriptRoot, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Unsafe regression cleanup path: $resolved"
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }
}

$buildRunner = 'call "{0}" && cd /d "{1}" && "{2}" -B -Q -U".." -I".." -N0"dcu" RunConversionEngine.dpr' -f $rsvars, $runnerDir, $dcc32
& cmd.exe /c $buildRunner | Out-Null
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $runner)) {
  throw 'Could not rebuild the conversion regression runner.'
}

New-Item -ItemType Directory -Path $output | Out-Null
& $runner $source $output
if ($LASTEXITCODE -ne 0) {
  throw 'Valid French-beta regression fixture did not convert successfully.'
}

$regressionPasPath = Join-Path $output 'RegressionForm.pas'
$regressionFmxPath = Join-Path $output 'RegressionForm.fmx'
$imageFmxPath = Join-Path $output 'ImageOnly.fmx'
$reportPath = Join-Path $output 'VCL_to_FMX_Conversion_Report.txt'
$pas = [IO.File]::ReadAllText($regressionPasPath)
$fmx = [IO.File]::ReadAllText($regressionFmxPath)
$imageFmx = [IO.File]::ReadAllText($imageFmxPath)
$report = [IO.File]::ReadAllText($reportPath)

if ([string]::IsNullOrWhiteSpace($fmx) -or [string]::IsNullOrWhiteSpace($imageFmx)) {
  throw 'A valid DFM produced empty FMX output.'
}
if (-not $imageFmx.TrimStart().StartsWith('object ImageOnlyForm:', [StringComparison]::OrdinalIgnoreCase)) {
  throw 'Mixed-case DFM object keyword was not normalized correctly.'
}
if (-not $pas.Contains('// Comment must remain unchanged: Vcl.Controls, Vcl.ImgList, Vcl.ToolWin.')) {
  throw 'A VCL unit name was removed from a comment.'
}
if (-not $pas.Contains('// SendMessage(Handle, WM_USER, 0, 0);')) {
  throw 'A commented SendMessage call was rewritten.'
}
if (-not $pas.Contains('/// Panels[0].Width :=') -or $pas.Contains('/// Panels[0].Width := .0')) {
  throw 'A documentation comment was changed by a numeric rewrite.'
}
if ([regex]::Matches($pas, '\bRegularExpressions\b').Count -ne 1 -or
    -not $pas.Contains('{$IFDEF REGULAR_EXP}') -or -not $pas.Contains('{$ENDIF}')) {
  throw 'Conditional uses-clause content was lost or made unconditional.'
}
if ($pas -match '(?im)^uses\s+.*\bUses\b') {
  throw 'The uses keyword was emitted as a unit name.'
}
foreach ($color in @('claBlack', 'claGreen', 'claRed', 'claWhite')) {
  if (-not $pas.Contains($color)) { throw "Color conversion missing: $color" }
}
if (-not $report.Contains('Theme-dependent VCL color clActiveCaption used')) {
  throw 'Theme-dependent color review was not reported.'
}

$implIndex = $pas.IndexOf('implementation', [StringComparison]::OrdinalIgnoreCase)
$usesIndex = $pas.IndexOf('uses System.StrUtils', $implIndex, [StringComparison]::OrdinalIgnoreCase)
$resourceIndex = $pas.IndexOf('{$R *.fmx}', $usesIndex, [StringComparison]::OrdinalIgnoreCase)
$memoImplIndex = $pas.IndexOf('procedure TMemo.Clear;', $resourceIndex, [StringComparison]::OrdinalIgnoreCase)
$generatedIndex = $pas.IndexOf('procedure TRegressionForm.GeneratedSetToggleState_', [StringComparison]::OrdinalIgnoreCase)
$initializationIndex = $pas.IndexOf('initialization', [StringComparison]::OrdinalIgnoreCase)
if (-not ($implIndex -ge 0 -and $usesIndex -gt $implIndex -and $resourceIndex -gt $usesIndex -and $memoImplIndex -gt $resourceIndex)) {
  throw 'Compatibility helper implementation was inserted before implementation uses/resources.'
}
if (-not ($generatedIndex -ge 0 -and $initializationIndex -gt $generatedIndex)) {
  throw 'Generated method implementation was inserted into initialization.'
}

New-Item -ItemType Directory -Path $compileDcu, $compileBin | Out-Null
$compileCommand = 'call "{0}" && cd /d "{1}" && "{2}" -B -Q -U"output" -I"output" -N0"compile_dcu" -E"compile_bin" RegressionCompile.dpr' -f $rsvars, $PSScriptRoot, $dcc32
& cmd.exe /c $compileCommand | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw 'Generated French-beta regression Pascal did not compile.'
}

New-Item -ItemType Directory -Path $invalidOutput | Out-Null
& $runner $invalidSource $invalidOutput
if ($LASTEXITCODE -eq 0) {
  throw 'Malformed DFM input was incorrectly reported as successful.'
}
if (Test-Path -LiteralPath (Join-Path $invalidOutput 'Broken.fmx')) {
  throw 'Malformed DFM input created an FMX output file.'
}

New-Item -ItemType Directory -Path $binarySource, $binaryOutput | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'RegressionForm.dfm') -Destination $binarySource
Copy-Item -LiteralPath (Join-Path $source 'RegressionForm.pas') -Destination $binarySource
& $dfmConvert -i -b (Join-Path $binarySource 'RegressionForm.dfm') | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw 'Delphi could not create the binary DFM regression fixture.'
}

$binaryBytes = [IO.File]::ReadAllBytes((Join-Path $binarySource 'RegressionForm.dfm'))
if ($binaryBytes.Length -lt 1 -or $binaryBytes[0] -ne 0xFF) {
  throw 'The binary DFM regression fixture does not have Delphi binary stream format.'
}

& $runner $binarySource $binaryOutput
if ($LASTEXITCODE -ne 0) {
  throw 'A valid Delphi binary DFM did not convert successfully.'
}
$binaryFmxPath = Join-Path $binaryOutput 'RegressionForm.fmx'
if (-not (Test-Path -LiteralPath $binaryFmxPath)) {
  throw 'A valid Delphi binary DFM did not create FMX output.'
}
$binaryFmx = [IO.File]::ReadAllText($binaryFmxPath)
if ([string]::IsNullOrWhiteSpace($binaryFmx) -or
    -not $binaryFmx.TrimStart().StartsWith('object RegressionForm:', [StringComparison]::OrdinalIgnoreCase)) {
  throw 'A valid Delphi binary DFM created empty or invalid FMX output.'
}

Write-Output 'French beta regression guard passed.'
