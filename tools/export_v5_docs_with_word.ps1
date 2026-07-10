$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')

$pdfRoot = Join-Path $DocsRoot 'pdf'
$htmlRoot = $ReferencesHtmlRoot
New-Item -ItemType Directory -Path $pdfRoot -Force | Out-Null
New-Item -ItemType Directory -Path $htmlRoot -Force | Out-Null

$docPaths = @(
  $UserGuidePath,
  $EngineeringGuidePath,
  $ComponentMappingReferencePath,
  $GenericRulesReferenceDocxPath,
  (Join-Path $NotesRoot 'VCL2FMXConverter_v5_Contract_System_Overview.docx')
) | Where-Object { Test-Path -LiteralPath $_ }

$word = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0

  foreach ($docPath in $docPaths) {
    $doc = $null
    try {
      $doc = $word.Documents.Open($docPath)
      if ($doc.TablesOfContents.Count -gt 0) {
        $doc.TablesOfContents.Item(1).Update() | Out-Null
        $doc.Save() | Out-Null
      }

      $baseName = [IO.Path]::GetFileNameWithoutExtension($docPath)
      $pdfPath = Join-Path $pdfRoot ($baseName + '.pdf')
      $doc.ExportAsFixedFormat($pdfPath, 17) | Out-Null

      if ($docPath -eq $ComponentMappingReferencePath) {
        $mappingHtmlPath = Join-Path $htmlRoot 'VCL2FMXConverter_Component_Mapping_Reference_v5_0.html'
        $wdFormatFilteredHTML = 10
        $doc.SaveAs([ref][object]$mappingHtmlPath, [ref][object]$wdFormatFilteredHTML) | Out-Null
      }
    }
    finally {
      if ($doc -ne $null) {
        $doc.Close($true) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
      }
    }
  }

  Write-Output 'PDF_EXPORT_COMPLETE'
  foreach ($docPath in $docPaths) {
    Join-Path $pdfRoot ([IO.Path]::GetFileNameWithoutExtension($docPath) + '.pdf')
  }
  Join-Path $htmlRoot 'VCL2FMXConverter_Component_Mapping_Reference_v5_0.html'
  $GenericRulesReferenceHtmlPath
}
finally {
  if ($word -ne $null) {
    $word.Quit() | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
  }
  [gc]::Collect()
  [gc]::WaitForPendingFinalizers()
}
