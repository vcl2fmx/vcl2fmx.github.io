$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')
try {
  & (Join-Path $PSScriptRoot 'build_engineering_guide_docx.ps1') -OutputPath $EngineeringGuideDiagnosticPath
}
catch {
  Write-Host $_.Exception.Message
  Write-Host $_.InvocationInfo.PositionMessage
  Write-Host $_.ScriptStackTrace
  exit 1
}
