$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$guidesRoot = Join-Path $projectRoot 'docs\guides'

foreach ($file in Get-ChildItem -LiteralPath $guidesRoot -File | Where-Object { $_.Name -like 'VCL2FMX*Help*' -or $_.Extension -eq '.json' }) {
  $text = Get-Content -LiteralPath $file.FullName -Raw
  $text = $text.Replace('C:\New Delphi Projects\VCL2FMXConverterV4\docs\Help', 'C:\New Delphi Projects\VCL2FMXConverterV5\docs\Help')
  $text = $text.Replace('VCL2FMX Converter v4.1.8 User Guide', 'VCL2FMX Converter v5.0 User Guide')
  $text = $text.Replace('VCL2FMXConverter_v4_1_8_User_Guide', 'VCL2FMXConverter_v5_0_User_Guide')
  $text = $text.Replace('VCL2FMXConverter_v4_1_User_Guide', 'VCL2FMXConverter_v5_0_User_Guide')
  $text = $text.Replace('IDH_VCL2FMXCONVERTER_V4_1_8_USER_GUIDE', 'IDH_VCL2FMXCONVERTER_V5_0_USER_GUIDE')
  $text = $text.Replace('IDH_VCL2FMXCONVERTER_V4_1_USER_GUIDE', 'IDH_VCL2FMXCONVERTER_V5_0_USER_GUIDE')
  $text = $text.Replace('vcl2fmxconverter-v4-1-user-guide.html', 'vcl2fmxconverter-v5-0-user-guide.html')
  $text = $text.Replace('Updated June 14, 2026', 'Updated June 25, 2026')
  $text = $text.Replace('current v4.1.8', 'current v5.0')
  $text = $text.Replace('Version 4.1.8', 'Version 5.0')
  $text = $text.Replace('v4.1.8', 'v5.0')
  $text = $text.Replace('VCL2FMXConverterV4', 'VCL2FMXConverterV5')
  Set-Content -LiteralPath $file.FullName -Value $text -Encoding UTF8
}

Write-Output 'HELP_PROJECT_SOURCES_UPDATED'
