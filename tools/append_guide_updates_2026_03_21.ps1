$ErrorActionPreference = 'Stop'

$eng$eng = $EngineeringGuidePath
$user$user = $UserGuidePath

function AppendUpdateSection($doc, $heading, $paragraphs) {
  $contentText = $doc.Content.Text
  if ($contentText.Contains($heading)) {
    return
  }
  $range = $doc.Content
  $range.Collapse(0)
  $range.InsertAfter("`r`r" + $heading + "`r")
  foreach ($p in $paragraphs) {
    $range = $doc.Content
    $range.Collapse(0)
    $range.InsertAfter($p + "`r")
  }
}

$word = New-Object -ComObject Word.Application
$word.Visible = $false

try {
  $doc = $word.Documents.Open($eng)
  AppendUpdateSection $doc 'Engineering Update - March 21, 2026' @(
    'This guide was reviewed after the generic recovery and public-release sweep. The live converter is now being maintained under a strict generic-only rule: fixes must be reusable across Delphi VCL projects and must not contain application-specific form names, control names, business procedures, schedules, log files, or other project-specific identifiers.',
    'Current generic additions beyond the earlier baseline include TDBNavigator to TBindNavigator, TDBComboBox to TComboEdit, scoped StyledSettings emission, generic label width and wrap normalization, styled container background handling, generic bound date and time parsing helpers, FMX media duration and notify bridging, startup timing protection for toggle and OnEnter behavior, and a two-path editable-grid strategy that separates browse grids from selector-grid editing scenarios.',
    'The project-generation path now preserves the source Application.CreateForm list generically rather than trying to infer form lifetime from later constructor calls. The integration layer also contains more explicit generic runtime helpers, including ApplyStyledBackgroundColor, ApplyContainerBackgroundColor, GeneratedTryParseBoundDate, GeneratedTryParseBoundTime, GeneratedAssignBoundFieldValue, toggle-state wrappers, startup-enter guards, deferred FormShow toggle execution, and generic FMX media-notify support.',
    'Before any public release, run a contamination sweep on the live converter source. Compare the converter files against the names of units and form classes from a real input project, then run a forbidden-marker sweep for historically unsafe identifiers. Any hit in a live converter source file should be treated as a release blocker unless it appears only in a historical audit document. Temporary test or scratch units should also be removed from the converter root before release packaging.'
  )
  $doc.Save()
  $doc.Close()

  $doc2 = $word.Documents.Open($user)
  AppendUpdateSection $doc2 'User Guide Update - March 21, 2026' @(
    'The converter is being maintained as a generic VCL-to-FMX migration tool. If a problem only affects one application and cannot be expressed as a reusable converter rule, that fix should be handled in the generated application or in a private post-conversion step rather than in the public converter core.',
    'Important current generic behavior to know when validating a converted app: long message and error dialogs are now routed through a scrollable text dialog, date and time entry in generated bound edits uses explicit parse and commit helpers, editable data-aware grids now follow either a browse-grid plus separate editors pattern or a selector-grid plus separate editors pattern, and FMX media duration and notify differences are normalized more explicitly than before.',
    'When working iteratively, prefer this cycle: regenerate into a clean output folder, open the generated project in Delphi, fix structural and runtime issues first, and only then spend time on visual polish. If you use AI assistance or outside review, insist on generic fixes and periodically sweep the converter source for project-specific identifiers before treating a build as release-ready.',
    'Use the Generic Rules Reference alongside this guide when you need a compact table of the active mappings, helper behaviors, and runtime conversion rules. Use the sweep report when you need to verify that the live converter source is still clean enough for a public-release review.'
  )
  $doc2.Save()
  $doc2.Close()

  Write-Output 'GUIDE_UPDATES_APPENDED'
}
finally {
  $word.Quit()
}

