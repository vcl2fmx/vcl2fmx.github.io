param(
  [string]$RevisionDate = 'June 26, 2026'
)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$v4Root = 'C:\New Delphi Projects\VCL2FMXConverterV4'

$userMaster = Join-Path $v4Root 'docs\guides\VCL2FMXConverter_v4_1_8_User_Guide.docx'
$engMaster = Join-Path $v4Root 'docs\guides\VCL2FMXConverter_v4_1_8_Engineering_Guide.docx'
$userDoc = Join-Path $root 'docs\guides\VCL2FMXConverter_v5_0_User_Guide.docx'
$engDoc = Join-Path $root 'docs\guides\VCL2FMXConverter_v5_0_Engineering_Guide.docx'
$userGraphic = Join-Path $root 'docs\guides\graphics\VCL2FMXConverter_User_Guide_Graphic.svg'
$engGraphic = Join-Path $root 'docs\guides\graphics\VCL2FMXConverter_Engineering_Guide_Graphic.svg'

Copy-Item -LiteralPath $userMaster -Destination $userDoc -Force
Copy-Item -LiteralPath $engMaster -Destination $engDoc -Force

function Release-ComObjectSafe($obj) {
  if ($null -ne $obj) {
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($obj) | Out-Null } catch {}
  }
}

function Replace-AllText($doc, [string]$findText, [string]$replaceText) {
  $find = $doc.Content.Find
  $find.ClearFormatting()
  $find.Replacement.ClearFormatting()
  $find.Text = $findText
  $find.Replacement.Text = $replaceText
  $find.Forward = $true
  $find.Wrap = 1
  $find.Format = $false
  $find.MatchCase = $false
  $find.MatchWholeWord = $false
  $find.MatchWildcards = $false
  $find.Execute([ref]$findText, [ref]$false, [ref]$false, [ref]$false, [ref]$false, [ref]$false, [ref]$true, [ref]1, [ref]$false, [ref]$replaceText, [ref]2) | Out-Null
}

function Find-HeadingParagraphStart($doc, [string]$startsWith) {
  foreach ($p in @($doc.Paragraphs)) {
    $text = $p.Range.Text
    if ($text) {
      $text = $text.Trim()
      if ($text.StartsWith($startsWith, [System.StringComparison]::OrdinalIgnoreCase)) {
        $styleName = ''
        try { $styleName = [string]$p.Range.Style.NameLocal } catch {}
        if ($styleName.StartsWith('Heading', [System.StringComparison]::OrdinalIgnoreCase)) {
          return $p.Range.Start
        }
      }
    }
  }
  throw "Could not find heading paragraph starting with '$startsWith'."
}

function Set-StandardMargins($doc) {
  foreach ($section in @($doc.Sections)) {
    $ps = $section.PageSetup
    $ps.TopMargin = 54
    $ps.BottomMargin = 54
    $ps.LeftMargin = 54
    $ps.RightMargin = 54
    $ps.HeaderDistance = 36
    $ps.FooterDistance = 36
  }
}

function Replace-FirstInlineGraphic($doc, [string]$graphicPath) {
  if (!(Test-Path -LiteralPath $graphicPath)) { return }
  if ($doc.InlineShapes.Count -lt 1) { return }

  $old = $doc.InlineShapes.Item(1)
  $range = $old.Range
  $width = $old.Width
  $height = $old.Height
  $old.Delete()
  $newShape = $doc.InlineShapes.AddPicture($graphicPath, $false, $true, $range)
  if ($width -gt 0) { $newShape.Width = $width }
  if ($height -gt 0) { $newShape.Height = $height }
}

function Write-Para($selection, $doc, [string]$styleName, [string]$text) {
  $selection.Style = $doc.Styles.Item($styleName)
  $selection.TypeText($text)
  $selection.TypeParagraph()
}

function Insert-UserContractsSection($word, $doc) {
  $insertAt = Find-HeadingParagraphStart $doc '15. Operational Best Practices'
  $selection = $word.Selection
  $selection.SetRange($insertAt, $insertAt)
  $selection.TypeParagraph()

  Write-Para $selection $doc 'Heading 2' '14.1 Conversion Contracts in v5.0'
  Write-Para $selection $doc 'Normal' 'Version 5.0 adds an executable conversion-contract system. A contract is a small Delphi fixture, paired with an expectation file, that proves a known conversion rule still behaves correctly. Contracts are used by the engineering test runner before release. They are not loaded during a normal conversion and they do not compare every user source file against a long checklist.'
  Write-Para $selection $doc 'Normal' 'For an operator, the contract system matters because it explains why v5.0 is more disciplined than earlier releases. The converter rules are tested against specific examples for include files, Windows messaging, protected uses clauses, DFM/FMXL output, graphics and GDI substitutions, and project integration. When a real project reveals a reusable conversion issue, the preferred v5.0 workflow is to add a contract first, then update the converter until the contract passes.'
  Write-Para $selection $doc 'Normal' 'The contracts live in the project contracts folder. Each expectation records the input file, expected status, expected conversions, expected manual-review items, units that must be present or absent, required output patterns, and forbidden output patterns. The release-candidate contract run is part of the validation evidence for the converter, while normal user conversions continue through the parser, mapper, rewrite, integration, and project-generation pipeline.'
  Write-Para $selection $doc 'Normal' 'If a conversion report mentions a Windows message, GDI drawing path, include-file issue, protected uses cleanup, or generated FMX behavior that is covered by the contracts, that report item is the converter applying the tested rule to the user project. Some items still remain manual review by design, especially where an automatic FMX replacement would be unsafe for the general user base.'
}

function Insert-EngineeringContractsSection($word, $doc) {
  $insertAt = Find-HeadingParagraphStart $doc '14. Unit-by-Unit Technical Reference'
  $selection = $word.Selection
  $selection.SetRange($insertAt, $insertAt)
  $selection.TypeParagraph()

  Write-Para $selection $doc 'Heading 2' '13.1 v5.0 Conversion Contract System'
  Write-Para $selection $doc 'Normal' 'The v5.0 engineering baseline is contract driven. A conversion contract is a fixture plus expectation that exercises one structural rule of the converter and records the expected output, report behavior, and uses-clause result. Contracts are stored under the project contracts folder and are executed by the contract runner. They are not runtime data for normal conversions.'
  Write-Para $selection $doc 'Normal' 'The contract runner discovers expectation files from the contracts tree, loads the related fixture input, runs the converter against a temporary output location, and validates the generated Pascal, FMX/DFM, conversion report, status, expected issue categories, required units, absent units, required output patterns, and forbidden output patterns. This keeps the test search bounded to the contract inventory instead of comparing every production source file with every contract.'
  Write-Para $selection $doc 'Normal' 'The first v5.0 contract families cover Pascal include-file analysis, Windows messaging detection and reporting, false-positive boundaries, protected and conditional uses cleanup, TMemo/TStrings collection output, TStringGrid event ordering, UTF-8 FMX output, GDI-to-FMX canvas substitutions, and whole-project integration behavior. Include handling is analysis first: include files are resolved safely from the source tree, recursive and outside-tree cases are reported, include contents are analyzed with the same encoding rules as Pascal files, and original include directives remain in generated source.'
  Write-Para $selection $doc 'Normal' 'Windows messaging rules remain category based. The converter detects message APIs, WM/CM/CN/common-control families, TWM/TCM records, WndProc overrides, message declarations, WM_USER offsets, system-command handlers, and false positives. Unsafe or ambiguous behavior is reported with source location, original symbol or API, code excerpt, category, suggested FMX path, and blocking status. Standalone safe cases may be converted only when the contract proves the result is reliable for the general user base.'
  Write-Para $selection $doc 'Normal' 'Future structural changes should start with a fixture and expectation before converter code is changed. This keeps v5.0 fixes reusable, prevents project-only patches, and protects the mapping packs, rewrite rules, include analysis, Windows messaging reports, and generated output from silent regression.'
}

function Update-Toc($doc) {
  if ($doc.TablesOfContents.Count -gt 0) {
    for ($i = 1; $i -le $doc.TablesOfContents.Count; $i++) {
      $doc.TablesOfContents.Item($i).Update()
    }
  }
  foreach ($field in @($doc.Fields)) {
    try {
      if ($field.Type -eq 13 -or $field.Type -eq 37) {
        $field.Update() | Out-Null
      }
    } catch {}
  }
}

function Repair-Guide([string]$path, [string]$graphicPath, [string]$kind) {
  $word = $null
  $doc = $null
  try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $doc = $word.Documents.Open($path)

    Set-StandardMargins $doc
    Replace-AllText $doc '4.1.8' '5.0'
    Replace-AllText $doc 'v4.1.8' 'v5.0'
    Replace-AllText $doc 'Version 4.1.8' 'Version 5.0 Vanguard'
    Replace-AllText $doc 'Version 5.0' 'Version 5.0 Vanguard'
    Replace-AllText $doc 'June 14, 2026' $RevisionDate
    Replace-AllText $doc 'Updated June 14, 2026' ("Revision date: " + $RevisionDate)
    Replace-AllText $doc ("Updated " + $RevisionDate) ("Revision date: " + $RevisionDate)
    Replace-AllText $doc 'Revision date: June 14, 2026' ("Revision date: " + $RevisionDate)
    Replace-AllText $doc 'VCL2FMXConverter v4.1.8' 'VCL2FMXConverter v5.0'
    Replace-AllText $doc 'VCL2FMXConverter v4.1' 'VCL2FMXConverter v5.0'

    Replace-FirstInlineGraphic $doc $graphicPath

    if ($kind -eq 'User') {
      Insert-UserContractsSection $word $doc
    } else {
      Insert-EngineeringContractsSection $word $doc
    }

    Update-Toc $doc
    $doc.Save()
    Write-Output "REPAIRED: $path"
  }
  finally {
    if ($doc -ne $null) {
      try { $doc.Close($false) | Out-Null } catch {}
      Release-ComObjectSafe $doc
    }
    if ($word -ne $null) {
      try { $word.Quit() | Out-Null } catch {}
      Release-ComObjectSafe $word
    }
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
  }
}

Repair-Guide $userDoc $userGraphic 'User'
Repair-Guide $engDoc $engGraphic 'Engineering'
