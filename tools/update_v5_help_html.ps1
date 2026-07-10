$ErrorActionPreference = 'Stop'

$helpRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\Help'
$today = 'June 25, 2026'

if (-not (Test-Path -LiteralPath $helpRoot)) {
  throw "Help folder not found: $helpRoot"
}

foreach ($file in Get-ChildItem -LiteralPath $helpRoot -Recurse -File -Include *.html,*.json,*.txt,*.h,*.xml) {
  $text = Get-Content -LiteralPath $file.FullName -Raw
  $text = $text.Replace('v4.1.8', 'v5.0')
  $text = $text.Replace('V4.1.8', 'V5.0')
  $text = $text.Replace('Version 4.1.8', 'Version 5.0')
  $text = $text.Replace('current v4.1.8', 'current v5.0')
  $text = $text.Replace('VCL2FMX Converter v4.1.8 User Guide', 'VCL2FMX Converter v5.0 User Guide')
  $text = $text.Replace('Updated June 14, 2026', 'Updated ' + $today)
  $text = $text.Replace('Generated 2026-05-20 12:33', 'Generated 2026-06-25')
  $text = $text.Replace('Version 1.0 &bull; Build 5', 'Version 5.0 &bull; Build 5')
  $text = $text.Replace('Version 1.0', 'Version 5.0')
  $text = $text.Replace('buildNumber":"5"', 'buildNumber":"5.0"')
  $text = $text.Replace('generatedAt":"2026-05-20 12:33"', 'generatedAt":"2026-06-25"')
  $text = $text.Replace('VCL2FMXConverter_v4_1_User_Guide', 'VCL2FMXConverter_v5_0_User_Guide')
  $text = $text.Replace('vcl2fmxconverter-v4-1-user-guide.html', 'vcl2fmxconverter-v5-0-user-guide.html')
  Set-Content -LiteralPath $file.FullName -Value $text -Encoding UTF8
}

$oldTopic = Join-Path $helpRoot 'topics\vcl2fmxconverter-v4-1-user-guide.html'
$newTopic = Join-Path $helpRoot 'topics\vcl2fmxconverter-v5-0-user-guide.html'
if ((Test-Path -LiteralPath $oldTopic) -and -not (Test-Path -LiteralPath $newTopic)) {
  Rename-Item -LiteralPath $oldTopic -NewName 'vcl2fmxconverter-v5-0-user-guide.html'
}

$contractsTopic = Join-Path $helpRoot 'topics\conversion-contracts-in-v5-0.html'
@'
<!doctype html><html><head><meta charset="utf-8"><title>Conversion Contracts in v5.0</title><link rel="stylesheet" href="../style.css"></head><body class="topic-page"><main><div class="doc-topic" style="display:block;">
<h1>Conversion Contracts in v5.0</h1>
<p>Version 5.0 adds an executable conversion-contract system. Contracts are small Delphi fixtures paired with expectation files. They prove that known conversion rules still work after converter changes.</p>
<table class="doc-table">
<tbody><tr><th>Contract Area</th><th>What It Protects</th></tr>
<tr><td>Include analysis</td><td>Beside-source, subfolder, missing, outside-tree, nested, recursive, conditional, commented, and UTF-8 Pascal include directives.</td></tr>
<tr><td>Windows messaging</td><td>SendMessage, PostMessage, Perform, WndProc, message declarations, WM/CM/CN/common-control families, WM_USER, system commands, and false positives.</td></tr>
<tr><td>Uses cleanup</td><td>Removal or preservation of VCL and Winapi units, including protected/conditional uses blocks and Vcl.Themes cleanup.</td></tr>
<tr><td>DFM/FMXL generation</td><td>TMemo string collections, TStringGrid event ordering, accented text, and paired Pascal/DFM form behavior.</td></tr>
<tr><td>Graphics and GDI</td><td>FMX canvas substitutions where reliable, plus visual-review reporting where drawing still needs inspection.</td></tr>
</tbody></table>
<p>The current v5.0 contract suite contains 175 expectations. The release-candidate run passed with 175 passing and 0 failing contracts.</p>
<p>Contracts are not loaded during normal user conversions. They are engineering fixtures used by the test runner to verify the converter before release.</p>
</div><div class="page-nav"><a href="../index.html" target="_top">Contents</a></div></main></body></html>
'@ | Set-Content -LiteralPath $contractsTopic -Encoding UTF8

$tocPath = Join-Path $helpRoot 'toc.json'
if (Test-Path -LiteralPath $tocPath) {
  $tocText = Get-Content -LiteralPath $tocPath -Raw
  if ($tocText -notmatch 'conversion-contracts-in-v5-0') {
    $toc = $tocText | ConvertFrom-Json
    $toc = @($toc) + [pscustomobject]@{
      title = 'Conversion Contracts in v5.0'
      url = 'topics/conversion-contracts-in-v5-0.html'
      status = 'Approved'
      owner = 'Auto Import'
    }
    $toc | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $tocPath -Encoding UTF8
  }
}

$searchPath = Join-Path $helpRoot 'search-index.json'
if (Test-Path -LiteralPath $searchPath) {
  $searchText = Get-Content -LiteralPath $searchPath -Raw
  if ($searchText -notmatch 'conversion-contracts-in-v5-0') {
    $items = $searchText | ConvertFrom-Json
    $items = @($items) + [pscustomobject]@{
      title = 'Conversion Contracts in v5.0'
      url = 'topics/conversion-contracts-in-v5-0.html'
      tags = 'contracts,regression,testing,v5'
      helpId = 'IDH_CONVERSION_CONTRACTS_IN_V5_0'
      owner = 'Auto Import'
    }
    $items | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $searchPath -Encoding UTF8
  }
}

$helpMap = Join-Path $helpRoot 'help-map.txt'
if (Test-Path -LiteralPath $helpMap) {
  $map = Get-Content -LiteralPath $helpMap -Raw
  if ($map -notmatch 'IDH_CONVERSION_CONTRACTS_IN_V5_0') {
    Add-Content -LiteralPath $helpMap -Value 'IDH_CONVERSION_CONTRACTS_IN_V5_0=conversion-contracts-in-v5-0.html'
  }
}

$sitemap = Join-Path $helpRoot 'sitemap.xml'
if (Test-Path -LiteralPath $sitemap) {
  $xml = Get-Content -LiteralPath $sitemap -Raw
  if ($xml -notmatch 'conversion-contracts-in-v5-0') {
    $xml = $xml.Replace('</urlset>', '  <url><loc>topics/conversion-contracts-in-v5-0.html</loc></url>' + "`r`n" + '</urlset>')
    Set-Content -LiteralPath $sitemap -Value $xml -Encoding UTF8
  }
}

Write-Output 'HELP_HTML_UPDATED'
