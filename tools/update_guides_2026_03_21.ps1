$ErrorActionPreference = 'Stop'

$eng$eng = $EngineeringGuidePath
$user$user = $UserGuidePath

function FindReplace($doc, $findText, $replaceText) {
  $range = $doc.Content
  $null = $range.Find.Execute($findText, $false, $false, $false, $false, $false, $true, 1, $false, $replaceText, 2)
}

function InsertAfterText($doc, $marker, $insertText) {
  $range = $doc.Content
  if ($range.Find.Execute($marker)) {
    $ins = $doc.Range($range.End, $range.End)
    $ins.InsertAfter("`r" + $insertText + "`r")
  }
  else {
    Write-Output ("MARKER NOT FOUND: " + $marker)
  }
}

$word = New-Object -ComObject Word.Application
$word.Visible = $false

try {
  $doc = $word.Documents.Open($eng)

  FindReplace $doc 'Generated March 16, 2026  19:23' 'Updated March 21, 2026'

  InsertAfterText $doc 'Keep risky fixes centralized and global rather than improvising project-specific patches.' 'The public converter must remain generic. Form names, control names, business procedures, schedules, log files, and other application-specific identifiers do not belong in the converter core. When a fix cannot be expressed as a reusable rule, it should be handled in the converted application or in a private profile outside the public release path.'
  InsertAfterText $doc 'A class rename alone is rarely enough. Mapping also depends on property filtering, event translation, runtime compatibility rewrites, and in many cases additional FMX infrastructure.' 'The current generic mapping set also includes TDBNavigator to TBindNavigator, TDBComboBox to TComboEdit, TDateTimePicker to TDateEdit, and TValueListEditor to TGrid. These mappings are backed by property, event, layout, and runtime compatibility rules rather than by class renaming alone.'
  InsertAfterText $doc 'TBindDBGridLink for converted DB grids.' 'Current generic behavior goes farther than the original baseline. Converted bound edits now use generated date/time parsing and commit helpers, DB combo boxes map to TComboEdit, and editable DB-grid forms are split into two safe strategies: a browse-grid plus existing standalone editors, or a selector grid plus generated editors when the source form has no separate editors.'
  InsertAfterText $doc 'Preserving the original VCL DBGrid.Columns collection is essential. Without it, FMX tends to generate default columns for every dataset field, which can expose irrelevant fields and render memo-backed values as generic blob placeholders.' 'This is paired with a generic selector-grid strategy. If the source form already has separate editors on the same datasource, the converted grid stays a browse and selection surface. If the source form relied on inline grid editing, the converter now generates a selector grid with separate editors rather than depending on fragile FMX inline database-grid editing.'
  InsertAfterText $doc 'Uses-clause reconstruction, helper injection, startup adaptation, schedule behavior fixes, grid and combo support, media cleanup, graphics scene safety, and many post-processing rules.' 'Current helper families include ApplyStyledBackgroundColor and ApplyContainerBackgroundColor for styled container colors, GeneratedTryParseBoundDate, GeneratedTryParseBoundTime, and GeneratedAssignBoundFieldValue for bound edit stability, toggle-state wrappers for FMX checkbox and radio semantics, startup OnEnter guards, deferred FormShow toggle execution, and generic FMX media-notify bridging.'
  InsertAfterText $doc '13. Validation, Maintenance, and Enhancement Guidance' "13.1 Generic Release Safeguard`rBefore a public release, sweep the live converter source for project-specific identifiers and remove temporary project files from the converter workspace. Compare the live source against known input-project units and form names, and treat any match in a converter source file as a release blocker unless it appears only in historical audit documentation."

  foreach ($toc in $doc.TablesOfContents) { $toc.Update() | Out-Null }
  foreach ($field in $doc.Fields) { $field.Update() | Out-Null }
  $doc.Save()
  $doc.Close()

  $doc2 = $word.Documents.Open($user)

  FindReplace $doc2 'Generated March 17, 2026  12:55' 'Updated March 21, 2026'
  InsertAfterText $doc2 'Use both guides together when a conversion is being actively refined and stabilized.' 'Use the Generic Rules Reference when you need a compact table of the active mappings, helper behaviors, and component-level conversion rules.'
  InsertAfterText $doc2 'A useful way to think about the converter is this: it is a serious productivity accelerator, not a promise that every converted application is instantly production-ready without verification. In practice, it can bring the vast majority of a migration under control and make the remaining issues understandable.' 'The public converter is maintained as a generic migration tool. If a problem only affects one application and cannot be expressed as a reusable converter rule, that fix should be handled in the generated application or in a private post-conversion step rather than added to the public converter core.'
  InsertAfterText $doc2 'This sequence matters. Trying to perfect colors or spacing before the application builds and runs cleanly is usually wasted effort. Stabilize structure first, runtime second, and presentation third.' 'When you improve the converter, prefer global rules over one-off patches. A healthy workflow is: expose a repeatable pattern in the converted app, update the converter generically, regenerate into a clean output folder, and verify the result again.'
  InsertAfterText $doc2 'Test secondary forms, help, menus, and common user actions.' 'Test long error or information dialogs and confirm they are readable. Test date and time entry with both valid and invalid values. Test data-aware grids to confirm they either browse through a read-only grid with separate editors or use a selector-grid pattern with separate editors.'
  InsertAfterText $doc2 'If a run goes badly, do not try to repair everything at once. The fastest route is usually to identify the highest-severity problem, improve the converter globally, regenerate clean output, and retest.' 'If you discover that a converter change only works for one project, treat that as a warning sign. Public converter changes should be reusable across Delphi projects; project-specific business logic should not be left in the converter core.'
  InsertAfterText $doc2 'The healthier workflow is: use the generated project to expose a pattern, fix the converter globally, regenerate, and verify that future projects will benefit too.' 'When using AI assistance or outside review, insist on generic fixes and periodically sweep the converter source for project-specific identifiers before treating a build as release-ready.'

  foreach ($toc in $doc2.TablesOfContents) { $toc.Update() | Out-Null }
  foreach ($field in $doc2.Fields) { $field.Update() | Out-Null }
  $doc2.Save()
  $doc2.Close()

  Write-Output 'DOCS_UPDATED'
}
finally {
  $word.Quit()
}

