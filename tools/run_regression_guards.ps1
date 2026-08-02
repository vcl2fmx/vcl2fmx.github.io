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
  $reportDir = Join-Path $env:TEMP 'VCL2FMXConverter\regression_guards'
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
$pascalParserText = Get-SourceText -RelativePath 'Converter.Parser.Pascal.pas'
$fileManagerText = Get-SourceText -RelativePath 'Converter.Core.FileManager.pas'
$engineText = Get-SourceText -RelativePath 'Converter.Core.Engine.pas'
$reportModelText = Get-SourceText -RelativePath 'Converter.Reporting.Model.pas'
$textReportRendererText = Get-SourceText -RelativePath 'Converter.Reporting.Text.pas'
$htmlReportRendererText = Get-SourceText -RelativePath 'Converter.Reporting.Html.pas'
$jsonReportRendererText = Get-SourceText -RelativePath 'Converter.Reporting.Json.pas'
$acceptanceText = Get-SourceText -RelativePath 'tools\run_acceptance_tests.ps1'
$mappingSmokeGuardText = Get-SourceText -RelativePath 'tests\mapping_pack_smoke\run_mapping_pack_smoke_guard.ps1'
$frenchBetaGuardText = Get-SourceText -RelativePath 'tests\french_beta_regression\run_guard.ps1'
$generateReportMatch = [regex]::Match($engineText,
  '(?ms)^procedure\s+TConverterEngine\.GenerateReport;.*?(?=^procedure\s+TConverterEngine\.Cancel;)')
$generateReportLineCount = if ($generateReportMatch.Success) {
  ($generateReportMatch.Value -split "\r?\n").Count
}
else {
  0
}
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
$mainFormFmxText = Get-SourceText -RelativePath 'MainForm.fmx'
$projectFileText = Get-SourceText -RelativePath 'VCL2FMXConverter.dproj'
$readmeText = Get-SourceText -RelativePath 'README.md'
$contractRunnerText = Get-SourceText -RelativePath 'tools\run_conversion_contracts.ps1'
$reportGoldenExpectationsText = @(
  Get-SourceText -RelativePath 'contracts\project_integration\05_real_world_report_shape\RealWorldReportShapeProject.expected.json'
  Get-SourceText -RelativePath 'contracts\reporting\02_blocking_application_call.expected.json'
  Get-SourceText -RelativePath 'contracts\third_party\03_unknown_vendor_component.expected.json'
) -join "`n"
$usesClauseText = Get-SourceText -RelativePath 'Converter.Rewrite.UsesClause.pas'
$winApiText = Get-SourceText -RelativePath 'Converter.Advanced.WinAPI.pas'
$activeConverterSourceText = @(
  Get-ChildItem -LiteralPath $ProjectRoot -File -Filter '*.pas' |
    ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }
) -join "`n"
$designerBuildMatch = [regex]::Match($mainFormFmxText,
  "Text = 'Navigator Release\s+v6\.0\s+Build\s+(?<build>\d{3})\s+(?<timestamp>\d{4}-\d{2}-\d{2}\s+\d{1,2}:\d{2}\s+(?:AM|PM))'")
$designerBuildText = if ($designerBuildMatch.Success) {
  $designerBuildMatch.Groups['build'].Value
}
else {
  ''
}
$designerBuildNumber = if ($designerBuildText -match '^\d{3}$') {
  [int]$designerBuildText
}
else {
  -1
}
$designerBadgeWidthMatch = [regex]::Match($mainFormFmxText,
  '(?ms)object\s+HeroVersionBadge:\s*TRectangle.*?Size\.Width\s*=\s*(?<width>[0-9.]+)')
$designerBadgeWidth = if ($designerBadgeWidthMatch.Success) {
  [double]$designerBadgeWidthMatch.Groups['width'].Value
}
else {
  0
}
$responsiveBadgeWidths = @(
  [regex]::Matches($mainFormText,
    'HeroVersionBadge\.Size\.Width\s*:=\s*(?<width>[0-9.]+)') |
    ForEach-Object { [double]$_.Groups['width'].Value }
)

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

  Add-RuleResult -Condition (
      ($mapperText -match 'FProperties\s*:=\s*TDictionary<string,\s*string>\.Create\(TIStringComparer\.Ordinal\)') -and
      ($mapperText -match 'FEvents\s*:=\s*TDictionary<string,\s*string>\.Create\(TIStringComparer\.Ordinal\)')
    ) -Area 'Comparer semantics' -Check 'RTTI member inventories are case-insensitive' `
    -PassDetails 'RTTI property and event keys use ordinal, case-insensitive Delphi identifier semantics.' `
    -FailDetails 'RTTI property or event inventory lookup is case-sensitive.'
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

Add-RuleResult -Condition (
    -not ($activeConverterSourceText -match
      'T(?:Object)?Dictionary<string,\s*[^>]+>\.Create(?:\(\[doOwnsValues\]\)|;)')
  ) -Area 'Comparer semantics' -Check 'String-key dictionaries declare comparison semantics' `
  -PassDetails 'Active string-key dictionaries no longer use the default comparer constructor.' `
  -FailDetails 'At least one active string-key dictionary still relies on the default comparer.'

if (-not [string]::IsNullOrWhiteSpace($pascalParserText)) {
  Add-RuleResult -Condition (
      ($pascalParserText -match
        'Result\s*:=\s*VCL2FMXStripCommentsForAnalysis\(Line,\s*False\)') -and
      (-not ($pascalParserText -match
        '(?s)function\s+TPascalParser\.StripComments.*?while\s+CharPos'))
    ) -Area 'Lexical ownership' -Check 'Pascal parser uses shared comment scanner' `
    -PassDetails 'The parser delegates comment stripping while explicitly removing compiler directives.' `
    -FailDetails 'The Pascal parser has restored an independent comment scanner.'
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

  Add-RuleResult -Condition (
      ($integrationText -match 'GridBindingSources\s*:=\s*TDictionary<string,\s*string>\.Create\(TIStringComparer\.Ordinal\)') -and
      ($integrationText -match 'DirectBindingTargets\s*:=\s*TDictionary<string,\s*string>\.Create\(TIStringComparer\.Ordinal\)')
    ) -Area 'Comparer semantics' -Check 'LiveBindings component lookups are case-insensitive' `
    -PassDetails 'Grid and direct-binding component names use ordinal, case-insensitive Delphi identifier semantics.' `
    -FailDetails 'A LiveBindings component-name dictionary is case-sensitive.'

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

  Add-RuleResult -Condition (($textReportRendererText -match 'CONVERSION LOG') -and
      ($htmlReportRendererText -match '<h2>Conversion log</h2>')) `
    -Area 'Engine' -Check 'Conversion log is surfaced in reports' `
    -PassDetails 'Text and HTML reports include the captured conversion log.' `
    -FailDetails 'Conversion log no longer appears to be surfaced in reports.'

  Add-RuleResult -Condition ($textReportRendererText -match 'Recommended next step:') `
    -Area 'Reporting' -Check 'Text report includes next-step guidance' `
    -PassDetails 'Text report still includes Recommended next step.' `
    -FailDetails 'Text report no longer includes Recommended next step guidance.'

  Add-RuleResult -Condition (($textReportRendererText -match
      'Distinct files needing attention') -and
      ($htmlReportRendererText -match 'Distinct files needing attention')) `
    -Area 'Reporting' -Check 'Report includes distinct-files needing attention metric' `
    -PassDetails 'Reporting includes Distinct files needing attention.' `
    -FailDetails 'Reporting no longer includes the Distinct files needing attention metric.'

  Add-RuleResult -Condition (($textReportRendererText -match
      'Files with conversion errors') -and
      ($htmlReportRendererText -match 'Files with conversion errors')) `
    -Area 'Reporting' -Check 'Report includes files-with-errors metric' `
    -PassDetails 'Reporting still includes Files with conversion errors.' `
    -FailDetails 'Reporting no longer includes the Files with conversion errors metric.'

  Add-RuleResult -Condition (
      ($engineText -match 'procedure\s+TConverterEngine\.AddHtmlReportDocumentHead\(const AHtml: TStrings\)') -and
      ($engineText -match 'AddHtmlReportDocumentHead\(Html\);') -and
      ($generateReportLineCount -gt 0) -and
      ($generateReportLineCount -le 600)
    ) -Area 'Reporting' -Check 'Static HTML document head is split from GenerateReport' `
    -PassDetails ('GenerateReport is ' + $generateReportLineCount + ' lines and delegates its static HTML document head.') `
    -FailDetails 'The HTML document head extraction is missing or GenerateReport has grown beyond 600 lines.'
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

  Add-RuleResult -Condition (
      ($mainFormText -match 'chkDryRunPreview:\s*TCheckBox;') -and
      (-not ($mainFormText -match 'TCheckBox\.Create\s*\(')) -and
      ($mainFormFmxText -match 'object\s+chkDryRunPreview:\s*TCheckBox') -and
      ($mainFormFmxText -match 'OnChange\s*=\s*RuleOptionChanged')
    ) -Area 'Designer UI' -Check 'Dry-run checkbox is designer-owned' `
    -PassDetails 'The dry-run checkbox is declared in MainForm.fmx and no checkbox is constructed at runtime.' `
    -FailDetails 'The dry-run checkbox is missing from MainForm.fmx or runtime checkbox construction has returned.'

  Add-RuleResult -Condition (
      ($designerBuildNumber -ge 1) -and
      ($mainFormText -match ('Version v6\.0 Navigator Build ' + [regex]::Escape($designerBuildText))) -and
      ($mainFormFmxText -match ("Caption = 'VCL to FMX Converter v6\.0 Navigator - Build " + [regex]::Escape($designerBuildText) + "'")) -and
      ($projectFileText -match ('FileVersion=6\.0\.0\.' + $designerBuildNumber + '(?:;|<)')) -and
      ($projectFileText -match ('<VerInfo_Build>' + $designerBuildNumber + '</VerInfo_Build>')) -and
      ($readmeText -match ('VCL2FMXConverter v6\.0 Navigator.+Build ' + [regex]::Escape($designerBuildText)))
    ) -Area 'Build identity' -Check 'Navigator build identity is synchronized' `
    -PassDetails ('Source header, designer text, timestamp, executable version metadata, and README identify Navigator Build ' + $designerBuildText + '.') `
    -FailDetails 'Navigator build identity is inconsistent across source, designer, project metadata, or README.'

  Add-RuleResult -Condition (
      ($designerBadgeWidth -ge 450) -and
      ($responsiveBadgeWidths.Count -eq 2) -and
      (@($responsiveBadgeWidths | Where-Object { $_ -lt 450 }).Count -eq 0)
    ) -Area 'Build identity' -Check 'Version badge contains full build and timestamp text' `
    -PassDetails 'Designer and both responsive states keep the version badge at least 450 pixels wide.' `
    -FailDetails 'The version badge can shrink below 450 pixels and clip the build or timestamp.'
}

Add-RuleResult -Condition (
    -not ($activeConverterSourceText -match 'Version\s+v5\.0\s+Vanguard') -and
    -not ($activeConverterSourceText -match 'Generated by VCL2FMX Converter v5\.0 Vanguard') -and
    ($activeConverterSourceText -match 'Generated by VCL2FMX Converter v6\.0 Navigator')
  ) -Area 'Build identity' -Check 'Active v6 source uses Navigator identity' `
  -PassDetails 'Active converter units and generated-project banners identify v6.0 Navigator.' `
  -FailDetails 'Active converter source still exposes the v5.0 Vanguard identity.'

if (-not [string]::IsNullOrWhiteSpace($contractRunnerText)) {
  Add-RuleResult -Condition (
      ($contractRunnerText -match 'Stale contract runner rejected') -and
      ($contractRunnerText -match 'LastWriteTimeUtc -gt \$converterExeInfo\.LastWriteTimeUtc') -and
      ($contractRunnerText -match 'Get-FileHash.+SHA256') -and
      ($contractRunnerText -match 'Contract runner provenance:')
    ) -Area 'Contract provenance' -Check 'Stale runner is rejected and identified' `
    -PassDetails 'The contract runner rejects newer source and prints executable hash/timestamp provenance.' `
    -FailDetails 'The contract runner can execute without stale-source rejection or auditable executable provenance.'

  Add-RuleResult -Condition (
      ($contractRunnerText -match 'function Normalize-ReportArtifact') -and
      ($contractRunnerText -match 'expected_normalized_text_report_sha256') -and
      ($contractRunnerText -match 'expected_normalized_html_report_sha256') -and
      ($contractRunnerText -match 'expected_normalized_json_report_sha256') -and
      (([regex]::Matches($reportGoldenExpectationsText,
        'expected_normalized_text_report_sha256')).Count -eq 3) -and
      (([regex]::Matches($reportGoldenExpectationsText,
        'expected_normalized_html_report_sha256')).Count -eq 3) -and
      (([regex]::Matches($reportGoldenExpectationsText,
        'expected_normalized_json_report_sha256')).Count -eq 3)
    ) -Area 'Reporting' -Check 'Representative reports have exact normalized goldens' `
    -PassDetails 'Three representative cases protect exact text, HTML, and JSON report output.' `
    -FailDetails 'Normalized text/HTML/JSON golden report coverage is incomplete.'

  Add-RuleResult -Condition (
      ($contractRunnerText -match 'expected_text_report_patterns') -and
      ($contractRunnerText -match 'expected_html_report_patterns') -and
      ($contractRunnerText -match 'expected_text_report_ordered_patterns') -and
      ($contractRunnerText -match 'expected_html_report_ordered_patterns') -and
      ($contractRunnerText -match 'expected_text_html_parity') -and
      ($reportGoldenExpectationsText -match 'expected_text_html_parity') -and
      ($reportGoldenExpectationsText -match '&lt; 1 second') -and
      ($reportGoldenExpectationsText -match 'Recommended solution')
    ) -Area 'Reporting' -Check 'Report semantics and text/HTML parity are explicit' `
    -PassDetails 'Representative report contracts independently check semantics, ordering, escaping, recommendations, and text/HTML parity.' `
    -FailDetails 'Explicit report semantic or text/HTML parity coverage is incomplete.'
}

if ((-not [string]::IsNullOrWhiteSpace($reportModelText)) -and
    (-not [string]::IsNullOrWhiteSpace($engineText))) {
  Add-RuleResult -Condition (
      ($reportModelText -match 'TConversionReportModel\s*=\s*record') -and
      ($reportModelText -match 'TConversionReportIssue\s*=\s*record') -and
      ($reportModelText -match 'StableIdentity:\s*string') -and
      ($reportModelText -match 'SourceStartLine:\s*Integer') -and
      ($reportModelText -match 'SourceEndLine:\s*Integer') -and
      ($reportModelText -match 'OriginalEvidence:\s*string') -and
      ($reportModelText -match 'RecommendedAction:\s*string') -and
      ($engineText -match 'ReportModel:\s*TConversionReportModel') -and
      ($engineText -match 'ReportModel\.Issues\[IssueIndex\]') -and
      ($engineText -match 'ReportModel\.VisibleIssueCount') -and
      ($engineText -match 'ReportModel\.NextStepText')
    ) -Area 'Reporting' -Check 'Text and HTML render from an internal report snapshot' `
    -PassDetails 'Report totals, outcomes, and issue provenance are captured in the shared internal report model.' `
    -FailDetails 'The internal report snapshot or its stable issue provenance is incomplete.'
}

if ((-not [string]::IsNullOrWhiteSpace($textReportRendererText)) -and
    $generateReportMatch.Success) {
  Add-RuleResult -Condition (
      ($textReportRendererText -match 'TConversionTextReportRenderer\s*=\s*class') -and
      ($textReportRendererText -match 'const AModel:\s*TConversionReportModel') -and
      ($textReportRendererText -match 'CONVERSION SUMMARY') -and
      ($generateReportMatch.Value -match
        'TConversionTextReportRenderer\.Render\(ReportModel,\s*Report\)') -and
      (-not ($generateReportMatch.Value -match 'CONVERSION SUMMARY'))
    ) -Area 'Reporting' -Check 'Text rendering is isolated behind the report model' `
    -PassDetails ('The dedicated text renderer owns text output and GenerateReport is ' + $generateReportLineCount + ' lines.') `
    -FailDetails 'Text report markup remains duplicated in GenerateReport or bypasses the report model.'
}

if ((-not [string]::IsNullOrWhiteSpace($htmlReportRendererText)) -and
    $generateReportMatch.Success) {
  Add-RuleResult -Condition (
      ($htmlReportRendererText -match 'TConversionHtmlReportRenderer\s*=\s*class') -and
      ($htmlReportRendererText -match 'const AModel:\s*TConversionReportModel') -and
      ($htmlReportRendererText -match '<body>') -and
      ($htmlReportRendererText -match '<h2>Issue summary</h2>') -and
      ($generateReportMatch.Value -match
        'TConversionHtmlReportRenderer\.RenderBody\(ReportModel,\s*Html\)') -and
      (-not ($generateReportMatch.Value -match '<body>'))
    ) -Area 'Reporting' -Check 'HTML rendering is isolated behind the report model' `
    -PassDetails ('The dedicated HTML renderer owns dynamic HTML output and GenerateReport is ' + $generateReportLineCount + ' lines.') `
    -FailDetails 'Dynamic HTML report markup remains duplicated in GenerateReport or bypasses the report model.'
}

if (-not [string]::IsNullOrWhiteSpace($jsonReportRendererText)) {
  Add-RuleResult -Condition (
      ($jsonReportRendererText -match 'TConversionJsonReportRenderer\s*=\s*class') -and
      ($jsonReportRendererText -match 'vcl2fmx\.report\.v1') -and
      ($jsonReportRendererText -match "'stableIdentity'") -and
      ($jsonReportRendererText -match "'sourceStartLine'") -and
      ($jsonReportRendererText -match "'sourceEndLine'") -and
      ($jsonReportRendererText -match "'originalEvidence'") -and
      ($jsonReportRendererText -match "'recommendedAction'") -and
      ($jsonReportRendererText -match "'issueCollection',\s*'raw'") -and
      ($jsonReportRendererText -match "'includeInDetailedIssues'") -and
      ($jsonReportRendererText -match "'dryRunPreview'") -and
      ($jsonReportRendererText -match "'actionableInformation'") -and
      ($jsonReportRendererText -match "'manualGroups'") -and
      ($jsonReportRendererText -match "'mappingPacks'") -and
      ($jsonReportRendererText -match "'mappingUsages'") -and
      ($jsonReportRendererText -match "'conversionLog'") -and
      ($engineText -match
        "UpperCase\(Trim\(IssueRiskCategory\(Issue\)\)\)\s*\+\s*'\|'") -and
      ($engineText -match
        'TConversionJsonReportRenderer\.Save\(ReportModel\)') -and
      $contractRunnerText.Contains(
        '($_.Name -like ''*Report*.json'')')
    ) -Area 'Reporting' -Check 'JSON report exposes stable issue provenance' `
    -PassDetails 'The deterministic v1 JSON schema is rendered from the shared report model and includes stable issue provenance.' `
    -FailDetails 'The JSON report schema, model ownership, or stable issue provenance is incomplete.'
}

if ((-not [string]::IsNullOrWhiteSpace($acceptanceText)) -and
    (-not [string]::IsNullOrWhiteSpace($mappingSmokeGuardText)) -and
    (-not [string]::IsNullOrWhiteSpace($frenchBetaGuardText))) {
  Add-RuleResult -Condition (
      ($acceptanceText -match "Required guard script is missing:") -and
      ($acceptanceText -match "Mapping-pack smoke output guard is available") -and
      ($acceptanceText -match "French beta regression corpus guard is available")
    ) -Area 'Workspace' -Check 'Required field-test suites cannot be silently skipped' `
    -PassDetails 'The restored mapping-pack and French regression guards are required by the acceptance gate, including explicit missing-suite failures.' `
    -FailDetails 'A required field-test suite is missing or the acceptance gate can silently skip it.'
}

if (-not [string]::IsNullOrWhiteSpace($usesClauseText)) {
  Add-RuleResult -Condition (
      (-not ($usesClauseText -match 'function\s+StripStringLiteralsForAnalysis')) -and
      (([regex]::Matches($usesClauseText,
        'VCL2FMXStripStringLiteralsForAnalysis\s*\(')).Count -ge 2)
    ) -Area 'Lexical ownership' -Check 'Uses-clause string masking uses shared scanner' `
    -PassDetails 'Both uses-clause passes call the shared string-literal analysis routine.' `
    -FailDetails 'A local duplicate string-literal masking routine has returned to the uses-clause rewriter.'

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
[void]$sb.AppendLine('VCL2FMXConverter v6.0 Navigator Regression Guards')
[void]$sb.AppendLine('=====================================')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
[void]$sb.AppendLine('Project root: ' + $ProjectRoot)
[void]$sb.AppendLine('')
[void]$sb.AppendLine(('Summary: {0} blocker(s), {1} warning(s), {2} pass item(s), {3} info item(s)' -f $blockerCount, $warningCount, $passCount, $infoCount))
[void]$sb.AppendLine('')

foreach ($group in @('Mapper', 'DFM parser', 'Data-aware', 'Integration', 'File scan', 'Engine', 'Encoding', 'Project generator', 'Uses clause', 'WinAPI', 'Reporting', 'UI summary', 'Designer UI', 'Build identity', 'Workspace')) {
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
