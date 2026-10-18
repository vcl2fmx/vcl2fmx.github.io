[CmdletBinding()]
param([string]$ProjectRoot, [string]$OutputDirectory, [string]$VersionTag = 'v7_0_Atlas',
  [string]$PythonExecutable = (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\python.exe'))
$ErrorActionPreference = 'Stop'
if (-not $ProjectRoot) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $ProjectRoot 'source distributions' }
& $PythonExecutable (Join-Path $ProjectRoot 'tools\build_v7_release_packages.py') --source-only --output $OutputDirectory
if ($LASTEXITCODE -ne 0) { throw 'V7 source packaging failed.' }
