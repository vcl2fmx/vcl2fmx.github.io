param([string]$TranslationProject,
  [string]$PythonExecutable = (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\python.exe'),
  [ValidateSet('V7TranslationContracts','V7ReportLanguageContracts','V7ReleaseSafetyContracts','V7FormLanguageContracts','V7HelpServerContracts')]
  [string[]]$Tests = @('V7TranslationContracts','V7ReportLanguageContracts','V7ReleaseSafetyContracts','V7FormLanguageContracts','V7HelpServerContracts'))
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $TranslationProject) { $TranslationProject = Join-Path $projectRoot 'dependencies\DelphiAppTranslation' }
$testOutput = Join-Path $projectRoot 'bin\Tests'
$testUnits = Join-Path $projectRoot 'dcu\LanguageTests'
$testWorkspace = Join-Path $projectRoot 'export\translation-work'
$testPacks = Join-Path $testOutput 'Localization\Languages'
$oldLocalAppData = $env:LOCALAPPDATA
New-Item -ItemType Directory -Force -Path $testOutput,$testUnits,$testWorkspace,$testPacks | Out-Null
Copy-Item (Join-Path $projectRoot 'Localization\Languages\*.json') $testPacks -Force
$unitSearch = @($projectRoot,
  (Join-Path $TranslationProject 'source\core'),
  (Join-Path $TranslationProject 'source\runtime'),
  (Join-Path $TranslationProject 'source\components')) -join ';'
try {
  $env:LOCALAPPDATA = Join-Path $testWorkspace 'LocalAppData'
  foreach ($testName in $Tests) {
    $command = '"C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" && dcc32.exe -Q -B -DREPORT_PATHS -E"{0}" -N0"{1}" -U"{2}" "{3}"' -f $testOutput,$testUnits,$unitSearch,(Join-Path $PSScriptRoot "$testName.dpr")
    cmd /c $command
    if ($LASTEXITCODE -ne 0) { throw "$testName build failed" }
    if ($testName -eq 'V7ReleaseSafetyContracts') {
      $junctionRoot = Join-Path $testWorkspace ([guid]::NewGuid().ToString())
      foreach ($case in 'same-root','source-cycle','output-link','output-hardlink') {
        $inputFolder = Join-Path $junctionRoot "$case\input"
        $outputFolder = Join-Path $junctionRoot "$case\output"
        New-Item -ItemType Directory -Path $inputFolder -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $inputFolder 'Example.pas'), 'unit Example; interface implementation end.')
        if ($case -eq 'same-root') {
          New-Item -ItemType Junction -Path $outputFolder -Target $inputFolder | Out-Null
        } else {
          New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
          if ($case -eq 'output-hardlink') {
            New-Item -ItemType HardLink -Path (Join-Path $outputFolder 'Example.pas') -Target (Join-Path $inputFolder 'Example.pas') | Out-Null
          } else {
            $linkPath = if ($case -eq 'source-cycle') { Join-Path $inputFolder 'cycle' } else { Join-Path $outputFolder 'Win32' }
            New-Item -ItemType Junction -Path $linkPath -Target $inputFolder | Out-Null
          }
        }
      }
      & (Join-Path $testOutput "$testName.exe") $testWorkspace $junctionRoot
    } else {
      & (Join-Path $testOutput "$testName.exe") (Join-Path $projectRoot 'Localization\Languages') $testWorkspace
    }
    if ($LASTEXITCODE -ne 0) { throw "$testName failed" }
  }
  & $PythonExecutable -B (Join-Path $PSScriptRoot 'validate_v7_languages.py')
  if ($LASTEXITCODE -ne 0) { throw 'Language pack audit failed' }
}
finally {
  $env:LOCALAPPDATA = $oldLocalAppData
}
