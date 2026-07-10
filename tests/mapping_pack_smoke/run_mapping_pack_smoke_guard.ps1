$ErrorActionPreference = 'Stop'

$OutputRoot = Join-Path $PSScriptRoot 'output'
$FmxPath = Join-Path $OutputRoot 'UnitDevExpressMock.fmx'
$ReportHtmlPath = Join-Path $OutputRoot 'VCL_to_FMX_Conversion_Report.html'
$ReportTextPath = Join-Path $OutputRoot 'VCL_to_FMX_Conversion_Report.txt'

if (-not (Test-Path -LiteralPath $FmxPath)) {
  throw "Missing generated FMX file: $FmxPath. Run the converter against tests\mapping_pack_smoke\source first."
}

if (-not (Test-Path -LiteralPath $ReportHtmlPath)) {
  throw "Missing generated HTML report: $ReportHtmlPath. Run the converter against tests\mapping_pack_smoke\source first."
}

$Fmx = Get-Content -LiteralPath $FmxPath -Raw
$ReportHtml = Get-Content -LiteralPath $ReportHtmlPath -Raw
$ReportText = if (Test-Path -LiteralPath $ReportTextPath) {
  Get-Content -LiteralPath $ReportTextPath -Raw
}
else {
  ''
}

$Failed = $false

function Test-RequiredText {
  param(
    [Parameter(Mandatory = $true)][string]$Text,
    [Parameter(Mandatory = $true)][string]$Pattern,
    [Parameter(Mandatory = $true)][string]$Label
  )

  if ($Text -notmatch [regex]::Escape($Pattern)) {
    Write-Host "FAIL: missing $Label"
    $script:Failed = $true
  }
}

function Test-AbsentText {
  param(
    [Parameter(Mandatory = $true)][string]$Text,
    [Parameter(Mandatory = $true)][string]$Pattern,
    [Parameter(Mandatory = $true)][string]$Label
  )

  if ($Text -match [regex]::Escape($Pattern)) {
    Write-Host "FAIL: unexpected $Label"
    $script:Failed = $true
  }
}

Test-RequiredText -Text $Fmx -Pattern 'cxButton1: TButton' -Label 'TcxButton to TButton conversion'
Test-RequiredText -Text $Fmx -Pattern 'cxTextEdit1: TEdit' -Label 'TcxTextEdit to TEdit conversion'
Test-RequiredText -Text $Fmx -Pattern 'cxMemo1: TMemo' -Label 'TcxMemo to TMemo conversion'
Test-RequiredText -Text $Fmx -Pattern 'cxMaskEdit1: TEdit' -Label 'TcxMaskEdit partial TEdit conversion'
Test-RequiredText -Text $Fmx -Pattern "Text = 'Click Me'" -Label 'Caption to Text mapping'
Test-AbsentText -Text $Fmx -Pattern 'cxGrid1: TcxGrid' -Label 'detect-only TcxGrid output'
Test-AbsentText -Text $Fmx -Pattern 'dxRibbon1: TdxRibbon' -Label 'detect-only TdxRibbon output'

$CombinedReport = $ReportHtml + "`n" + $ReportText
Test-RequiredText -Text $CombinedReport -Pattern 'DevExpress_MappingPack_v1' -Label 'DevExpress mapping pack name'
Test-RequiredText -Text $CombinedReport -Pattern 'Mapping pack partial conversion' -Label 'partial conversion report section'
Test-RequiredText -Text $CombinedReport -Pattern 'TcxMaskEdit' -Label 'TcxMaskEdit report entry'
Test-RequiredText -Text $CombinedReport -Pattern 'Mapping pack detection only' -Label 'detect-only report section'
Test-RequiredText -Text $CombinedReport -Pattern 'TcxGrid' -Label 'TcxGrid detect-only report entry'
Test-RequiredText -Text $CombinedReport -Pattern 'TdxRibbon' -Label 'TdxRibbon detect-only report entry'

if ($Failed) {
  exit 1
}

Write-Host 'MAPPING_PACK_SMOKE_GUARD_PASS'
