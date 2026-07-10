param(
  [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')
. (Join-Path $PSScriptRoot 'load_reference_matrices.ps1')

if (-not $PSBoundParameters.ContainsKey('OutputPath')) {
  $OutputPath = $ComponentMappingReferencePath
}

function Add-Paragraph {
  param(
    $Selection,
    [string]$Text,
    [string]$Style = 'Normal',
    [int]$Alignment = 0,
    [switch]$Italic,
    [switch]$Bold
  )

  $Selection.Style = $Style
  $Selection.ParagraphFormat.Alignment = $Alignment
  $Selection.Font.Italic = [int]$Italic.IsPresent
  $Selection.Font.Bold = [int]$Bold.IsPresent
  $Selection.TypeText($Text)
  $Selection.TypeParagraph()
  $Selection.Font.Italic = 0
  $Selection.Font.Bold = 0
  $Selection.ParagraphFormat.Alignment = 0
}

function Add-Table {
  param(
    $Document,
    $Selection,
    [string[]]$Headers,
    [object[][]]$Rows
  )

  $rowCount = [Math]::Max($Rows.Count, 1) + 1
  $insertAt = [Math]::Max($Document.Content.End - 1, 0)
  $range = $Document.Range($insertAt, $insertAt)
  $table = $Document.Tables.Add($range, $rowCount, $Headers.Count)
  try { $table.Style = 'Table Grid' } catch {}
  $table.Range.Font.Name = 'Segoe UI'
  $table.Range.Font.Size = 9
  $table.Range.ParagraphFormat.SpaceAfter = 2

  for ($c = 0; $c -lt $Headers.Count; $c++) {
    $cell = $table.Cell(1, $c + 1)
    $cell.Range.Text = [string]$Headers[$c]
    $cell.Range.Bold = $true
    $cell.Range.Font.Color = 16777215
    $cell.Shading.BackgroundPatternColor = 8404992
  }

  if ($Rows.Count -eq 0) {
    $table.Cell(2, 1).Range.Text = 'None'
    for ($c = 2; $c -le $Headers.Count; $c++) {
      $table.Cell(2, $c).Range.Text = ''
    }
  }
  else {
    for ($r = 0; $r -lt $Rows.Count; $r++) {
      for ($c = 0; $c -lt $Headers.Count; $c++) {
        $table.Cell($r + 2, $c + 1).Range.Text = [string]$Rows[$r][$c]
      }
    }
  }

  $Selection.SetRange($table.Range.End, $table.Range.End)
  $Selection.TypeParagraph()
  $Selection.TypeParagraph()
}

function Get-UniqueOrdered {
  param([object[]]$Items)

  $seen = @{}
  $result = New-Object System.Collections.Generic.List[string]
  foreach ($item in $Items) {
    $text = [string]$item
    if ([string]::IsNullOrWhiteSpace($text)) { continue }
    if (-not $seen.ContainsKey($text)) {
      $seen[$text] = $true
      $result.Add($text)
    }
  }
  return ,$result.ToArray()
}

$referenceData = Get-ReferenceMatrixData -ProjectRoot $ProjectRoot
$classRows = @($referenceData.ClassRows | Sort-Object vcl_class)
$propertyRows = @($referenceData.PropertyRows)
$eventRows = @($referenceData.EventRows)

$summaryRows = @()
foreach ($mapping in $classRows) {
  $summaryRows += ,@(
    [string]$mapping.vcl_class,
    $(if ([string]::IsNullOrWhiteSpace([string]$mapping.fmx_class)) { 'None / Manual Review' } else { [string]$mapping.fmx_class }),
    [string]$mapping.mapping_type,
    [string]$mapping.confidence,
    [string]$mapping.notes
  )
}

$word = $null
$doc = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  $doc = $word.Documents.Add()
  $sel = $word.Selection

  $section = $doc.Sections.Item(1)
  $section.PageSetup.TopMargin = 54
  $section.PageSetup.BottomMargin = 54
  $section.PageSetup.LeftMargin = 54
  $section.PageSetup.RightMargin = 54

  $normal = $doc.Styles.Item('Normal')
  $normal.Font.Name = 'Segoe UI'
  $normal.Font.Size = 10
  $normal.ParagraphFormat.SpaceAfter = 6

  $title = $doc.Styles.Item('Title')
  $title.Font.Name = 'Cambria'
  $title.Font.Size = 22
  $title.Font.Bold = $true
  $title.Font.Color = 7352422

  $h1 = $doc.Styles.Item('Heading 1')
  $h1.Font.Name = 'Cambria'
  $h1.Font.Size = 16
  $h1.Font.Bold = $true
  $h1.Font.Color = 7352422
  $h1.ParagraphFormat.SpaceBefore = 14
  $h1.ParagraphFormat.SpaceAfter = 8
  $h1.ParagraphFormat.KeepWithNext = $true

  $h2 = $doc.Styles.Item('Heading 2')
  $h2.Font.Name = 'Cambria'
  $h2.Font.Size = 12.5
  $h2.Font.Bold = $true
  $h2.ParagraphFormat.SpaceBefore = 10
  $h2.ParagraphFormat.SpaceAfter = 6
  $h2.ParagraphFormat.KeepWithNext = $true

  Add-Paragraph $sel 'VCL to FMX Component Mapping Reference' 'Title' 1
  Add-Paragraph $sel 'Generated from the current VCL2FMXConverter v5.0 mapping reference data' 'Normal' 1 -Italic
  Add-Paragraph $sel 'Version 5.0 Vanguard' 'Normal' 1 -Bold
  Add-Paragraph $sel ('Revision date: ' + (Get-Date -Format 'MMMM dd, yyyy')) 'Normal' 1
  Add-Paragraph $sel 'Scope: standard VCL classes currently modeled in the converter, their FMX counterparts when known, and the current property/event mapping rows exposed by the live mapper. This document reflects the current v5.0 mapping surface. The 22 JSON mapping packs were compared against the released v4.1.8 set and are unchanged for v5.0.' 'Normal'
  if ($referenceData.SourceMode -eq 'matrix_artifacts') {
    Add-Paragraph $sel 'Source mode: live matrix artifacts exported from the current converter build.' 'Normal'
  }
  else {
    Add-Paragraph $sel 'Source mode: built-in mapper-source fallback. The class/property/event rows were reconstructed from the current mapper source because explicit matrix JSON artifacts were not present in the expected build directories.' 'Normal'
  }

  Add-Paragraph $sel 'Component Summary' 'Heading 1'
  Add-Table $doc $sel @('VCL Component', 'FMX Counterpart', 'Mapping Type', 'Confidence', 'Notes') $summaryRows

  Add-Paragraph $sel 'Detailed Component Reference' 'Heading 1'

  foreach ($mapping in $classRows) {
    $vclClass = [string]$mapping.vcl_class
    $fmxClass = [string]$mapping.fmx_class
    $targetClass = if ([string]::IsNullOrWhiteSpace($fmxClass)) { 'None / Manual Review' } else { $fmxClass }

    Add-Paragraph $sel ($vclClass + ' -> ' + $targetClass) 'Heading 2'

    $summaryDetailRows = @(
      @('VCL Component', $vclClass),
      @('FMX Counterpart', $targetClass),
      @('Mapping Type', [string]$mapping.mapping_type),
      @('Confidence', [string]$mapping.confidence),
      @('Parser Policy', [string]$mapping.parser_policy),
      @('Notes', [string]$mapping.notes)
    )
    Add-Table $doc $sel @('Field', 'Value') $summaryDetailRows

    Add-Paragraph $sel 'Property Mapping Rows' 'Heading 2'
    $classPropertyRows = @($propertyRows | Where-Object { $_.vcl_class -eq $vclClass } | Sort-Object vcl_property)
    $propRows = @()
    foreach ($prop in $classPropertyRows) {
      $propRows += ,@(
        [string]$prop.vcl_property,
        [string]$prop.fmx_property,
        [string]$prop.classification,
        [string]$prop.rule_source,
        $(if ([bool]$prop.needs_transformation) { [string]$prop.transformer } else { '' }),
        [string]$prop.notes
      )
    }
    Add-Table $doc $sel @('VCL Property', 'FMX Property', 'Classification', 'Rule Source', 'Transformer', 'Notes') $propRows

    Add-Paragraph $sel 'Event Mapping Rows' 'Heading 2'
    $classEventRows = @($eventRows | Where-Object { $_.vcl_class -eq $vclClass } | Sort-Object vcl_event)
    $evtRows = @()
    foreach ($event in $classEventRows) {
      $evtRows += ,@(
        [string]$event.vcl_event,
        [string]$event.fmx_event,
        [string]$event.classification,
        $(if ([bool]$event.signature_compatible) { 'Yes' } else { 'No' }),
        [string]$event.rule_source,
        [string]$event.notes
      )
    }
    Add-Table $doc $sel @('VCL Event', 'FMX Event', 'Classification', 'Signature Compatible', 'Rule Source', 'Notes') $evtRows

    Add-Paragraph $sel 'Known FMX Surface' 'Heading 2'
    if (-not [string]::IsNullOrWhiteSpace($fmxClass)) {
      $fmxProps = Get-UniqueOrdered @($classPropertyRows | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.fmx_property) } | ForEach-Object { $_.fmx_property })
      $fmxEvents = Get-UniqueOrdered @($classEventRows | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.fmx_event) } | ForEach-Object { $_.fmx_event })
      $maxRows = [Math]::Max($fmxProps.Count, $fmxEvents.Count)
      $surfaceRows = @()
      for ($i = 0; $i -lt $maxRows; $i++) {
        $surfaceRows += ,@(
          $(if ($i -lt $fmxProps.Count) { [string]$fmxProps[$i] } else { '' }),
          $(if ($i -lt $fmxEvents.Count) { [string]$fmxEvents[$i] } else { '' })
        )
      }
      Add-Table $doc $sel @('Known FMX Properties', 'Known FMX Events') $surfaceRows
    }
    else {
      Add-Paragraph $sel 'No FMX target class is mapped for this item. Treat it as manual-review or unsupported.' 'Normal'
    }
  }

  $outDir = Split-Path -Parent $OutputPath
  if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
  }

  $wdFormatXMLDocument = 16
  $doc.SaveAs([ref][object]$OutputPath, [ref][object]$wdFormatXMLDocument) | Out-Null
}
finally {
  if ($doc -ne $null) {
    try { $doc.Close($true) | Out-Null } catch {}
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null } catch {}
  }
  if ($word -ne $null) {
    try { $word.Quit() | Out-Null } catch {}
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null } catch {}
  }
  [System.GC]::Collect()
  [System.GC]::WaitForPendingFinalizers()
}

Write-Output $OutputPath
