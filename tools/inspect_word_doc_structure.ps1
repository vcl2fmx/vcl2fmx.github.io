param(
  [Parameter(Mandatory = $true)]
  [string]$Path
)

$ErrorActionPreference = 'Stop'
$word = $null
$doc = $null
try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $word.DisplayAlerts = 0
  $doc = $word.Documents.Open((Resolve-Path -LiteralPath $Path).Path)
  $ps = $doc.Sections.Item(1).PageSetup
  Write-Output ("FILE: {0}" -f $Path)
  Write-Output ("MARGINS twips: L={0} R={1} T={2} B={3}" -f $ps.LeftMargin,$ps.RightMargin,$ps.TopMargin,$ps.BottomMargin)
  Write-Output ("TOC count: {0}" -f $doc.TablesOfContents.Count)
  Write-Output ("InlineShapes: {0}; Shapes: {1}" -f $doc.InlineShapes.Count,$doc.Shapes.Count)
  Write-Output "HEADINGS:"
  for ($i = 1; $i -le $doc.Paragraphs.Count; $i++) {
    $p = $doc.Paragraphs.Item($i)
    $style = [string]$p.Range.Style.NameLocal
    if ($style -like 'Heading*' -or $style -eq 'Title') {
      $text = ($p.Range.Text -replace "[`r`n]+",' ').Trim()
      if ($text.Length -gt 0) {
        Write-Output ("{0}: {1}: {2}" -f $i,$style,$text)
      }
    }
  }
}
finally {
  if ($doc -ne $null) {
    try { $doc.Close($false) | Out-Null } catch {}
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null } catch {}
  }
  if ($word -ne $null) {
    try { $word.Quit() | Out-Null } catch {}
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null } catch {}
  }
  [gc]::Collect()
  [gc]::WaitForPendingFinalizers()
}
