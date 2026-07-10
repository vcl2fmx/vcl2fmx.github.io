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

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
  $reportDir = Join-Path $ProjectRoot 'docs\notes\regression_guards'
  New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
  $timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
  $ReportPath = Join-Path $reportDir ("REGRESSION_GUARDS_{0}.txt" -f $timestamp)
}

function Add-Result {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Pass', 'Blocker', 'Warning', 'Info')]
    [string]$Status,
    [Parameter(Mandatory = $true)]
    [string]$Area,
    [Parameter(Mandatory = $true)]
    [string]$Check,
    [Parameter(Mandatory = $true)]
    [string]$Details
  )

  $script:Results.Add([pscustomobject]@{
    Status = $Status
    Area = $Area
    Check = $Check
    Details = $Details
  }) | Out-Null
}

function Get-SourceText {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $fullPath = Join-Path $ProjectRoot $RelativePath
  if (-not (Test-Path $fullPath)) {
    Add-Result -Status 'Blocker' -Area 'Workspace' -Check $RelativePath -Details 'Expected converter file is missing.'
    return ''
  }

  return [System.IO.File]::ReadAllText($fullPath)
}

function Add-RuleResult {
  param(
    [Parameter(Mandatory = $true)]
    [bool]$Condition,
    [Parameter(Mandatory = $true)]
    [string]$Area,
    [Parameter(Mandatory = $true)]
    [string]$Check,
    [Parameter(Mandatory = $true)]
    [string]$PassDetails,
    [Parameter(Mandatory = $true)]
    [string]$FailDetails,
    [ValidateSet('Blocker', 'Warning', 'Info')]
    [string]$FailureStatus = 'Blocker'
  )

  if ($Condition) {
    Add-Result -Status 'Pass' -Area $Area -Check $Check -Details $PassDetails
  }
  else {
    Add-Result -Status $FailureStatus -Area $Area -Check $Check -Details $FailDetails
  }
}

function Get-MethodBlock {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text,
    [Parameter(Mandatory = $true)]
    [string]$MethodName
  )

  $pattern = "(?ms)^function\s+TComponentMapper\.$([regex]::Escape($MethodName))\b.*?^end;"
  $match = [regex]::Match($Text, $pattern)
  if ($match.Success) {
    return $match.Value
  }

  return ''
}

$Results = New-Object 'System.Collections.Generic.List[object]'

$mapperText = Get-SourceText -RelativePath 'Converter.Mapper.Component.pas'
$dataAwareText = Get-SourceText -RelativePath 'Converter.Advanced.DataAware.pas'
$integrationText = Get-SourceText -RelativePath 'Converter.Core.Integration.pas'
$autoFixText = Get-SourceText -RelativePath 'Converter.Rewrite.AutoFixes.pas'
$liveBindingsText = Get-SourceText -RelativePath 'Converter.Rewrite.LiveBindings.pas'
$dfmParserText = Get-SourceText -RelativePath 'Converter.Parser.DFM.pas'
$fileManagerText = Get-SourceText -RelativePath 'Converter.Core.FileManager.pas'
$engineText = Get-SourceText -RelativePath 'Converter.Core.Engine.pas'
$engineConstructorMatch = [regex]::Match($engineText,
  '(?ms)constructor\s+TConverterEngine\.Create\b.*?^end;\s*$')
$engineConstructorText = if ($engineConstructorMatch.Success) {
  $engineConstructorMatch.Value
}
else {
  ''
}
$coreTypesText = Get-SourceText -RelativePath 'Converter.Core.Types.pas'
$projectGeneratorText = Get-SourceText -RelativePath 'Converter.Project.Generator.pas'
$mainFormText = Get-SourceText -RelativePath 'MainForm.pas'
$usesClauseText = Get-SourceText -RelativePath 'Converter.Rewrite.UsesClause.pas'
$winApiText = Get-SourceText -RelativePath 'Converter.Advanced.WinAPI.pas'

if (-not [string]::IsNullOrWhiteSpace($mapperText)) {
  $ensureBestMatchBlock = Get-MethodBlock -Text $mapperText -MethodName 'EnsureBestMatch'
  $findBestMatchBlock = Get-MethodBlock -Text $mapperText -MethodName 'FindBestMatch'

  Add-RuleResult -Condition (-not [string]::IsNullOrWhiteSpace($ensureBestMatchBlock)) `
    -Area 'Mapper' -Check 'EnsureBestMatch exists' `
    -PassDetails 'EnsureBestMatch is present for side-effecting mapper lookup.' `
    -FailDetails 'EnsureBestMatch is missing from the mapper.'

  Add-RuleResult -Condition (-not [string]::IsNullOrWhiteSpace($findBestMatchBlock)) `
    -Area 'Mapper' -Check 'FindBestMatch exists' `
    -PassDetails 'FindBestMatch is present for pure/cached mapper lookup.' `
    -FailDetails 'FindBestMatch is missing from the mapper.'

  Add-RuleResult -Condition (
      ($ensureBestMatchBlock -match 'RegisterResolvedMapping\(LookupKey,\s*Result\)') -or
      (
        ($ensureBestMatchBlock -match 'FMappingDatabase\.Add\(Result\)') -and
        ($ensureBestMatchBlock -match 'FMappingIndex\.AddOrSetValue') -and
        ($ensureBestMatchBlock -match 'FDerivedMappingCache\.Remove')
      )
    ) -Area 'Mapper' -Check 'EnsureBestMatch mutates the mapper cache/database' `
    -PassDetails 'EnsureBestMatch still owns the mutation path for derived matches.' `
    -FailDetails 'EnsureBestMatch no longer shows the expected mutation path for derived matches.'

  Add-RuleResult -Condition (
      ($findBestMatchBlock -match 'BuildBestMatch\(VCLClassName, False\)') -and
      ($findBestMatchBlock -match 'FDerivedMappingCache\.AddOrSetValue') -and
      -not ($findBestMatchBlock -match 'FMappingDatabase\.Add\(') -and
      -not ($findBestMatchBlock -match 'FMappingIndex\.AddOrSetValue') -and
      -not ($findBestMatchBlock -match 'FContext\.AddIssue\(')
    ) -Area 'Mapper' -Check 'FindBestMatch remains pure/cached' `
    -PassDetails 'FindBestMatch still uses the derived cache without mutating the mapping database or logging issues.' `
    -FailDetails 'FindBestMatch no longer looks like a pure/cached lookup path.'
}

if (-not [string]::IsNullOrWhiteSpace($dfmParserText)) {
  Add-RuleResult -Condition ($dfmParserText -match 'EnsureBestMatch\(Component\.ComponentClass\)') `
    -Area 'DFM parser' -Check 'DFM parser uses EnsureBestMatch' `
    -PassDetails 'DFM parsing still routes component resolution through EnsureBestMatch.' `
    -FailDetails 'DFM parsing no longer shows the expected EnsureBestMatch call.'

  Add-RuleResult -Condition (-not ($dfmParserText -match 'FindBestMatch\(Component\.ComponentClass\)')) `
    -Area 'DFM parser' -Check 'DFM parser avoids FindBestMatch for component resolution' `
    -PassDetails 'DFM parsing does not call FindBestMatch directly for component resolution.' `
    -FailDetails 'DFM parsing appears to call FindBestMatch directly for component resolution.'

  Add-RuleResult -Condition (($dfmParserText -match 'VCL2FMXTryReadTextFile') -and ($dfmParserText -match 'VCL2FMX_MAX_TEXT_DFM_BYTES')) `
    -Area 'DFM parser' -Check 'DFM parser uses shared encoding and size guard' `
    -PassDetails 'DFM loading uses the shared text reader and large-file guard.' `
    -FailDetails 'DFM loading no longer shows the shared encoding reader and size guard.'
}

if (-not [string]::IsNullOrWhiteSpace($dataAwareText)) {
  Add-RuleResult -Condition ($dataAwareText -match 'function\s+NormalizeComponentClassName') `
    -Area 'Data-aware' -Check 'Normalized component-class helper exists' `
    -PassDetails 'NormalizeComponentClassName is present.' `
    -FailDetails 'NormalizeComponentClassName is missing from the data-aware unit.'

  Add-RuleResult -Condition ($dataAwareText -match 'function\s+ComponentMatchesClass') `
    -Area 'Data-aware' -Check 'ComponentMatchesClass helper exists' `
    -PassDetails 'ComponentMatchesClass is present for normalized/ancestry-aware matching.' `
    -FailDetails 'ComponentMatchesClass is missing from the data-aware unit.'

  Add-RuleResult -Condition ($dataAwareText -match 'AMapper\.GetVCLInventory') `
    -Area 'Data-aware' -Check 'Mapper-backed ancestry lookup exists' `
    -PassDetails 'Data-aware matching still walks mapper inventory ancestry.' `
    -FailDetails 'Data-aware matching no longer shows mapper-backed ancestry lookup.'

  Add-RuleResult -Condition (-not ($dataAwareText -match 'ComponentClass\.Contains\(')) `
    -Area 'Data-aware' -Check 'Substring-based ComponentClass.Contains checks are gone' `
    -PassDetails 'The old substring-based ComponentClass.Contains pattern is absent.' `
    -FailDetails 'Substring-based ComponentClass.Contains matching reappeared in the data-aware unit.'
}

if (-not [string]::IsNullOrWhiteSpace($integrationText)) {
  $autoFixScopeText = $integrationText + $autoFixText

  Add-RuleResult -Condition ($autoFixScopeText -match 'procedure\s+T(?:ConversionOrchestrator|AutoFixRewriter)\.MarkUnsupportedPascalRoutinesForReview') `
    -Area 'Integration' -Check 'Unsupported-routine review helper exists' `
    -PassDetails 'MarkUnsupportedPascalRoutinesForReview is present.' `
    -FailDetails 'MarkUnsupportedPascalRoutinesForReview is missing.'

  Add-RuleResult -Condition (($autoFixScopeText -match 'end\\b\|until\\b') -and ($autoFixScopeText -notmatch 'end\\b\|until\\b\|finally\\b\|except\\b')) `
    -Area 'Integration' -Check 'Unsupported-routine depth tracks plain end tokens' `
    -PassDetails 'Unsupported-routine depth tracking closes on end/until and treats finally/except as try-block separators.' `
    -FailDetails 'Unsupported-routine depth tracking no longer shows the expected plain end token pattern.'

  Add-RuleResult -Condition ($autoFixScopeText -match 'MarkUnsupportedPascalRoutinesForReview\(Lines\);') `
    -Area 'Integration' -Check 'ApplyAutomaticFixes invokes unsupported-routine review pass' `
    -PassDetails 'ApplyAutomaticFixes still invokes MarkUnsupportedPascalRoutinesForReview.' `
    -FailDetails 'ApplyAutomaticFixes no longer invokes MarkUnsupportedPascalRoutinesForReview.'

  Add-RuleResult -Condition ($autoFixScopeText -match 'RewriteCanvasGeometryLine\(L, InEllipseFill, InPolygonFill\);') `
    -Area 'Integration' -Check 'ApplyAutomaticFixes invokes canvas-geometry helper' `
    -PassDetails 'ApplyAutomaticFixes still invokes RewriteCanvasGeometryLine.' `
    -FailDetails 'ApplyAutomaticFixes no longer invokes RewriteCanvasGeometryLine.'

  Add-RuleResult -Condition ($autoFixScopeText -match 'RestoreNonUnsupportedManualReviewSignatures\(Lines\);') `
    -Area 'Integration' -Check 'ApplyAutomaticFixes restores safe signatures after review tagging' `
    -PassDetails 'ApplyAutomaticFixes still invokes RestoreNonUnsupportedManualReviewSignatures.' `
    -FailDetails 'ApplyAutomaticFixes no longer invokes RestoreNonUnsupportedManualReviewSignatures.'

  Add-RuleResult -Condition (($integrationText -match 'FLiveBindings\.WarnIfMultipleFormDeclarations') -and (($integrationText + $liveBindingsText) -match 'Multi-form unit LiveBindings review')) `
    -Area 'Integration' -Check 'Multi-form LiveBindings warning remains in place' `
    -PassDetails 'Integration warns when a Pascal unit contains multiple form/frame/datamodule declarations.' `
    -FailDetails 'The multi-form LiveBindings warning no longer appears to be present.'

  Add-RuleResult -Condition (($integrationText -match 'Pascal unit is missing an implementation section') -and
    ($integrationText -match 'Open the converted unit and restore the implementation section before compiling') -and
    ($integrationText -match 'Implementation section contains an unexpected first statement')) `
    -Area 'Integration' -Check 'Implementation-section safeguard remains active' `
    -PassDetails 'FixImplementationSection reports missing implementation sections and unexpected first implementation statements.' `
    -FailDetails 'FixImplementationSection no longer shows the expected structure safeguards.'
}

if (-not [string]::IsNullOrWhiteSpace($fileManagerText)) {
  Add-RuleResult -Condition (($fileManagerText -match 'FindFirst\(') -and ($fileManagerText -match 'FindNext\(') -and ($fileManagerText -match 'FindClose\(')) `
    -Area 'File scan' -Check 'Streaming directory enumeration remains in place' `
    -PassDetails 'FileManager still uses FindFirst/FindNext/FindClose for scanning.' `
    -FailDetails 'FileManager no longer shows the expected streaming directory enumeration pattern.'

  Add-RuleResult -Condition ($fileManagerText -match 'FFiles\.Sort;') `
    -Area 'File scan' -Check 'Deterministic file ordering remains in place' `
    -PassDetails 'FileManager still sorts the collected file list deterministically.' `
    -FailDetails 'FileManager no longer shows deterministic file sorting.'

  Add-RuleResult -Condition (($fileManagerText -match 'function\s+SaveConvertedFile\(const OriginalFile, Code: string\): Boolean') -and ($fileManagerText -match 'Result := True')) `
    -Area 'File scan' -Check 'SaveConvertedFile reports success or failure' `
    -PassDetails 'SaveConvertedFile returns Boolean status so callers can report failed saves.' `
    -FailDetails 'SaveConvertedFile no longer appears to return explicit save status.'
}

if ((-not [string]::IsNullOrWhiteSpace($fileManagerText)) -and (-not [string]::IsNullOrWhiteSpace($engineText))) {
  Add-RuleResult -Condition ($engineText -match 'TotalFiles := FFileManager\.FileCount;') `
    -Area 'Engine' -Check 'Engine uses FileCount instead of rescanning for totals' `
    -PassDetails 'Engine still uses FileManager.FileCount for total-file reporting.' `
    -FailDetails 'Engine no longer shows the expected FileManager.FileCount usage for total-file reporting.'
}

if (-not [string]::IsNullOrWhiteSpace($engineText)) {
  Add-RuleResult -Condition (($engineText -match 'procedure\s+TConverterEngine\.RebuildServicesForContext') -and ($engineText -match 'RebuildServicesForContext\(AContext\);') -and (-not ($engineText -match '(?ms)function\s+TConverterEngine\.Convert\b.*?^\s*FContext := AContext;\s*$'))) `
    -Area 'Engine' -Check 'Engine rebuilds services when context changes' `
    -PassDetails 'Engine conversion uses RebuildServicesForContext instead of directly swapping FContext.' `
    -FailDetails 'Engine may have reverted to direct FContext reassignment.'

  Add-RuleResult -Condition (($engineConstructorText -match 'RebuildServicesForContext\(AContext\);') -and (-not ($engineConstructorText -match 'FOrchestrator\s*:=\s*TConversionOrchestrator\.Create\(FContext\);'))) `
    -Area 'Engine' -Check 'Engine services are not double-created' `
    -PassDetails 'Engine constructor does not recreate services after RebuildServicesForContext.' `
    -FailDetails 'Engine constructor appears to recreate services after RebuildServicesForContext, which can duplicate mapping-pack report entries.'

  Add-RuleResult -Condition (($engineText -match 'Pascal save skipped') -and ($engineText -match 'DFM save skipped') -and ($engineText -match 'SaveConvertedFile\(AFileName, Code\)')) `
    -Area 'Engine' -Check 'Failed conversion saves are explicitly reported' `
    -PassDetails 'Engine reports skipped Pascal/DFM saves instead of leaving empty else paths.' `
    -FailDetails 'Engine no longer shows explicit skipped-save reporting.'

  Add-RuleResult -Condition (($engineText -match 'CONVERSION LOG') -and ($engineText -match '<h2>Conversion log</h2>')) `
    -Area 'Engine' -Check 'Conversion log is surfaced in reports' `
    -PassDetails 'Text and HTML reports include the captured conversion log.' `
    -FailDetails 'Conversion log no longer appears to be surfaced in reports.'

  Add-RuleResult -Condition ($engineText -match 'Recommended next step:') `
    -Area 'Reporting' -Check 'Text report includes next-step guidance' `
    -PassDetails 'Text report still includes Recommended next step.' `
    -FailDetails 'Text report no longer includes Recommended next step guidance.'

  Add-RuleResult -Condition ($engineText -match 'Distinct files needing attention') `
    -Area 'Reporting' -Check 'Report includes distinct-files needing attention metric' `
    -PassDetails 'Reporting includes Distinct files needing attention.' `
    -FailDetails 'Reporting no longer includes the Distinct files needing attention metric.'

  Add-RuleResult -Condition ($engineText -match 'Files with conversion errors') `
    -Area 'Reporting' -Check 'Report includes files-with-errors metric' `
    -PassDetails 'Reporting still includes Files with conversion errors.' `
    -FailDetails 'Reporting no longer includes the Files with conversion errors metric.'
}

if (-not [string]::IsNullOrWhiteSpace($coreTypesText)) {
  $localUtf8HelperCount = ([regex]::Matches(($mapperText + $dataAwareText + $integrationText + $dfmParserText + $fileManagerText + $engineText + $projectGeneratorText), 'function\s+IsValidUTF8Bytes')).Count

  Add-RuleResult -Condition (($coreTypesText -match 'function\s+VCL2FMXIsValidUTF8Bytes') -and ($coreTypesText -match 'function\s+VCL2FMXTryReadTextFile') -and ($localUtf8HelperCount -eq 0)) `
    -Area 'Encoding' -Check 'Encoding helpers are centralized' `
    -PassDetails 'Shared encoding helpers live in Converter.Core.Types and local duplicate UTF8 helpers are absent.' `
    -FailDetails 'Duplicate local UTF8 helper functions or missing shared encoding helpers were found.'
}

if (-not [string]::IsNullOrWhiteSpace($projectGeneratorText)) {
  Add-RuleResult -Condition (($projectGeneratorText -match 'VCL2FMXTryReadTextFile\(SourceDPR') -and ($projectGeneratorText -match 'VCL2FMXTryReadTextFile\(SourceProj') -and ($projectGeneratorText -match 'VCL2FMXTryReadTextFile\(Source,')) `
    -Area 'Project generator' -Check 'Project files use shared encoding reader' `
    -PassDetails 'DPR, DPROJ, and DEPLOYPROJ reads use the shared encoding reader.' `
    -FailDetails 'Project generation appears to have ad hoc project-file encoding reads.'
}

if (-not [string]::IsNullOrWhiteSpace($mainFormText)) {
  Add-RuleResult -Condition (
      ($mainFormText -match "Result := 'Blocking issues present'") -and
      ($mainFormText -match "Result := 'Manual review required'") -and
      ($mainFormText -match 'Next: fix blocking items first and review the report\.')
    ) -Area 'UI summary' -Check 'Main form status wording matches report outcomes' `
    -PassDetails 'Main form summary text still aligns with the current report status wording.' `
    -FailDetails 'Main form summary text no longer aligns with the current report status wording.'
}

if (-not [string]::IsNullOrWhiteSpace($usesClauseText)) {
  Add-RuleResult -Condition (-not ($usesClauseText -match "Pos\('cla',\s*AnalysisCode\)")) `
    -Area 'Uses clause' -Check 'cla color detection avoids substring matching' `
    -PassDetails 'Uses-clause detection no longer treats every class declaration as a cla color constant.' `
    -FailDetails 'Uses-clause detection still contains Pos(''cla'', AnalysisCode).'

  Add-RuleResult -Condition (($usesClauseText -match "'\\b\(WM_\|CM_\|CN_\|EM_\|LB_\|CB_\|LVM_\|TVM_\|TCM_\|TWM\[A-Za-z0-9_\]\*\|TCM\[A-Za-z0-9_\]\*\)'") -and
      ($usesClauseText -match 'HasLikelyMessageAPICall\(AnalysisCode\)')) `
    -Area 'Uses clause' -Check 'message constants are matched case-sensitively' `
    -PassDetails 'Message-family detection remains case-sensitive and broad API names are context-gated.' `
    -FailDetails 'Message-constant detection may still be case-insensitive or missing.'

  Add-RuleResult -Condition (($usesClauseText -match 'HasLikelyMessageAPICall') -and
      ($usesClauseText -match 'GetMessage') -and
      -not ($usesClauseText -match "\\b\(SendMessage\|PostMessage\|DispatchMessage\|PeekMessage\|GetMessage\)\\s\*\\\(")) `
    -Area 'Uses clause' -Check 'GetMessage is not a generic Winapi.Messages trigger' `
    -PassDetails 'GetMessage is present only inside context-gated message API analysis.' `
    -FailDetails 'GetMessage remains in the broad Winapi.Messages detection regex.'

  Add-RuleResult -Condition (($usesClauseText -match 'Winapi\.Messages was added because') -and -not ($usesClauseText -match 'Winapi\.Messages was retained because')) `
    -Area 'Uses clause' -Check 'Winapi.Messages issue text says added' `
    -PassDetails 'The Winapi.Messages warning describes added units accurately.' `
    -FailDetails 'The Winapi.Messages warning still uses retained wording.'
}

if (-not [string]::IsNullOrWhiteSpace($winApiText)) {
  Add-RuleResult -Condition ($winApiText -match 'function\s+IsLikelyMessageAPICall') `
    -Area 'WinAPI' -Check 'message API conversion is context-gated' `
    -PassDetails 'Broad message API names are checked for likely WinAPI context before conversion.' `
    -FailDetails 'Message API conversion is still driven only by broad function-name regexes.'

  Add-RuleResult -Condition ($winApiText -match "Category = 'Message'\) and not IsLikelyMessageAPICall\(AnalysisLine\)") `
    -Area 'WinAPI' -Check 'message API guard is applied before conversion' `
    -PassDetails 'Message API matches are skipped unless the line looks like WinAPI message code.' `
    -FailDetails 'The message API context guard is missing from the conversion loop.'

  Add-RuleResult -Condition (-not ($winApiText -match "(?s)IsCommentContinuationBoundary\(OriginalLine\).*?AwaitingConditionalBegin := False;\s*Continue;" )) `
    -Area 'WinAPI' -Check 'comment continuation boundary does not fall through' `
    -PassDetails 'Boundary lines reset continuation state and fall through to normal analysis.' `
    -FailDetails 'Boundary lines still exit before normal WinAPI analysis.'

  Add-RuleResult -Condition (($winApiText -match "Trim\(AnalysisLine\) = ''\) and not CommentContinuation") -and
      ($winApiText -match 'StripStringLiteralsForAnalysis')) `
    -Area 'WinAPI' -Check 'comment-only continuation lines are preserved' `
    -PassDetails 'Comment-only lines inside continuation blocks are still prefixed.' `
    -FailDetails 'Comment-only continuation lines may still be skipped.'

  Add-RuleResult -Condition ($winApiText -match 'FPlatformIfdefs\.Add\(Line\)') `
    -Area 'WinAPI' -Check 'PlatformIfdefs stores converted text' `
    -PassDetails 'PlatformIfdefs records the converted line.' `
    -FailDetails 'PlatformIfdefs may still record stale pre-conversion text.'
}

$blockerCount = @($Results | Where-Object { $_.Status -eq 'Blocker' }).Count
$warningCount = @($Results | Where-Object { $_.Status -eq 'Warning' }).Count
$passCount = @($Results | Where-Object { $_.Status -eq 'Pass' }).Count
$infoCount = @($Results | Where-Object { $_.Status -eq 'Info' }).Count

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('VCL2FMXConverter V5 Regression Guards')
[void]$sb.AppendLine('=====================================')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
[void]$sb.AppendLine('Project root: ' + $ProjectRoot)
[void]$sb.AppendLine('')
[void]$sb.AppendLine(('Summary: {0} blocker(s), {1} warning(s), {2} pass item(s), {3} info item(s)' -f $blockerCount, $warningCount, $passCount, $infoCount))
[void]$sb.AppendLine('')

foreach ($group in @('Mapper', 'DFM parser', 'Data-aware', 'Integration', 'File scan', 'Engine', 'Encoding', 'Project generator', 'Uses clause', 'WinAPI', 'Reporting', 'UI summary', 'Workspace')) {
  $groupItems = @($Results | Where-Object { $_.Area -eq $group })
  if ($groupItems.Count -eq 0) {
    continue
  }

  [void]$sb.AppendLine($group)
  [void]$sb.AppendLine(('-' * $group.Length))
  foreach ($item in $groupItems) {
    [void]$sb.AppendLine(('[{0}] {1}' -f $item.Status.ToUpperInvariant(), $item.Check))
    [void]$sb.AppendLine(('  {0}' -f $item.Details))
  }
  [void]$sb.AppendLine('')
}

[System.IO.File]::WriteAllText($ReportPath, $sb.ToString(), [System.Text.UTF8Encoding]::new($true))
Write-Output ('Regression guard report saved to: ' + $ReportPath)
Write-Output ('Summary: {0} blocker(s), {1} warning(s), {2} pass item(s), {3} info item(s)' -f $blockerCount, $warningCount, $passCount, $infoCount)

if ($FailOnBlockers -and ($blockerCount -gt 0)) {
  throw ('Regression guards found {0} blocker(s). Review: {1}' -f $blockerCount, $ReportPath)
}
