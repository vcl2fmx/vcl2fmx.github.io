[CmdletBinding()]
param(
  [string]$ProjectRoot,
  [string]$OutputDirectory,
  [string]$VersionTag = 'v5_0'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}

$ProjectRoot = (Resolve-Path $ProjectRoot).Path

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
  $OutputDirectory = Join-Path $ProjectRoot 'Source Distributions'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$OutputDirectory = (Resolve-Path $OutputDirectory).Path

$licensePath = Join-Path $ProjectRoot 'LICENSE.txt'
if (-not (Test-Path $licensePath -PathType Leaf)) {
  throw 'LICENSE.txt is missing from the project root. Create it before building a source distribution.'
}

$timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$distributionName = 'VCL2FMXConverter_{0}_Source_Distribution_{1}' -f $VersionTag, $timestamp
$zipPath = Join-Path $OutputDirectory ($distributionName + '.zip')
$stageRoot = Join-Path ([IO.Path]::GetTempPath()) ('VCL2FMXConverterV5_Source_Distribution_' + $timestamp)
$stageProjectRoot = $stageRoot

$excludedDirectoryNames = @(
  'Win32',
  'Win64',
  'dcu',
  '__history',
  '__recovery',
  '.agents',
  '.codex',
  '.git',
  'docs',
  'tests',
  'tools',
  'samples',
  'src',
  'Logos and Icons',
  'Source Distributions',
  'Distribution Zip Files'
)
$excludedFilePatterns = @(
  '*.dproj.local',
  '*.groupproj',
  '*.identcache',
  '*.docx',
  '*.dcu',
  '*.exe',
  '*.dll',
  '*.zip',
  '*.7z',
  '*.rar',
  '*.bak',
  '*.tmp',
  '*.temp'
)

function Get-RelativePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$BasePath,
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $normalizedBase = [IO.Path]::GetFullPath($BasePath).TrimEnd('\')
  $normalizedPath = [IO.Path]::GetFullPath($Path)

  if ($normalizedPath.Equals($normalizedBase, [System.StringComparison]::OrdinalIgnoreCase)) {
    return '.'
  }

  $prefix = $normalizedBase + '\'
  if ($normalizedPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $normalizedPath.Substring($prefix.Length)
  }

  return $normalizedPath
}

function Test-IsExcludedPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FullPath,
    [switch]$IsDirectory
  )

  $relativePath = Get-RelativePath -BasePath $ProjectRoot -Path $FullPath
  if ($relativePath -eq '.') {
    return $false
  }

  $segments = $relativePath -split '[\\/]'
  foreach ($segment in $segments) {
    if ($excludedDirectoryNames -contains $segment) {
      return $true
    }
  }

  if ($IsDirectory) {
    return $false
  }

  $fileName = [IO.Path]::GetFileName($FullPath)
  foreach ($pattern in $excludedFilePatterns) {
    if ($fileName -like $pattern) {
      return $true
    }
  }

  return $false
}

try {
  if (Test-Path $stageRoot) {
    Remove-Item $stageRoot -Recurse -Force
  }

  New-Item -ItemType Directory -Path $stageProjectRoot -Force | Out-Null

  foreach ($directory in Get-ChildItem $ProjectRoot -Recurse -Directory) {
    if (Test-IsExcludedPath -FullPath $directory.FullName -IsDirectory) {
      continue
    }

    $relativeDirectory = Get-RelativePath -BasePath $ProjectRoot -Path $directory.FullName
    $targetDirectory = Join-Path $stageProjectRoot $relativeDirectory
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
  }

  foreach ($file in Get-ChildItem $ProjectRoot -Recurse -File) {
    if (Test-IsExcludedPath -FullPath $file.FullName) {
      continue
    }

    $relativeFile = Get-RelativePath -BasePath $ProjectRoot -Path $file.FullName
    $targetFile = Join-Path $stageProjectRoot $relativeFile
    $targetDirectory = Split-Path -Parent $targetFile
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    Copy-Item $file.FullName $targetFile -Force
  }

  $stagedLicensePath = Join-Path $stageProjectRoot 'LICENSE.txt'
  if (-not (Test-Path $stagedLicensePath -PathType Leaf)) {
    throw 'LICENSE.txt was not copied into the staged source distribution.'
  }

  if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
  }

  Compress-Archive -Path (Join-Path $stageProjectRoot '*') -DestinationPath $zipPath -CompressionLevel Optimal
  Write-Output $zipPath
}
finally {
  if (Test-Path $stageRoot) {
    Remove-Item $stageRoot -Recurse -Force
  }
}
