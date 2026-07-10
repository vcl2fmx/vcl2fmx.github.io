[CmdletBinding()]
param(
  [string]$ProjectRoot,
  [string]$ReportPath,
  [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}

$ProjectRoot = (Resolve-Path $ProjectRoot).Path

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
  $timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
  $ReportPath = Join-Path $env:TEMP ("VCL2FMX_ACCEPTANCE_{0}.txt" -f $timestamp)
}

$Results = New-Object 'System.Collections.Generic.List[object]'

function Add-Result {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Pass', 'Fail', 'Info')]
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

function Add-Check {
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
    [string]$FailDetails
  )

  if ($Condition) {
    Add-Result -Status Pass -Area $Area -Check $Check -Details $PassDetails
  }
  else {
    Add-Result -Status Fail -Area $Area -Check $Check -Details $FailDetails
  }
}

function Get-Text {
  param([Parameter(Mandatory = $true)][string]$RelativePath)
  $path = Join-Path $ProjectRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path)) {
    Add-Result -Status Fail -Area Workspace -Check $RelativePath -Details 'Required file is missing.'
    return ''
  }
  return [System.IO.File]::ReadAllText($path)
}

function Invoke-Process {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string]$Arguments,
    [Parameter(Mandatory = $true)][string]$WorkingDirectory
  )

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $FilePath
  $psi.Arguments = $Arguments
  $psi.WorkingDirectory = $WorkingDirectory
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true

  $process = [System.Diagnostics.Process]::Start($psi)
  $stdout = $process.StandardOutput.ReadToEnd()
  $stderr = $process.StandardError.ReadToEnd()
  $process.WaitForExit()

  return [pscustomobject]@{
    ExitCode = $process.ExitCode
    StdOut = $stdout
    StdErr = $stderr
  }
}

function Test-JsonMappingPacks {
  $packFolder = Join-Path $ProjectRoot 'mapping_packs'
  $packs = @(Get-ChildItem -LiteralPath $packFolder -Filter '*.json' -ErrorAction SilentlyContinue)
  $bad = New-Object 'System.Collections.Generic.List[string]'

  foreach ($pack in $packs) {
    try {
      $json = Get-Content -LiteralPath $pack.FullName -Raw | ConvertFrom-Json
      foreach ($field in @('pack_name', 'pack_id', 'vendor', 'version', 'description', 'mode', 'rules')) {
        if (-not ($json.PSObject.Properties.Name -contains $field)) {
          $bad.Add("$($pack.Name): missing $field") | Out-Null
        }
      }

      if ($json.rules -eq $null -or @($json.rules).Count -eq 0) {
        $bad.Add("$($pack.Name): no rules") | Out-Null
      }

      foreach ($rule in @($json.rules)) {
        if (-not ($rule.PSObject.Properties.Name -contains 'vcl_class')) {
          $bad.Add("$($pack.Name): rule missing vcl_class") | Out-Null
        }
        if (-not ($rule.PSObject.Properties.Name -contains 'action')) {
          $bad.Add("$($pack.Name): rule missing action") | Out-Null
        }
      }
    }
    catch {
      $bad.Add("$($pack.Name): $($_.Exception.Message)") | Out-Null
    }
  }

  Add-Check -Condition (($packs.Count -gt 0) -and ($bad.Count -eq 0)) `
    -Area 'Mapping packs' `
    -Check 'Mapping packs are parseable and structurally valid' `
    -PassDetails ("Validated {0} mapping pack JSON file(s)." -f $packs.Count) `
    -FailDetails $(if ($bad.Count -gt 0) { $bad -join '; ' } else { 'No mapping packs were found.' })
}

$engineText = Get-Text 'Converter.Core.Engine.pas'
$typesText = Get-Text 'Converter.Core.Types.pas'
$fileManagerText = Get-Text 'Converter.Core.FileManager.pas'
$integrationText = Get-Text 'Converter.Core.Integration.pas'
$dfmText = Get-Text 'Converter.Parser.DFM.pas'
$projectGeneratorText = Get-Text 'Converter.Project.Generator.pas'
$mapperText = Get-Text 'Converter.Mapper.Component.pas'
$thirdPartyText = Get-Text 'Converter.Advanced.ThirdParty.pas'
$pascalParserText = Get-Text 'Converter.Parser.Pascal.pas'
$autoFixText = Get-Text 'Converter.Rewrite.AutoFixes.pas'
$liveBindingsText = Get-Text 'Converter.Rewrite.LiveBindings.pas'
$mainFormText = Get-Text 'MainForm.pas'
$compatibilityText = Get-Text 'Converter.Rewrite.Compatibility.pas'
$usesClauseText = Get-Text 'Converter.Rewrite.UsesClause.pas'
$runtimeText = Get-Text 'Converter.Rewrite.RuntimeNormalization.pas'
$winApiText = Get-Text 'Converter.Advanced.WinAPI.pas'
$convertPascalStep16Count = [regex]::Matches($integrationText, 'Step 16:').Count
$engineConstructorMatch = [regex]::Match($engineText,
  '(?ms)constructor\s+TConverterEngine\.Create\b.*?^end;\s*$')
$engineConstructorText = if ($engineConstructorMatch.Success) {
  $engineConstructorMatch.Value
}
else {
  ''
}

Add-Check -Condition ($typesText -match 'function\s+VCL2FMXTryReadTextFile') `
  -Area Encoding `
  -Check 'Shared text reader exists' `
  -PassDetails 'Shared text reader is present in Converter.Core.Types.' `
  -FailDetails 'Shared text reader is missing.'

Add-Check -Condition (-not (($engineText + $fileManagerText + $dfmText + $projectGeneratorText) -match 'function\s+IsValidUTF8Bytes')) `
  -Area Encoding `
  -Check 'Duplicate local UTF8 helpers are absent' `
  -PassDetails 'No local IsValidUTF8Bytes helper functions were found in critical files.' `
  -FailDetails 'A duplicate local IsValidUTF8Bytes helper function was found.'

Add-Check -Condition (-not (($engineText + $dfmText + $projectGeneratorText) -match 'TFile\.ReadAllText\(')) `
  -Area Encoding `
  -Check 'Critical reads use shared reader' `
  -PassDetails 'Engine, DFM parser, and project generator avoid direct ReadAllText calls.' `
  -FailDetails 'A critical direct TFile.ReadAllText call was found.'

Add-Check -Condition (($fileManagerText -match 'function\s+SaveConvertedFile\(const OriginalFile, Code: string\): Boolean') -and ($engineText -match 'Pascal save skipped') -and ($engineText -match 'DFM save skipped')) `
  -Area Save `
  -Check 'Failed saves are explicit' `
  -PassDetails 'SaveConvertedFile returns Boolean and engine reports skipped saves.' `
  -FailDetails 'Save failure reporting is incomplete.'

Add-Check -Condition (($engineText -match 'procedure\s+TConverterEngine\.RebuildServicesForContext') -and ($engineText -match 'RebuildServicesForContext\(AContext\);') -and (-not ($engineText -match '(?ms)function\s+TConverterEngine\.Convert\b.*?^\s*FContext := AContext;\s*$'))) `
  -Area Context `
  -Check 'Engine context swap is guarded' `
  -PassDetails 'Engine rebuilds services if a new context is supplied.' `
  -FailDetails 'Engine context reassignment is not safely guarded.'

Add-Check -Condition (($engineConstructorText -match 'RebuildServicesForContext\(AContext\);') -and (-not ($engineConstructorText -match 'FOrchestrator\s*:=\s*TConversionOrchestrator\.Create\(FContext\);'))) `
  -Area Context `
  -Check 'Engine services are not double-created' `
  -PassDetails 'Engine constructor relies on RebuildServicesForContext for service construction.' `
  -FailDetails 'Engine constructor creates conversion services after RebuildServicesForContext, which can double-load mapping packs.'

Add-Check -Condition (-not ($engineText -match "UILog\([^`r`n]*'\s*\?")) `
  -Area Reporting `
  -Check 'Screen log output uses plain ASCII status text' `
  -PassDetails 'UILog status strings do not contain degraded question-mark glyphs.' `
  -FailDetails 'A UILog status string still contains a question-mark status marker.'

Add-Check -Condition (($integrationText -match 'Pascal unit is missing an implementation section') -and
  ($integrationText -match 'Open the converted unit and restore the implementation section before compiling') -and
  ($integrationText -match 'Implementation section contains an unexpected first statement')) `
  -Area Structure `
  -Check 'Implementation-section safeguard exists' `
  -PassDetails 'Missing implementation sections and unexpected first implementation statements are reported.' `
  -FailDetails 'Implementation-section checks are missing.'

Add-Check -Condition (($integrationText -match 'NormalizeFMXResourceDirectiveSpacing') -and ($integrationText -match '\{\\\$R\\s\+\\\*\\\.fmx') -and ($integrationText -match '\$1'' \+ sLineBreak \+ sLineBreak \+ ''\$2')) `
  -Area Structure `
  -Check 'FMX resource directive spacing is normalized' `
  -PassDetails 'Generated helper code is prevented from sharing a line with {$R *.fmx}.' `
  -FailDetails 'FMX resource directive line-normalization is missing.'

Add-Check -Condition (($integrationText -match 'FLiveBindings\.WarnIfMultipleFormDeclarations') -and (($integrationText + $liveBindingsText) -match 'Multi-form unit LiveBindings review')) `
  -Area Structure `
  -Check 'Multi-form LiveBindings warning exists' `
  -PassDetails 'Multi-form units are reported for LiveBindings review.' `
  -FailDetails 'Multi-form LiveBindings warning is missing.'

Add-Check -Condition (($typesText -match 'function\s+VCL2FMXStripCommentsForAnalysis') -and
  ($typesText -match 'cstLine') -and
  ($typesText -match 'cstBrace') -and
  ($typesText -match 'cstParenStar') -and
  ($pascalParserText -match 'FLines\.Text := VCL2FMXStripCommentsForAnalysis\(Code\)')) `
  -Area Comments `
  -Check 'Pascal parser uses shared full-comment analysis stripper' `
  -PassDetails 'Parser analysis uses the shared stripper for //, {...}, and (*...*) comments.' `
  -FailDetails 'Parser does not use the shared full-comment analysis stripper.'

Add-Check -Condition (($usesClauseText -match 'VCL2FMXStripCommentsForAnalysis') -and
  ($usesClauseText -match 'AnalysisLines\.Text := AnalysisCode') -and
  ($usesClauseText -match 'Pos\(''TImage'', AnalysisCode\)') -and
  ($usesClauseText -match 'ProtectedLines\.Add\(OriginalLine\)') -and
  ($usesClauseText -match "SameText\(UnitName, 'uses'\)")) `
  -Area Comments `
  -Check 'Uses-clause rewrite ignores comment text' `
  -PassDetails 'Uses-clause cleanup uses a comment-free analysis copy and preserves source comments outside rewritten uses clauses.' `
  -FailDetails 'Uses-clause cleanup can still treat comment text as live Pascal.'

Add-Check -Condition (($autoFixText -match 'VCL2FMXStripCommentsForAnalysis') -and
  ($autoFixText -match 'AnalysisLines\.Text := VCL2FMXStripCommentsForAnalysis\(ALines\.Text\)') -and
  ($autoFixText -match 'DiscoverDeclaredTypeMaps\(AnalysisLines') -and
  ($autoFixText -match 'if Trim\(AnalysisLine\) = '''' then') -and
  ($autoFixText -match 'IsUnsupportedMessageHandlerSignature\(AnalysisLine, NextAnalysisLine\)')) `
  -Area Comments `
  -Check 'AutoFix ignores block-commented Pascal code' `
  -PassDetails 'AutoFix uses comment-free analysis lines for unsupported handler detection and skips block-comment-only lines.' `
  -FailDetails 'AutoFix can still treat block-commented Pascal as live code.'

Add-Check -Condition (($dfmText -match 'VCL2FMXStripLineCommentOutsideString\(Result\)') -and
  ($typesText -match 'function\s+VCL2FMXStripLineCommentOutsideString')) `
  -Area Comments `
  -Check 'DFM property cleanup preserves quoted // text' `
  -PassDetails 'DFM property cleanup strips // comments only outside quoted strings.' `
  -FailDetails 'DFM property cleanup may still truncate quoted values containing //.'

Add-Check -Condition (($compatibilityText -match 'AnalysisCode := VCL2FMXStripCommentsForAnalysis\(Code\)') -and
  ($compatibilityText -match 'NeedRadioGroup := ContainsText\(AnalysisCode') -and
  ($compatibilityText -match 'NeedFontDialog := ContainsText\(AnalysisCode') -and
  ($compatibilityText -match 'NeedColorDialog := ContainsText\(AnalysisCode')) `
  -Area Comments `
  -Check 'Compatibility injection decisions ignore comments' `
  -PassDetails 'Compatibility helper decisions are based on comment-stripped analysis code.' `
  -FailDetails 'Compatibility helper decisions may still be triggered by comment text.'

Add-Check -Condition (($compatibilityText.Contains("NeedMemoCompat := ContainsText(AnalysisCode, 'TMemo')")) -and
  ($compatibilityText.Contains("NeedTrackBarCompat := ContainsText(AnalysisCode, 'TTrackBar')")) -and
  ($compatibilityText.Contains("NeedProgressBarCompat := ContainsText(AnalysisCode, 'TProgressBar')")) -and
  ($compatibilityText.Contains("NeedSpinBoxCompat := (ContainsText(AnalysisCode, 'TSpinEdit')")) -and
  ($compatibilityText.Contains("not ContainsText(AnalysisCode, 'TTrackBar = class(FMX.StdCtrls.TTrackBar)')")) -and
  ($compatibilityText.Contains("TRegEx.IsMatch(AnalysisCode, '\buses\b[^;]*\bAudioManager\b'")) -and
  ($compatibilityText.Contains("Code := TRegEx.Replace(Code,")) -and
  ($compatibilityText.Contains("FMX.StdCtrls.TTrackBar")) -and
  (-not ($compatibilityText -match 'RegisterFmxClasses\(\['))) `
  -Area Context `
  -Check 'Compatibility helpers avoid unsafe duplicate wrappers' `
  -PassDetails 'Trackbar/progress/spinbox helpers use guarded detection, AudioManager suppression, qualified type rewrites, and no duplicate class registration.' `
  -FailDetails 'Compatibility helper guards for trackbar/progress/spinbox wrappers are missing or duplicate RegisterFmxClasses injection may be present.'

Add-Check -Condition (($compatibilityText -match "SameText\(Trim\(AnalysisLines\[J\]\), 'uses'\)") -and
  ($compatibilityText -match 'StartsText\(''uses '', TrimLeft\(AnalysisLines\[J\]\)\)') -and
  ($runtimeText -match "SameText\(Trim\(Lines\[I\]\), 'uses'\)") -and
  ($runtimeText -match 'StartsText\(''uses '', TrimLeft\(Lines\[I\]\)\)')) `
  -Area Structure `
  -Check 'Generated helpers respect implementation uses clauses' `
  -PassDetails 'Compatibility and runtime helper insertion both skip implementation uses clauses before inserting generated code.' `
  -FailDetails 'Generated helpers may still be inserted before implementation uses clauses.'

Add-Check -Condition (($compatibilityText -match 'AnalysisCode := VCL2FMXStripCommentsForAnalysis\(OriginalCode\)') -and
  ($compatibilityText -match "ContainsText\(AnalysisCode, 'TPngImage'\)") -and
  ($compatibilityText -match 'TRegEx\.IsMatch\(AnalysisCode,')) `
  -Area Comments `
  -Check 'Compatibility lifecycle warnings ignore comments' `
  -PassDetails 'Lifecycle warning decisions use comment-stripped source text.' `
  -FailDetails 'Lifecycle warning decisions can still be triggered by comment text.'

Add-Check -Condition (([regex]::Matches(($pascalParserText + $autoFixText + $usesClauseText), 'function\s+T\w+\.(?:StripCommentsForAnalysis|StripBlockCommentsForAnalysis)').Count -eq 0) -and
  ($typesText -match 'function\s+VCL2FMXStripCommentsForAnalysis')) `
  -Area Comments `
  -Check 'Comment stripping implementation is centralized' `
  -PassDetails 'Parser, AutoFix, and UsesClause no longer carry duplicate comment-stripper implementations.' `
  -FailDetails 'Duplicate comment-stripper implementation remains outside Converter.Core.Types.'

Add-Check -Condition (($autoFixText -match 'FContext:\s*TConversionContext') -and
  ($autoFixText -match 'constructor\s+Create\(ADfmParser:\s*TDFMParser;\s*AContext:\s*TConversionContext\)') -and
  ($autoFixText -match 'procedure\s+TAutoFixRewriter\.MarkLineForManualReview') -and
  ($autoFixText -match 'FContext\.AddManualReview') -and
  ($integrationText -match 'TAutoFixRewriter\.Create\(FDfmParser,\s*FContext\)')) `
  -Area Reporting `
  -Check 'AutoFix manual-review markers report directly' `
  -PassDetails 'AutoFix receives conversion context and reports manual-review markers directly.' `
  -FailDetails 'AutoFix manual-review markers still rely only on post-conversion report auditing.'

Add-Check -Condition (-not (($autoFixText -match "ContainsText\(L, 'ScaleBy\('") -or
  ($autoFixText -match "ContainsText\(L, 'DoubleBuffered'\)") -or
  ($autoFixText -match "TRegEx\.IsMatch\(L,\s*'\\b\\w\*MediaPlayer\\w\*\\.Notify") -or
  ($autoFixText -match 'shape class handled in generated \.fmx') -or
  ($autoFixText -match 'FMX: Use Width/Height for scaling'))) `
  -Area Comments `
  -Check 'AutoFix review detections use analysis lines' `
  -PassDetails 'ScaleBy, shape, and related review detections no longer run on raw comment-bearing lines.' `
  -FailDetails 'AutoFix still contains raw-line review detection or silent review comments.'

Add-Check -Condition (($mainFormText -match 'Engine\.ScreenMemo\s*:=\s*MemoLog') -and
  ($engineText -match 'TThread\.Synchronize') -and
  ($engineText -match 'ScreenMemo\.Lines\.Add\(ScreenMsg\)')) `
  -Area Threading `
  -Check 'Worker thread log output is routed safely to the UI memo' `
  -PassDetails 'ConversionThreadProc connects MemoLog and engine UI updates are synchronized.' `
  -FailDetails 'Live conversion logging is not connected or is not synchronized.'

Add-Check -Condition (-not ($mainFormText -match 'FPending(Log|Error)Message')) `
  -Area Threading `
  -Check 'Synchronized messages use local captures' `
  -PassDetails 'Log and error synchronization no longer use shared pending message fields.' `
  -FailDetails 'Shared pending log/error message fields are still present.'

Add-Check -Condition (($mainFormText -match 'TConversionCompletionSnapshot\s*=\s*record') -and
  ($mainFormText -match 'var\s+Completion:\s*TConversionCompletionSnapshot') -and
  ($mainFormText -match 'FPendingCompletion\s*:=\s*Completion')) `
  -Area Threading `
  -Check 'Completion results are queued as a snapshot' `
  -PassDetails 'Background conversion results are packaged before the UI completion handler reads them.' `
  -FailDetails 'Conversion completion snapshot handling is missing or incomplete.'

Add-Check -Condition (($mainFormText -match 'FormCloseQuery') -and
  ($mainFormText -match 'FConversionThread\.Finished') -and
  ($mainFormText -match 'FreeAndNil\(FConversionThread\)')) `
  -Area Threading `
  -Check 'Close query permits finished conversion threads' `
  -PassDetails 'FormCloseQuery frees a finished conversion thread before deciding whether close is allowed.' `
  -FailDetails 'FormCloseQuery does not handle the finished-thread timing window.'

Add-Check -Condition (($usesClauseText -match 'constructor\s+TUsesClauseRewriter\.Create\(AContext:\s*TConversionContext\)') -and
  ($compatibilityText -match 'constructor\s+TCompatibilityInjector\.Create\(AContext:\s*TConversionContext\)') -and
  ($integrationText -match 'TUsesClauseRewriter\.Create\(FContext\)') -and
  ($integrationText -match 'TCompatibilityInjector\.Create\(FContext\)')) `
  -Area Context `
  -Check 'Extracted rewrite helpers receive conversion context' `
  -PassDetails 'Compatibility and uses-clause rewriters are constructed with TConversionContext.' `
  -FailDetails 'Compatibility or uses-clause rewriter context wiring is incomplete.'

Add-Check -Condition (($usesClauseText -match 'FContext\.AddIssue\(csInfo') -and
  ($usesClauseText -match 'Interface uses clause normalized for FMX compatibility') -and
  ($usesClauseText -match 'Implementation uses clause normalized for FMX compatibility') -and
  ($compatibilityText -match 'FContext\.AddIssue\(csInfo') -and
  ($compatibilityText -match 'Injected TMemo compatibility helper') -and
  ($compatibilityText -match 'Runtime compatibility rewrites applied for FMX conversion support')) `
  -Area Context `
  -Check 'Extracted rewrite helpers report actual changes' `
  -PassDetails 'Compatibility and uses-clause rewriters add context info when they modify source.' `
  -FailDetails 'Compatibility or uses-clause rewriter context reporting is missing.'

Add-Check -Condition (-not ($compatibilityText -match 'Compatibility classes injected for FMX conversion support')) `
  -Area Reporting `
  -Check 'Compatibility reporting avoids generic duplicate message' `
  -PassDetails 'Compatibility injector uses specific per-helper report messages.' `
  -FailDetails 'Compatibility injector still emits the generic duplicate report message.'

Add-Check -Condition (($compatibilityText -match 'Injected TRadioGroup compatibility helper') -and
  ($compatibilityText -match 'Injected generated canvas compatibility helpers') -and
  ($compatibilityText -match 'TPngImage references were rewritten') -and
  ($compatibilityText -match 'Paint handler signatures were adapted')) `
  -Area Reporting `
  -Check 'Compatibility rewrites report specific helper details' `
  -PassDetails 'Compatibility injector reports helper insertions and warning-level review cases.' `
  -FailDetails 'Compatibility injector reporting is still too generic.'

Add-Check -Condition (($usesClauseText -match 'Added FMX\.Forms to the interface uses clause') -and
  ($usesClauseText -match 'Added FMX\.Controls to the interface uses clause') -and
  ($usesClauseText -match 'Winapi\.Messages was retained')) `
  -Area Reporting `
  -Check 'Uses-clause rewrites report specific additions and warnings' `
  -PassDetails 'Uses-clause rewriter reports specific FMX additions and Winapi.Messages review warnings.' `
  -FailDetails 'Uses-clause reporting is still too generic.'

Add-Check -Condition (($autoFixText -match 'procedure\s+TAutoFixRewriter\.ApplyBasicTypeAndPropertyRewrites') -and
  ($autoFixText -match 'ApplyBasicTypeAndPropertyRewrites\(L,\s*AnalysisLine,\s*ControlTypes\)')) `
  -Area Structure `
  -Check 'AutoFix Apply has decomposition seam' `
  -PassDetails 'Basic type/property rewrites were extracted from Apply.' `
  -FailDetails 'AutoFix Apply still lacks the expected decomposition seam.'

Add-Check -Condition (($liveBindingsText -match 'AppendComboDataChangeMethodImplementations') -and
  ($liveBindingsText -match 'AppendNavigatorMethodImplementations') -and
  ($liveBindingsText -match 'AppendAfterOpenMethodImplementations')) `
  -Area Structure `
  -Check 'LiveBindings generated-method blocks are decomposed' `
  -PassDetails 'Combo data-change, navigator, and after-open generation blocks are extracted.' `
  -FailDetails 'LiveBindings generated-method blocks remain inline.'

Add-Check -Condition ((-not ($runtimeText -match '^\s*HelperCode\s*=')) -and
  ($runtimeText -match 'BaseRuntimeColorHelperCode') -and
  ($runtimeText -match 'InsertGeneratedHelperBlock\(BaseRuntimeColorHelperCode\)')) `
  -Area Structure `
  -Check 'Runtime normalizer has no dead duplicate helper block' `
  -PassDetails 'NormalizeColors keeps only the named helper constants it actually injects.' `
  -FailDetails 'NormalizeColors still contains a dead duplicate HelperCode constant.'

Add-Check -Condition (($pascalParserText -match 'else if \(CharPos < Length\(S\)\) and \(S\[CharPos \+ 1\] = ''''''''\) then') -and
  ($pascalParserText -match 'while i <= Length\(Line\) do') -and
  ($pascalParserText -match 'else if \(i < Length\(Line\)\) and \(Line\[i \+ 1\] = ''''''''\) then')) `
  -Area Comments `
  -Check 'Pascal parser handles doubled quotes in string/comment stripping' `
  -PassDetails 'StripComments and StripStringLiterals skip doubled Pascal quotes correctly.' `
  -FailDetails 'Pascal parser string/comment stripping still mishandles doubled quotes.'

Add-Check -Condition (($pascalParserText -match 'SanIdx:\s*Integer') -and
  ($pascalParserText -match 'while SanIdx <= Length\(Line\) do') -and
  ($pascalParserText -match 'Line\[SanIdx \+ 1\] = ''''''''')) `
  -Area Comments `
  -Check 'Message-call parser handles doubled quotes' `
  -PassDetails 'HasMessageCalls uses indexed string scanning and skips doubled Pascal quotes.' `
  -FailDetails 'HasMessageCalls can still treat doubled quotes inside strings as live code.'

Add-Check -Condition (($autoFixText -match 'procedure TAutoFixRewriter\.SplitTrailingBlockComment') -and
  ($autoFixText -match 'SplitTrailingBlockComment\(L, TrailingComment\)') -and
  ($autoFixText -match 'ApplyBasicTypeAndPropertyRewrites\(L, AnalysisLine, ControlTypes\)') -and
  ($autoFixText -match 'L := L \+ TrailingComment') -and
  ($autoFixText -match "ALine\[P \+ 1\] = '\$'")) `
  -Area Comments `
  -Check 'AutoFix full loop preserves trailing block comments and compiler directives' `
  -PassDetails 'The full Apply loop separates and restores trailing block comments while preserving {$...} compiler directives.' `
  -FailDetails 'The full Apply loop may still rewrite trailing block comments or strip compiler directives.'

Add-Check -Condition (($winApiText -match 'TGraphicsConverter\s*=\s*class') -and
  ($winApiText -match 'function\s+TGraphicsConverter\.ConvertGraphics') -and
  ($integrationText -match 'FGraphics\.ConvertGraphics\(Code\)')) `
  -Area Graphics `
  -Check 'Graphics converter is implemented and called' `
  -PassDetails 'TGraphicsConverter is present in Converter.Advanced.WinAPI and used by the orchestrator.' `
  -FailDetails 'TGraphicsConverter declaration, implementation, or call site is missing.'

Add-Check -Condition ($integrationText -match '(?s)Step 20: Final uses clause cleanup\..*?try\s+FUsesRewriter\.Fix\(Code\);.*?except.*?Final uses clause cleanup failed') `
  -Area Structure `
  -Check 'Final uses cleanup is exception guarded' `
  -PassDetails 'Step 20 reports uses-clause cleanup failures without aborting the file conversion.' `
  -FailDetails 'Step 20 final uses cleanup is not wrapped in a reporting try/except.'

Add-Check -Condition (($integrationText -match '(?s)FLiveBindings\.Free;.*?FRuntimeNormalizer\.Free;') -and
  ($integrationText -match 'method reference to FRuntimeNormalizer\.NormalizeColors')) `
  -Area Lifetime `
  -Check 'LiveBindings method-reference lifetime is explicit' `
  -PassDetails 'FLiveBindings is freed before FRuntimeNormalizer and the ordering is documented.' `
  -FailDetails 'FLiveBindings/FRuntimeNormalizer destructor ordering is not protected.'

Add-Check -Condition (($convertPascalStep16Count -eq 1) -and ($integrationText -match 'Step 20: Final uses clause cleanup') -and (-not ($integrationText -match '    // Step 17:'))) `
  -Area Structure `
  -Check 'ConvertPascal pipeline numbering is clean' `
  -PassDetails 'ConvertPascal steps are sequential and indentation is normalized.' `
  -FailDetails 'ConvertPascal still has duplicate or oddly indented step comments.'

Add-Check -Condition (($integrationText.Contains('\{\$R\s+\*\.dfm\}')) -and
  ($integrationText.Contains('{$R *.fmx}')) -and
  ($projectGeneratorText -match "StringReplace\(Result,\s*'.dfm',\s*'.fmx'")) `
  -Area Structure `
  -Check 'Converted projects reference FMX resources' `
  -PassDetails 'Pascal resource directives and DPROJ metadata are converted from *.dfm to *.fmx.' `
  -FailDetails 'Converted Pascal or project metadata can still reference stale *.dfm resources.'

Add-Check -Condition (($integrationText -match 'procedure\s+TConversionOrchestrator\.EnsureFMXResourceDirective') -and
  ($integrationText -match 'Lines\.Insert\(I \+ 1,\s*''\{\$R \*\.fmx\}''\)') -and
  ($projectGeneratorText -match '<FormType>fmx</FormType>')) `
  -Area Structure `
  -Check 'Converted form units always link FMX resources' `
  -PassDetails 'Form units with source DFM files receive {$R *.fmx} when the original directive is missing, and DPROJ form references are tagged as FMX.' `
  -FailDetails 'Converted form units can still omit {$R *.fmx} and fail at runtime with ERresNotFound.'

Add-Check -Condition ($integrationText -match '(?s)FRuntimeNormalizer\.RewriteTextLayoutMath\(FileName, Code\);.*?FRuntimeNormalizer\.NormalizeColors\(Code\);') `
  -Area Structure `
  -Check 'Late generated helper calls receive helper implementations' `
  -PassDetails 'Runtime helper injection is re-run after late rewrite passes emit helper calls.' `
  -FailDetails 'Late generated helper calls may not receive their helper implementations.'

Add-Check -Condition (($liveBindingsText -match 'TLiveBindingInjector') -and ($integrationText -match 'FLiveBindings\.Inject\(Code\)') -and (-not ($integrationText -match 'procedure\s+TConversionOrchestrator\.InjectLiveBindings'))) `
  -Area Structure `
  -Check 'LiveBindings rewrite logic is isolated' `
  -PassDetails 'LiveBindings injection lives in Converter.Rewrite.LiveBindings and Integration delegates to it.' `
  -FailDetails 'LiveBindings extraction is incomplete or has drifted back into Integration.'

Add-Check -Condition (($dfmText -match 'VCL2FMX_MAX_TEXT_DFM_BYTES') -and ($dfmText -match 'VCL2FMXTryReadTextFile')) `
  -Area DFM `
  -Check 'DFM size and encoding guards exist' `
  -PassDetails 'DFM loading uses size and encoding safeguards.' `
  -FailDetails 'DFM size or encoding guard is missing.'

Add-Check -Condition (($integrationText -match 'DFM parser found no root component') -and
  ($integrationText -match 'DFM generator produced invalid or empty FMX') -and
  ($engineText -match 'DFM conversion returned empty output') -and
  ($dfmText -match "StartsText\('object ', Line\)")) `
  -Area DFM `
  -Check 'Empty or invalid FMX output is rejected' `
  -PassDetails 'DFM parsing is case-insensitive and empty or invalid generated FMX cannot be saved as successful output.' `
  -FailDetails 'The DFM pipeline can still accept or save empty output.'

Add-Check -Condition (($dfmText -match 'TestStreamFormat\(FileStream\) = sofBinary') -and
  ($dfmText -match 'ObjectResourceToText\(InputStream, OutputStream\)') -and
  ($dfmText -match 'ObjectBinaryToText\(InputStream, OutputStream\)') -and
  ($engineText -match "UILog\('  Detecting DFM stream format\.\.\.'\)")) `
  -Area DFM `
  -Check 'Delphi binary DFM streams are detected and converted' `
  -PassDetails 'DFM loading uses Delphi stream-format detection, resource conversion, and raw-binary fallback without pre-decoding binary data as text.' `
  -FailDetails 'Binary DFM handling is missing or can still pre-decode binary data as text.'

Add-Check -Condition (($liveBindingsText -match 'AnalysisLines\.Text := VCL2FMXStripCommentsForAnalysis\(Lines\.Text\)') -and
  ($liveBindingsText -match "SameText\(TrimmedLine, 'initialization'\)") -and
  ($compatibilityText -match 'for J := 0 to AnalysisLines\.Count - 1') -and
  ($compatibilityText -match 'CandidateIdx := J \+ 1')) `
  -Area Structure `
  -Check 'Generated declarations and methods use active Pascal structure' `
  -PassDetails 'Compatibility and LiveBindings insertion points ignore comments and remain outside initialization and finalization blocks.' `
  -FailDetails 'Generated declarations or methods may still be injected into comments or initialization code.'

Add-Check -Condition (($winApiText -match 'AnalysisLines\.Text := VCL2FMXStripCommentsForAnalysis\(PascalCode\)') -and
  ($winApiText -match "Trim\(AnalysisLines\[I\]\) = ''") -and
  ($winApiText -match 'whole-file regex here would also remove unit names from comments') -and
  ($winApiText -match 'for J := 0 to High\(Words\) do') -and
  ($winApiText -match 'Line := StringReplace\(Line, W, ConvertColor\(W\)') -and
  ($winApiText -match 'Theme-dependent VCL color clActiveCaption used')) `
  -Area Comments `
  -Check 'WinAPI and graphics rewrites preserve comments and handle colors consistently' `
  -PassDetails 'Comment-only code is skipped, color arrays are converted, and theme-dependent colors are explicitly marked for review.' `
  -FailDetails 'WinAPI or graphics rewrites may still alter comments or silently mishandle color constants.'

Add-Check -Condition (($dfmText -match "SameText\(CompClass, 'TEdit'\) and SameText\(PropName, 'PasswordChar'\)") -and ($dfmText -match "ConvertedPropName := 'Password'") -and ($dfmText -match 'BoolToStr\(not SameText\(Trim\(PropValue\), ''#0''\)')) `
  -Area DFM `
  -Check 'VCL PasswordChar is converted to FMX Password' `
  -PassDetails 'TEdit PasswordChar is translated to the FMX Password Boolean before output.' `
  -FailDetails 'TEdit PasswordChar conversion guard is missing.'

Add-Check -Condition (-not ($dfmText -match 'FindBestMatch\(Component\.ComponentClass\)')) `
  -Area DFM `
  -Check 'DFM mapper lookup uses safe path' `
  -PassDetails 'DFM parser avoids direct FindBestMatch component resolution.' `
  -FailDetails 'DFM parser uses direct FindBestMatch for component resolution.'

Add-Check -Condition (($projectGeneratorText -match 'VCL2FMXIsBuildArtifactFolder') -and ($projectGeneratorText -match 'VCL2FMX_RUNTIME_SCORE_HISTORY')) `
  -Area Constants `
  -Check 'Project generator uses shared constants' `
  -PassDetails 'Project generator uses shared build-folder and scoring constants.' `
  -FailDetails 'Project generator appears to have reverted to hardcoded constants.'

Add-Check -Condition (($mapperText -match 'IsValidMappingPackAction') -and ($mapperText -match 'SortedFiles') -and ($mapperText -match 'unsupported action') -and ($mapperText -match 'LoadedMappingPacks')) `
  -Area 'Mapping packs' `
  -Check 'Mapping-pack loader guardrails exist' `
  -PassDetails 'Mapping-pack action validation and atomic rule loading are present.' `
  -FailDetails 'Mapping-pack loader guardrails are missing.'

Add-Check -Condition (($thirdPartyText -match 'TThirdPartyHandler') -and ($thirdPartyText -match 'AnalyzeComponent') -and ($thirdPartyText -match 'DevExpress') -and ($thirdPartyText -match 'TMS')) `
  -Area 'Third-party' `
  -Check 'Fallback third-party detection remains available' `
  -PassDetails 'Hardcoded fallback third-party detection remains available alongside mapping packs.' `
  -FailDetails 'Fallback third-party detection appears to have been removed or damaged.'

Test-JsonMappingPacks

$guardScript = Join-Path $ProjectRoot 'tools\run_regression_guards.ps1'
$guardReport = Join-Path $env:TEMP ('VCL2FMX_REGRESSION_FOR_ACCEPTANCE_{0}.txt' -f (Get-Date -Format 'yyyy-MM-dd_HHmmss'))
$guard = Invoke-Process -FilePath 'powershell.exe' `
  -Arguments ('-ExecutionPolicy Bypass -File "{0}" -ProjectRoot "{1}" -ReportPath "{2}" -FailOnBlockers' -f $guardScript, $ProjectRoot, $guardReport) `
  -WorkingDirectory $ProjectRoot
  Add-Check -Condition ($guard.ExitCode -eq 0) `
    -Area Guards `
    -Check 'Regression guards pass' `
    -PassDetails ('Regression guard report: ' + $guardReport) `
    -FailDetails $(if (($guard.StdOut + $guard.StdErr).Trim() -ne '') { ($guard.StdOut + $guard.StdErr).Trim() } else { 'Regression guard process returned a nonzero exit code.' })

$mappingSmokeScript = Join-Path $ProjectRoot 'tests\mapping_pack_smoke\run_mapping_pack_smoke_guard.ps1'
if (Test-Path -LiteralPath $mappingSmokeScript) {
  $mappingSmoke = Invoke-Process -FilePath 'powershell.exe' `
    -Arguments ('-ExecutionPolicy Bypass -File "{0}"' -f $mappingSmokeScript) `
    -WorkingDirectory (Split-Path -Parent $mappingSmokeScript)
  Add-Check -Condition ($mappingSmoke.ExitCode -eq 0) `
    -Area Guards `
    -Check 'Mapping-pack smoke output guard passes' `
    -PassDetails 'Mapping-pack smoke output contains expected conversions, detect-only omissions, and report entries.' `
    -FailDetails $(if (($mappingSmoke.StdOut + $mappingSmoke.StdErr).Trim() -ne '') { ($mappingSmoke.StdOut + $mappingSmoke.StdErr).Trim() } else { 'Mapping-pack smoke guard returned a nonzero exit code.' })
}

$frenchBetaGuardScript = Join-Path $ProjectRoot 'tests\french_beta_regression\run_guard.ps1'
if (Test-Path -LiteralPath $frenchBetaGuardScript) {
  $frenchBetaGuard = Invoke-Process -FilePath 'powershell.exe' `
    -Arguments ('-ExecutionPolicy Bypass -File "{0}" -ProjectRoot "{1}"' -f $frenchBetaGuardScript, $ProjectRoot) `
    -WorkingDirectory (Split-Path -Parent $frenchBetaGuardScript)
  Add-Check -Condition ($frenchBetaGuard.ExitCode -eq 0) `
    -Area Guards `
    -Check 'French beta regression corpus passes' `
    -PassDetails 'Valid DFMs produce nonempty FMX, generated Pascal compiles, comments and conditional uses survive, and malformed DFMs are blocked.' `
    -FailDetails $(if (($frenchBetaGuard.StdOut + $frenchBetaGuard.StdErr).Trim() -ne '') { ($frenchBetaGuard.StdOut + $frenchBetaGuard.StdErr).Trim() } else { 'French beta regression guard returned a nonzero exit code.' })
}

if (-not $SkipBuild) {
  $rsvars = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat'
  $msbuild = 'C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe'
  $dproj = Join-Path $ProjectRoot 'VCL2FMXConverter.dproj'
  $buildCommand = ('call "{0}" && "{1}" "{2}" /t:Build /p:Config=Release /p:Platform=Win32' -f $rsvars, $msbuild, $dproj)
  $build = Invoke-Process -FilePath 'cmd.exe' -Arguments ('/c "' + $buildCommand + '"') -WorkingDirectory $ProjectRoot
  $buildOutput = ($build.StdOut + $build.StdErr)
  Add-Check -Condition (($build.ExitCode -eq 0) -and ($buildOutput -match '0 Warning\(s\)') -and ($buildOutput -match '0 Error\(s\)')) `
    -Area Build `
    -Check 'Release MSBuild passes cleanly' `
    -PassDetails 'Release build completed with 0 warnings and 0 errors.' `
    -FailDetails $buildOutput.Trim()
}

$releaseExe = Join-Path $ProjectRoot 'Win32\Release\VCL2FMXConverter.exe'
Add-Check -Condition (Test-Path -LiteralPath $releaseExe) `
  -Area Build `
  -Check 'Release executable exists' `
  -PassDetails $releaseExe `
  -FailDetails 'Release executable is missing after build.'

$failCount = @($Results | Where-Object { $_.Status -eq 'Fail' }).Count
$passCount = @($Results | Where-Object { $_.Status -eq 'Pass' }).Count
$infoCount = @($Results | Where-Object { $_.Status -eq 'Info' }).Count

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('VCL2FMXConverter Acceptance Gate')
[void]$sb.AppendLine('================================')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Generated: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
[void]$sb.AppendLine('Project root: ' + $ProjectRoot)
[void]$sb.AppendLine(('Summary: {0} pass item(s), {1} fail item(s), {2} info item(s)' -f $passCount, $failCount, $infoCount))
[void]$sb.AppendLine('')

$reportGroups = @('Encoding', 'Save', 'Context', 'Structure', 'DFM', 'Constants', 'Mapping packs', 'Third-party', 'Guards', 'Build', 'Reporting', 'Workspace')
$reportGroups += @($Results.Area | Where-Object { $_ -notin $reportGroups } | Sort-Object -Unique)

foreach ($group in $reportGroups) {
  $items = @($Results | Where-Object { $_.Area -eq $group })
  if ($items.Count -eq 0) {
    continue
  }

  [void]$sb.AppendLine($group)
  [void]$sb.AppendLine(('-' * $group.Length))
  foreach ($item in $items) {
    [void]$sb.AppendLine(('[{0}] {1}' -f $item.Status.ToUpperInvariant(), $item.Check))
    [void]$sb.AppendLine(('  {0}' -f $item.Details))
  }
  [void]$sb.AppendLine('')
}

[System.IO.File]::WriteAllText($ReportPath, $sb.ToString(), [System.Text.UTF8Encoding]::new($true))
Write-Output ('Acceptance report saved to: ' + $ReportPath)
Write-Output ('Summary: {0} pass item(s), {1} fail item(s), {2} info item(s)' -f $passCount, $failCount, $infoCount)

if ($failCount -gt 0) {
  throw ('Acceptance gate failed with {0} item(s). Review: {1}' -f $failCount, $ReportPath)
}
