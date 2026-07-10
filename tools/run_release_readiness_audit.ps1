[CmdletBinding()]
param(
  [string]$ProjectRoot,
  [string]$ReportPath,
  [switch]$FailOnBlockers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}

$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$auditScriptPath = [IO.Path]::GetFullPath($PSCommandPath)
$buildOutputDirectoryNames = @('Win32', 'Win64', '__history')

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
  $reportDir = Join-Path $ProjectRoot 'docs\notes\release_audits'
  New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
  $timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
  $ReportPath = Join-Path $reportDir ("RELEASE_READINESS_AUDIT_{0}.txt" -f $timestamp)
}

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

function Test-PathStartsWith {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Prefix
  )

  $normalizedPath = [IO.Path]::GetFullPath($Path).TrimEnd('\\')
  $normalizedPrefix = [IO.Path]::GetFullPath($Prefix).TrimEnd('\\')
  return $normalizedPath.StartsWith($normalizedPrefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-IsUnderNamedDirectory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string[]]$DirectoryNames
  )

  foreach ($directoryName in $DirectoryNames) {
    if (Test-PathStartsWith -Path $Path -Prefix (Join-Path $ProjectRoot $directoryName)) {
      return $true
    }
  }

  return $false
}

function Add-Finding {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Blocker', 'Warning', 'Info')]
    [string]$Severity,
    [Parameter(Mandatory = $true)]
    [string]$Category,
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Details,
    [int]$LineNumber = 0
  )

  $script:Findings.Add([pscustomobject]@{
    Severity = $Severity
    Category = $Category
    RelativePath = Get-RelativePath -BasePath $ProjectRoot -Path $Path
    FullPath = [IO.Path]::GetFullPath($Path)
    LineNumber = $LineNumber
    Details = $Details
  }) | Out-Null
}

function Get-PathMatches {
  param(
    [System.IO.FileInfo[]]$Files = @(),
    [Parameter(Mandatory = $true)]
    [string]$Pattern,
    [Parameter(Mandatory = $true)]
    [ValidateSet('Blocker', 'Warning', 'Info')]
    [string]$Severity,
    [Parameter(Mandatory = $true)]
    [string]$Category,
    [Parameter(Mandatory = $true)]
    [string]$DetailPrefix
  )

  foreach ($file in $Files) {
    $matches = Select-String -Path $file.FullName -Pattern $Pattern -AllMatches
    foreach ($match in $matches) {
      foreach ($capture in $match.Matches) {
        $detail = $DetailPrefix
        if (-not [string]::IsNullOrWhiteSpace($capture.Value)) {
          $detail += ': ' + $capture.Value.Trim()
        }
        Add-Finding -Severity $Severity -Category $Category -Path $file.FullName -Details $detail -LineNumber $match.LineNumber
      }
    }
  }
}

$Findings = New-Object 'System.Collections.Generic.List[object]'

$sourceExtensions = @('.pas', '.dpr', '.dproj', '.groupproj', '.fmx', '.dfm', '.inc')
$supportExtensions = @('.ps1', '.html', '.md', '.txt', '.json', '.xml')
$supportRoots = @(
  (Join-Path $ProjectRoot 'tools'),
  (Join-Path $ProjectRoot 'docs\references\html')
)

$allFiles = @(Get-ChildItem $ProjectRoot -Recurse -File)
$allDirectories = @(Get-ChildItem $ProjectRoot -Recurse -Directory)
$sourceFiles = @(
  $allFiles | Where-Object {
    ($sourceExtensions -contains $_.Extension.ToLowerInvariant()) -and
    -not (Test-IsUnderNamedDirectory -Path $_.DirectoryName -DirectoryNames $buildOutputDirectoryNames)
  }
)
$supportFiles = @(
  foreach ($root in $supportRoots) {
    if (Test-Path $root) {
      Get-ChildItem $root -Recurse -File | Where-Object {
        ($supportExtensions -contains $_.Extension.ToLowerInvariant()) -and
        ([IO.Path]::GetFullPath($_.FullName) -ne $auditScriptPath)
      }
    }
  }
)

$licenseFilePath = Join-Path $ProjectRoot 'LICENSE.txt'
if (-not (Test-Path $licenseFilePath -PathType Leaf)) {
  Add-Finding -Severity 'Blocker' -Category 'Missing license file' -Path $licenseFilePath -Details 'Root LICENSE.txt is missing from the live workspace.'
}

$artifactFileRules = @(
  @{ Severity = 'Warning'; Category = 'IDE artifact'; Pattern = '(?i)\.dproj\.local$'; Detail = 'Delphi local project settings file is present in the live workspace, but the source-distribution script excludes it from shipping.' },
  @{ Severity = 'Warning'; Category = 'IDE artifact'; Pattern = '(?i)\.identcache$'; Detail = 'Delphi ident cache file is present in the live workspace, but the source-distribution script excludes it from shipping.' },
  @{ Severity = 'Blocker'; Category = 'Debug artifact'; Pattern = '(?i)grid_binding_debug\.log$'; Detail = 'Grid debug log should not ship.' },
  @{ Severity = 'Warning'; Category = 'Archive artifact'; Pattern = '(?i)\.(zip|7z|rar)$'; Detail = 'Archive file found inside the live workspace.' },
  @{ Severity = 'Warning'; Category = 'Temporary artifact'; Pattern = '(?i)\.(bak|tmp|temp)$'; Detail = 'Temporary or backup file found inside the live workspace.' },
  @{ Severity = 'Warning'; Category = 'Compiled artifact'; Pattern = '(?i)\.(dcu|exe|dll)$'; Detail = 'Compiled binary found inside the live workspace.' }
)

$artifactDirectoryRules = @(
  @{ Severity = 'Warning'; Category = 'IDE build output'; Pattern = '^(?i:Win32|Win64|__history)$'; Detail = 'IDE build output directory is present in the live workspace, but the source-distribution script excludes it from shipping.' },
  @{ Severity = 'Warning'; Category = 'Workspace clutter'; Pattern = '(?i)(backup|scratch|temp|tmp|debug|trace)'; Detail = 'Suspicious non-source directory name found in the live workspace.' }
)

$absolutePathPattern = '(?i)(?:[A-Z]:\\[A-Za-z0-9_.$() -]+(?:\\[A-Za-z0-9_.$() -]+)+|\\\\[A-Za-z0-9_.$ -]+\\[A-Za-z0-9_.$ -]+(?:\\[A-Za-z0-9_.$ -]+)*)'
$debugMarkerPattern = '(?i)(grid_binding_debug|OutputDebugString|DebugBreak|IsDebuggerPresent|debug log|trace log)'

foreach ($file in $allFiles) {
  foreach ($rule in $artifactFileRules) {
    if (($rule.Category -eq 'Compiled artifact') -and
        (Test-IsUnderNamedDirectory -Path $file.DirectoryName -DirectoryNames $buildOutputDirectoryNames)) {
      continue
    }

    if ($file.FullName -match $rule.Pattern) {
      Add-Finding -Severity $rule.Severity -Category $rule.Category -Path $file.FullName -Details $rule.Detail
      break
    }
  }
}

foreach ($directory in $allDirectories) {
  foreach ($rule in $artifactDirectoryRules) {
    if ($directory.Name -match $rule.Pattern) {
      Add-Finding -Severity $rule.Severity -Category $rule.Category -Path $directory.FullName -Details $rule.Detail
      break
    }
  }
}

Get-PathMatches -Files $sourceFiles -Pattern $absolutePathPattern -Severity 'Blocker' -Category 'Local path reference' -DetailPrefix 'Absolute path reference found in live source/project file'
Get-PathMatches -Files $sourceFiles -Pattern $debugMarkerPattern -Severity 'Blocker' -Category 'Debug marker' -DetailPrefix 'Debug-oriented marker found in live source/project file'
Get-PathMatches -Files $supportFiles -Pattern $absolutePathPattern -Severity 'Warning' -Category 'Support-file local path reference' -DetailPrefix 'Absolute path reference found in tool/reference file'
Get-PathMatches -Files $supportFiles -Pattern $debugMarkerPattern -Severity 'Warning' -Category 'Support-file debug marker' -DetailPrefix 'Debug-oriented marker found in tool/reference file'

$blockerCount = @($Findings | Where-Object { $_.Severity -eq 'Blocker' }).Count
$warningCount = @($Findings | Where-Object { $_.Severity -eq 'Warning' }).Count
$infoCount = @($Findings | Where-Object { $_.Severity -eq 'Info' }).Count

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('VCL2FMXConverter V3 Release Readiness Audit')
[void]$sb.AppendLine('===========================================')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
[void]$sb.AppendLine('Project root: ' + $ProjectRoot)
[void]$sb.AppendLine('Source files scanned: ' + $sourceFiles.Count)
[void]$sb.AppendLine('Support files scanned: ' + $supportFiles.Count)
[void]$sb.AppendLine('')
[void]$sb.AppendLine(('Summary: {0} blocker(s), {1} warning(s), {2} info item(s)' -f $blockerCount, $warningCount, $infoCount))
[void]$sb.AppendLine('')

if ($Findings.Count -eq 0) {
  [void]$sb.AppendLine('No release-readiness findings were detected.')
} else {
  $severityOrder = @{ Blocker = 0; Warning = 1; Info = 2 }
  $orderedFindings = $Findings | Sort-Object @{ Expression = { $severityOrder[$_.Severity] } }, Category, RelativePath, LineNumber, Details
  foreach ($group in $orderedFindings | Group-Object Severity, Category) {
    $first = $group.Group[0]
    [void]$sb.AppendLine(('{0} - {1}' -f $first.Severity.ToUpperInvariant(), $first.Category))
    foreach ($item in $group.Group) {
      $lineSuffix = ''
      if ($item.LineNumber -gt 0) {
        $lineSuffix = ':' + $item.LineNumber
      }
      [void]$sb.AppendLine(('  - {0}{1} :: {2}' -f $item.RelativePath, $lineSuffix, $item.Details))
    }
    [void]$sb.AppendLine('')
  }
}

Set-Content -Path $ReportPath -Value $sb.ToString() -Encoding UTF8
Write-Output $ReportPath
Write-Output ('BLOCKERS=' + $blockerCount)
Write-Output ('WARNINGS=' + $warningCount)
Write-Output ('INFO=' + $infoCount)

if ($FailOnBlockers -and ($blockerCount -gt 0)) {
  exit 1
}


