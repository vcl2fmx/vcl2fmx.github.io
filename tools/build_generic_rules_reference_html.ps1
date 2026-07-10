param(
  [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')
. (Join-Path $PSScriptRoot 'load_reference_matrices.ps1')

if (-not $PSBoundParameters.ContainsKey('OutputPath')) {
  $OutputPath = $GenericRulesReferenceHtmlPath
}

function HtmlEncode {
  param([string]$Text)
  if ($null -eq $Text) { return '' }
  $encoded = [System.Net.WebUtility]::HtmlEncode($Text)
  return $encoded.Replace("`r`n", '<br>').Replace("`n", '<br>')
}

function Render-TableRows {
  param([object[][]]$Rows)
  $sb = New-Object System.Text.StringBuilder
  foreach ($row in $Rows) {
    [void]$sb.AppendLine('      <tr>')
    foreach ($cell in $row) {
      [void]$sb.AppendLine('        <td>' + (HtmlEncode ([string]$cell)) + '</td>')
    }
    [void]$sb.AppendLine('      </tr>')
  }
  return $sb.ToString()
}

function Get-ComponentRuleName {
  param([string]$MappingType)
  switch ($MappingType) {
    'direct' { return 'Direct component mapping' }
    'substitute' { return 'Substitute component mapping' }
    'unmapped' { return 'Unsupported / manual review' }
    default { return 'Component mapping rule' }
  }
}

function Get-ComponentOutput {
  param($Row)
  if ([string]::IsNullOrWhiteSpace($Row.fmx_class)) {
    return 'Manual review / unsupported'
  }
  return $Row.fmx_class
}

function Get-ComponentDescription {
  param($Row)
  if (-not [string]::IsNullOrWhiteSpace($Row.notes)) {
    return $Row.notes
  }
  if (-not [string]::IsNullOrWhiteSpace($Row.runtime_policy_notes)) {
    return $Row.runtime_policy_notes
  }
  switch ($Row.mapping_type) {
    'direct' { return 'Maps directly to the matching FMX component surface.' }
    'substitute' { return 'Uses the closest stock FMX substitute and applies later parser or integration rules where needed.' }
    'unmapped' { return 'No safe stock FMX equivalent is modeled in the current converter; treat as manual review.' }
    default { return 'Mapped according to the current converter rules.' }
  }
}

$referenceData = Get-ReferenceMatrixData -ProjectRoot $ProjectRoot
$classRows = @($referenceData.ClassRows)
$propertyRows = @($referenceData.PropertyRows)
$eventRows = @($referenceData.EventRows)

$classCounts = $classRows | Group-Object mapping_type -AsHashTable -AsString
$propertyCounts = $propertyRows | Group-Object classification -AsHashTable -AsString
$eventCounts = $eventRows | Group-Object classification -AsHashTable -AsString

$componentTableRows = @()
foreach ($row in ($classRows | Sort-Object vcl_class)) {
  $componentTableRows += ,@(
    (Get-ComponentRuleName $row.mapping_type),
    $row.vcl_class,
    (Get-ComponentOutput $row),
    (Get-ComponentDescription $row),
    'Converter.Mapper.Component.pas'
  )
}

$propertyEventRuleRows = @(
  @('Caption-to-Text translation','Caption-based control text','Text / TextSettings-based output','Converts VCL Caption usage to the appropriate FMX text property or text-setting path depending on the control type.','Converter.Parser.DFM.pas; Converter.Core.Integration.pas'),
  @('Checked-to-IsChecked translation','Checked','IsChecked','Normalizes VCL toggle state access to the FMX boolean property used by check boxes and radio buttons.','Converter.Mapper.Component.pas; Converter.Core.Integration.pas'),
  @('Picture-to-Bitmap translation','TPicture-based image content','Bitmap-based FMX image content','Bridges the VCL picture model to the bitmap-oriented FMX image control model.','Converter.Mapper.Component.pas; Converter.Core.Integration.pas'),
  @('Brush and Pen translation','Brush / Pen','Fill / Stroke','Maps VCL drawing properties to the FMX rendering property model.','Converter.Mapper.Component.pas; Converter.Core.Integration.pas'),
  @('Combo popup event translation','OnDropDown','OnPopup','Rewrites combo drop-down events to the FMX popup event used by combo boxes and combo-edit controls.','Converter.Mapper.Component.pas; Converter.Parser.DFM.pas'),
  @('Combo close event translation','OnCloseUp','OnClosePopup','Rewrites combo close-up events to the FMX popup-close event used by combo boxes and combo-edit controls.','Converter.Mapper.Component.pas; Converter.Parser.DFM.pas'),
  @('Date picker open event translation','OnDropDown','OnOpenPicker','Maps the VCL date-picker open event to the FMX picker-open event.','Converter.Mapper.Component.pas; Converter.Parser.DFM.pas'),
  @('Date picker close event translation','OnCloseUp','OnClosePicker','Maps the VCL date-picker close event to the FMX picker-close event.','Converter.Mapper.Component.pas; Converter.Parser.DFM.pas'),
  @('Key event signature review','OnKeyDown / OnKeyUp','FMX key events with different signatures','Marks keyboard events whose FMX handler signatures differ from VCL so the converter can report or adapt them honestly.','Converter.Mapper.Component.pas'),
  @('Form mouse-move signature review','Form OnMouseMove','FMX mouse events with Single coordinates','Flags signature differences where FMX expects floating-point coordinates instead of the VCL integer pattern.','Converter.Mapper.Component.pas'),
  @('Root-form double-click adaptation','Form OnDblClick','Generated OnMouseUp adapter','Keeps FMX forms from streaming an unsupported OnDblClick property by remapping root-form double-click behavior through a generated mouse-up adapter.','Converter.Parser.DFM.pas; Converter.Core.Integration.pas'),
  @('Masked-edit rule','EditMask','Manual review','Keeps TMaskEdit on the supported class matrix while leaving masking semantics explicit instead of pretending there is a full FMX equivalent.','Converter.Mapper.Component.pas'),
  @('Windows message to FMX event translation','WM_* handlers','OnEnter / OnExit / OnClick / OnResize / etc.','Translates common Windows message-handler patterns into the closest FMX event model and marks critical areas for review when needed.','Converter.Advanced.CriticalAreas.pas'),
  @('VCL color constant translation','clBtnFace, clWindow, clActiveCaption, and similar constants','TAlphaColor / FMX-safe color literals','Converts common VCL color constants into the FMX color system so colors render correctly outside WinAPI painting.','Converter.Advanced.WinAPI.pas; Converter.Core.Integration.pas'),
  @('TColor cast normalization','TColor(...)','TAlphaColor(...)','Normalizes explicit color casts so converted code compiles and uses the FMX color type system.','Converter.Advanced.WinAPI.pas'),
  @('MessageDlg button qualification','[mbOK], [mbYes, mbNo] and similar sets','[TMsgDlgBtn.mbOK], [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo]','Qualifies generated FMX message-dialog button sets so they use the FMX/System.UITypes enum surface instead of bare VCL-style identifiers.','Converter.Core.Integration.pas'),
  @('Folder picker dialog translation','TFileOpenDialog with fdoPickFolders','FMX SelectDirectory helper path','Converts folder-only browse flows to FMX directory selection and suppresses unsupported VCL dialog option constants from leaking into generated FMX Pascal.','Converter.Core.Integration.pas'),
  @('Toggle user-change semantics','VCL check box / radio button OnClick semantics','FMX OnChange plus generated silent setter','Preserves user-change behavior generically by separating programmatic state assignment from user-triggered event handling.','Converter.Core.Integration.pas'),
  @('Message dialog preservation','ShowMessage(...)','ShowMessage(...)','Preserves standard message dialogs rather than routing them through an extra helper layer.','Converter.Core.Integration.pas')
)

$layoutRows = @(
  @('Scoped StyledSettings emission','Styled text-capable controls with custom font/color/alignment','Scoped StyledSettings literal','Clears only the FMX style buckets actually overridden by converted font, color, and alignment settings instead of forcing StyledSettings to an empty set.','Converter.Parser.DFM.pas'),
  @('Label AutoSize preservation','AutoSize and non-AutoSize VCL labels','TLabel sizing that follows the original intent','Keeps safe AutoSize behavior where appropriate and avoids over-expanding labels that were fixed-width in VCL.','Converter.Parser.DFM.pas'),
  @('Fixed-width label width bump','Long single-line fixed-width labels','Wider TLabel output','Adds a mild width increase so slightly larger FMX text does not clip or crowd adjacent controls.','Converter.Parser.DFM.pas'),
  @('Wrapped label width normalization','Long wrapped labels and labels with manual line breaks','Wider wrapped TLabel output','Expands wrapped labels so multiline text fits more naturally in FMX.','Converter.Parser.DFM.pas'),
  @('Wrapped label height normalization','Wrapped labels that need extra vertical space','Taller TLabel output','Increases label height so wrapped text fully displays instead of truncating after the first line.','Converter.Parser.DFM.pas'),
  @('Right/centered label alignment preservation','Right-justified or centered labels','Fixed-width aligned FMX label output','Preserves alignment intent and keeps labels visually aligned with nearby controls rather than forcing unsafe autosizing.','Converter.Parser.DFM.pas'),
  @('Auto-sized label anchor reset','Auto-sized VCL labels carrying broad anchor sets','Default FMX anchors for auto-sized labels','Prevents FMX from stretching centered or auto-sized labels just because the source VCL label carried opposite-edge anchors.','Converter.Parser.DFM.pas'),
  @('DIP-aware font scaling','VCL pixel-sized text controls','Adjusted FMX font sizes and dimensions','Applies component-aware sizing adjustments so text controls look closer to their VCL proportions under FMX device-independent pixels.','Converter.Parser.DFM.pas'),
  @('Editable combo read-only safeguard','TDBComboBox converted to TComboEdit','Editable combo-edit output','Prevents VCL ReadOnly metadata from incorrectly locking editable converted combo-edit controls.','Converter.Parser.DFM.pas'),
  @('Runtime font-size styled-setting release','Control.Font.Size assignments on FMX styled text controls','Generated font-size helper that clears TStyledSetting.Size first','Ensures runtime font-size changes are honored on FMX text controls whose styles would otherwise keep Size locked.','Converter.Core.Integration.pas'),
  @('VCL-style text layout math preservation','Label stacking math that depends on Height after runtime font changes','Generated VCL text-height helper','Preserves vertical spacing in converted dashboards and clock-style layouts by using source label metrics instead of trusting raw FMX auto-size heights.','Converter.Core.Integration.pas'),
  @('Style-resource background application','VCL styled containers with explicit background colors','Styled FMX container tinting','Applies explicit container colors through the FMX style tree so panels, group boxes, toolbars, and status bars keep their visual intent.','Converter.Core.Integration.pas'),
  @('Recursive container color propagation','Nested VCL containers with explicit color usage','ApplyContainerBackgroundColor helper','Walks the FMX control tree and applies compatible background color handling to styled container hierarchies.','Converter.Core.Integration.pas')
)

$runtimeRows = @(
  @('Bound date parser','Date text entered into converted bound edits','GeneratedTryParseBoundDate','Accepts flexible date text, validates it, and converts it safely before the dataset field is updated.','Converter.Core.Integration.pas'),
  @('Bound time parser','Time text entered into converted bound edits','GeneratedTryParseBoundTime','Accepts flexible 12-hour and 24-hour time input and normalizes it for FMX-bound field updates.','Converter.Core.Integration.pas'),
  @('Bound field assignment helper','Field updates from converted edits','GeneratedAssignBoundFieldValue','Centralizes type-aware field assignment so invalid values are rejected cleanly and valid values normalize through the field display logic.','Converter.Core.Integration.pas'),
  @('DisplayText refresh preservation','TDBEdit.Field.DisplayText refresh logic','GeneratedGetManualFieldDisplayText','Preserves VCL data-aware display formatting such as OnGetText-driven month/day presentation when converted edits refresh from their bound field display text.','Converter.Core.Integration.pas'),
  @('Bound edit commit wiring','TDBEdit-style behavior','OnChangeTracking / OnExit / OnKeyDown wiring','Wakes dataset edit mode while typing, commits on Enter or exit, and re-syncs from the field display value afterward.','Converter.Core.Integration.pas'),
  @('TMemo clear normalization','TMemo.Clear','Lines.Clear','Normalizes memo-clearing calls to the FMX multiline text model.','Converter.Core.Integration.pas'),
  @('Numeric Position-to-Value normalization','Track and progress Position semantics','FMX Value semantics','Normalizes common slider-style control reads and writes to FMX Value properties.','Converter.Core.Integration.pas'),
  @('Combo startup popup suppression','Generated combo setup on form creation','Field sync without popup side effects','Initializes converted combo values from the bound field without calling actual popup-open logic during form startup.','Converter.Core.Integration.pas'),
  @('Combo popup-close preservation','Existing OnClosePopup handlers on converted combo controls','Generated close-popup wrapper plus restore-on-cleanup','Chains original close-popup logic with generated field-sync behavior and restores the original handler for externally owned/shared combo controls during teardown.','Converter.Core.Integration.pas'),
  @('External datasource handler restoration','Wrapped external TDataSource.OnDataChange handlers','Restore original OnDataChange on cleanup','Prevents generated binding cleanup from leaving a shared datasource with its handler nilled out after the form closes.','Converter.Core.Integration.pas'),
  @('External navigator handler restoration','Wrapped external TBindNavigator.BeforeAction handlers','Restore original BeforeAction on cleanup','Prevents shared navigators from being left pointed at generated wrapper methods on a destroyed form.','Converter.Core.Integration.pas'),
  @('Startup OnEnter guard','Side-effecting OnEnter handlers that fire during initial FMX display','Generated startup-guard enter wrappers','Prevents startup focus churn from triggering VCL OnEnter logic too early when a form first appears in FMX.','Converter.Core.Integration.pas'),
  @('Deferred FormShow toggle click','Programmatic toggle state changes followed by click handler calls in FormShow','ForceQueue-deferred simulated click','Lets the FMX form finish showing before the original handler runs, which better matches VCL startup timing.','Converter.Core.Integration.pas'),
  @('Media duration to milliseconds','MediaPlayer.Length-style millisecond logic','Round((Duration / MediaTimeScale) * 1000)','Converts FMX TMediaTime values into the millisecond units expected by converted VCL code.','Converter.Core.Integration.pas'),
  @('Media duration to seconds','MediaPlayer.Length div 1000-style logic','Round(Duration / MediaTimeScale)','Converts FMX TMediaTime values into seconds for countdown and remaining-time calculations.','Converter.Core.Integration.pas'),
  @('FMX media notify bridge','TMediaPlayer.OnNotify / Notify usage','Generated media-notify timer bridge','Emulates the VCL-style media notify pattern on FMX players by watching playback state and firing the original callback path generically.','Converter.Core.Integration.pas'),
  @('Ellipse drawing helper','VCL-style ellipse fill/stroke drawing patterns','FillAndStrokeEllipse','Injects a reusable FMX helper for shape-drawing scenarios that do not map cleanly one-to-one from the VCL canvas model.','Converter.Core.Integration.pas'),
  @('Client geometry normalization','CenterX / CenterY and client-size assumptions','ClientWidth / ClientHeight-aware output','Normalizes geometry calculations that depend on VCL client sizing so they make sense under FMX layout rules.','Converter.Core.Integration.pas'),
  @('Hide-to-tray fallback simplification','Hide To Tray button or handler','WindowState := wsMinimized','Converts hide-to-tray niceties to a simpler FMX-safe minimize behavior rather than trying to emulate a platform tray implementation automatically.','Converter.Core.Integration.pas'),
  @('Form centering float normalization','Mixed Integer/Extended center-position math','Rounded integer-safe assignment','Prevents generated form-centering code from assigning Extended expressions directly to integer Top/Left properties.','Converter.Core.Integration.pas'),
  @('TMemo string collection preservation','Lines.Strings, Items.Strings, SQL.Strings, Params.Strings','Structured collection output','Preserves string-list collection properties without flattening them into invalid FMX text.','Converter.Parser.DFM.pas'),
  @('StringGrid event-before-child emission','TStringGrid event properties and generated column children','Event properties emitted before child objects','Keeps generated FMX forms loadable in Delphi by preserving reader-sensitive ordering.','Converter.Parser.DFM.pas'),
  @('FMX UTF-8 BOM output','Generated .fmx text with international characters','UTF-8 with BOM','Ensures accented text and international captions display correctly when opened in Delphi.','Converter.Core.FileManager.pas'),
  @('DPR auto-create preservation','Application.CreateForm list in the source DPR','Preserved Application.CreateForm output','Keeps the source form auto-create list intact and suppresses the immediate extra Show call that caused FMX startup instability.','Converter.Project.Generator.pas'),
  @('ShellExecute preservation','Windows ShellExecute help/document/URL launch calls','Live ShellExecute output in Windows-targeted FMX projects','Keeps valid Windows shell-launch behavior active instead of commenting it out, restoring help/document buttons and similar utilities.','Converter.Advanced.WinAPI.pas'),
  @('Serial and named-pipe handle preservation','Comm-resource CreateFile / WriteFile patterns','Preserved Windows handle open/write calls','Keeps valid Windows serial-port and named-pipe communication paths live instead of downgrading them as ordinary file I/O.','Converter.Advanced.WinAPI.pas'),
  @('Process-control preservation','GetExitCodeProcess / TerminateProcess around preserved CreateProcess flows','Live Windows process-control output','Keeps partial process-runner code from breaking by preserving the surrounding Windows process-status and termination calls when the process path is already being preserved.','Converter.Advanced.WinAPI.pas')
)

$analysisRows = @(
  @('Explicit matrix export','Current mapper state','JSON inventory and matrix artifacts','Exports RTTI inventories plus explicit class, property, and event matrices so coverage can be audited from the compiled mapper.','Converter.Mapper.Component.pas'),
  @('Third-party component catalog','Known VCL components and compatibility metadata','Catalog-backed FMX suggestions','Provides a compatibility catalog used during analysis and documentation of what maps directly, what needs bindings, and what needs redesign.','Converter.Advanced.ThirdParty.pas'),
  @('Manual-review comment emission','Unsupported or risky VCL patterns','FMX manual review comments','Leaves review markers only where the converter still needs the user to make a conscious follow-up decision.','Converter.Advanced.CriticalAreas.pas; Converter.Parser.Pascal.pas; Converter.Core.Integration.pas'),
  @('Critical-area reporting','Message maps, WinAPI-heavy code, unsupported patterns','Conversion report output','Collects risky patterns during conversion so they can be surfaced for later inspection.','Converter.Advanced.CriticalAreas.pas; Converter.Core.Engine.pas'),
  @('Live mapping reference tabs','Current mapper knowledge','Component / Property / Event map pages','Uses the same mapper and discovery paths that drive conversion so the on-screen reference tabs reflect the compiled v5.0 knowledge base.','MainForm.pas'),
  @('Pascal include analysis','{$I} and {$INCLUDE} directives','Analysis-first include handling with safe copy','Analyzes include contents for VCL, Winapi, and message usage, copies source-tree includes to output, warns on missing/outside-tree files, and guards recursive/nested include chains.','Converter.Core.Engine.pas'),
  @('Windows messaging contract policy','WM/CM/CN/common-control messages, WndProc, message declarations, message APIs','Category-based conversion or manual-review reporting','Converts only reliable cases, preserves mixed system-command behavior as manual review, ignores comments/strings/false positives, and emits source-line report details for unsupported messaging.','Converter.Advanced.WinAPI.pas; Converter.Parser.Pascal.pas; Converter.Rewrite.AutoFixes.pas'),
  @('Protected conditional uses cleanup','VCL/Winapi units inside protected or conditional uses blocks','Contract-tested uses normalization','Removes stale VCL units such as Vcl.Themes when active generated output no longer needs them, while preserving Windows units only when active code still requires them.','Converter.Rewrite.UsesClause.pas; Converter.Core.Integration.pas'),
  @('Inventory-based runtime companion reporting','Real runtime-support files in the source root','Actionable staged/found report entries','Copies runtime companions from the source root only, avoids ambiguous build-output duplicates, filters out build folders, and reports only meaningful staged or still-manual items.','Converter.Project.Generator.pas'),
  @('Executable conversion contracts','Small Delphi fixtures plus .expected.json files','Contract runner assertions','Runs 194 v5.0 expectations against generated output and report text so structural rules are tested before release.','contracts; tools/run_conversion_contracts.ps1'),
  @('Report wording clarity','Distinct-file issue count and staged companion wording','Clearer text and HTML report labels','Clarifies that the report count is for distinct files needing attention and uses explicit staged-runtime wording in both report channels.','Converter.Core.Engine.pas; Converter.Project.Generator.pas'),
  @('Generic release hygiene','Project-specific identifiers in converter source','Audit and sweep checks','Supports the generic/public release process by allowing the converter source to be scanned for forbidden project-specific markers.','GENERIC_RULE_AUDIT_2026-03-20.txt; generic sweep process')
)

$updatedText = Get-Date -Format 'MMMM dd, yyyy HH:mm'
$classDirect = if ($classCounts.ContainsKey('direct')) { $classCounts['direct'].Count } else { 0 }
$classSubstitute = if ($classCounts.ContainsKey('substitute')) { $classCounts['substitute'].Count } else { 0 }
$classUnmapped = if ($classCounts.ContainsKey('unmapped')) { $classCounts['unmapped'].Count } else { 0 }
$propDirect = if ($propertyCounts.ContainsKey('direct')) { $propertyCounts['direct'].Count } else { 0 }
$propRename = if ($propertyCounts.ContainsKey('rename')) { $propertyCounts['rename'].Count } else { 0 }
$propTransform = if ($propertyCounts.ContainsKey('transform')) { $propertyCounts['transform'].Count } else { 0 }
$propOmit = if ($propertyCounts.ContainsKey('omit')) { $propertyCounts['omit'].Count } else { 0 }
$propManual = if ($propertyCounts.ContainsKey('manual_review')) { $propertyCounts['manual_review'].Count } else { 0 }
$eventDirect = if ($eventCounts.ContainsKey('direct')) { $eventCounts['direct'].Count } else { 0 }
$eventRename = if ($eventCounts.ContainsKey('rename')) { $eventCounts['rename'].Count } else { 0 }
$eventIncompatible = if ($eventCounts.ContainsKey('incompatible_signature')) { $eventCounts['incompatible_signature'].Count } else { 0 }
$eventManual = if ($eventCounts.ContainsKey('manual_review')) { $eventCounts['manual_review'].Count } else { 0 }

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>VCL2FMXConverter Generic Rules Reference</title>
  <style>
    body {
      font-family: Calibri, Arial, sans-serif;
      font-size: 11pt;
      line-height: 1.35;
      color: #222;
      margin: 24px;
    }
    h1, h2 {
      color: #7a0c0c;
      margin-bottom: 6px;
    }
    p {
      margin-top: 0;
    }
    table {
      border-collapse: collapse;
      width: 100%;
      margin-bottom: 18px;
    }
    th, td {
      border: 1px solid #b7b7b7;
      padding: 6px 8px;
      vertical-align: top;
      text-align: left;
    }
    th {
      background: #efe2c2;
      color: #4b2a1a;
    }
    .note {
      background: #f9f4e8;
      border: 1px solid #d8c49a;
      padding: 8px 10px;
      margin-bottom: 18px;
    }
    .small {
      font-size: 10pt;
      color: #555;
    }
  </style>
</head>
<body>
  <h1>VCL2FMXConverter Generic Rules Reference</h1>

  <div class="note">
    <strong>Scope:</strong> This document lists the active generic conversion rules in VCL2FMXConverter v5.0. It covers component mappings, data-aware rules, property and event rewrites, layout and style handling, runtime helper behavior, media conversion logic, project-generation rules, include analysis, Windows messaging policy, and the executable contract-test system. It does <strong>not</strong> include project-specific rules. Current v5.0 note: the live Component Map, Property Map, and Event Map screens are backed by the same compiled mapper knowledge used during conversion, and the mapper exports explicit RTTI inventories and class/property/event matrices for audit and maintenance.
  </div>

  <p class='small'><strong>Version:</strong> 5.0 Vanguard.</p>
  <p class='small'><strong>Revision date:</strong> $(Get-Date -Format 'MMMM dd, yyyy') from the current v5.0 codebase.</p>
  <p class='small'><strong>Reference data source:</strong> $($referenceData.SourceMode).</p>
  <p class='small'><strong>Current matrix snapshot:</strong> classes: $($classRows.Count) total ($classDirect direct, $classSubstitute substitute, $classUnmapped manual review); properties: $($propertyRows.Count) total ($propDirect direct, $propRename renamed, $propTransform transformed, $propOmit omitted, $propManual manual review); events: $($eventRows.Count) total ($eventDirect direct, $eventRename renamed, $eventIncompatible incompatible signature, $eventManual manual review).</p>

  <h2>1. Component Mapping Rules</h2>
  <table>
    <thead>
      <tr>
        <th>Rule Name</th>
        <th>VCL Source</th>
        <th>FMX Output</th>
        <th>What the New Component / Rule Does</th>
        <th>Implemented In</th>
      </tr>
    </thead>
    <tbody>
$(([string](Render-TableRows $componentTableRows)).TrimEnd())
    </tbody>
  </table>

  <h2>2. Data-Aware and Binding Rules</h2>
  <table>
    <thead>
      <tr>
        <th>Rule Name</th>
        <th>VCL Source</th>
        <th>FMX Output</th>
        <th>What the New Component / Rule Does</th>
        <th>Implemented In</th>
      </tr>
    </thead>
    <tbody>
$(([string](Render-TableRows @(
  @('Field binding analysis','TDBEdit / field-style DB-aware editors','TEdit + generated bind/sync code','Detects field-bound editors and generates the helper methods and events needed to keep FMX edits synchronized with dataset values.','Converter.Advanced.DataAware.pas; Converter.Core.Integration.pas'),
  @('Grid binding analysis','TDBGrid','TStringGrid + binding/selector strategy','Captures grid column metadata and routes each form to either a browse-grid path or a selector-grid-with-editors path based on the form structure.','Converter.Advanced.DataAware.pas; Converter.Core.Integration.pas'),
  @('Navigator binding analysis','TDBNavigator','TBindNavigator + generated bind source','Detects navigator usage and generates the FMX navigator/bind-source setup needed to drive the dataset.','Converter.Advanced.DataAware.pas'),
  @('Lookup combo analysis','TDBLookupComboBox','Lookup-style LiveBindings setup','Marks lookup combos for fill-control binding behavior so list values and selected keys can be bridged in FMX.','Converter.Advanced.DataAware.pas'),
  @('Display text binding','TDBText','TLabel + text binding','Routes read-only DB text fields to an FMX label with text/property binding semantics.','Converter.Advanced.DataAware.pas; Converter.Advanced.ThirdParty.pas'),
  @('Editable combo text binding','TDBComboBox','TComboEdit + combo text sync','Uses an editable FMX combo-edit for data-aware combo text and generates selection, popup, and field-sync logic around it.','Converter.Advanced.DataAware.pas; Converter.Core.Integration.pas'),
  @('Blob image binding','TDBImage','TImage + blob binding','Flags image fields for blob/property binding so visual image content can be pushed into FMX bitmap-based controls.','Converter.Advanced.DataAware.pas'),
  @('Memo text binding','TDBMemo','TMemo + text binding','Routes memo fields to multiline FMX text components with property binding behavior.','Converter.Advanced.DataAware.pas'),
  @('Boolean field binding','TDBCheckBox','TCheckBox + IsChecked binding','Maps boolean database fields to FMX check boxes using IsChecked rather than Checked.','Converter.Advanced.DataAware.pas'),
  @('Enum / radio-group binding','TDBRadioGroup','TRadioGroup + enum binding','Maps enumerated field groups to FMX radio-group/property binding behavior when the current compatibility path is appropriate.','Converter.Advanced.DataAware.pas; Converter.Advanced.ThirdParty.pas'),
  @('Bind-source code generation','DB-aware datasets and controls','LiveBindings objects and generated helper code','Creates the FMX-side bind-source objects and related link components where direct FMX data-aware controls do not exist.','Converter.Advanced.DataAware.pas'),
  @('Read-only browse grid rule','Editable source DB grid with separate editors','Browse-only TStringGrid','Keeps the grid for browsing/selection and pushes editing responsibility into the already-existing standalone editors on the form.','Converter.Core.Integration.pas'),
  @('Selector-grid rule','Editable source DB grid without separate editors','TStringGrid + generated editor panel','Builds a selector grid plus generated editors so inline VCL DB-grid editing is replaced with a safer FMX editing model.','Converter.Core.Integration.pas')
))).TrimEnd())
    </tbody>
  </table>

  <h2>3. Property, Event, and Semantic Translation Rules</h2>
  <p class="small">The current explicit property matrix classifies $($propertyRows.Count) rows ($propDirect direct, $propRename renamed, $propTransform transformed, $propOmit omitted, $propManual manual review). The current explicit event matrix classifies $($eventRows.Count) rows ($eventDirect direct, $eventRename renamed, $eventIncompatible incompatible-signature, $eventManual manual review).</p>
  <table>
    <thead>
      <tr>
        <th>Rule Name</th>
        <th>VCL Source</th>
        <th>FMX Output</th>
        <th>What the New Component / Rule Does</th>
        <th>Implemented In</th>
      </tr>
    </thead>
    <tbody>
$(([string](Render-TableRows $propertyEventRuleRows)).TrimEnd())
    </tbody>
  </table>

  <h2>4. Layout, Text, and Style Rules</h2>
  <table>
    <thead>
      <tr>
        <th>Rule Name</th>
        <th>VCL Source</th>
        <th>FMX Output</th>
        <th>What the New Component / Rule Does</th>
        <th>Implemented In</th>
      </tr>
    </thead>
    <tbody>
$(([string](Render-TableRows $layoutRows)).TrimEnd())
    </tbody>
  </table>

  <h2>5. Runtime Helper and Code-Rewrite Rules</h2>
  <table>
    <thead>
      <tr>
        <th>Rule Name</th>
        <th>VCL Source</th>
        <th>FMX Output</th>
        <th>What the New Component / Rule Does</th>
        <th>Implemented In</th>
      </tr>
    </thead>
    <tbody>
$(([string](Render-TableRows $runtimeRows)).TrimEnd())
    </tbody>
  </table>

  <h2>6. Analysis, Catalog, and Review Rules</h2>
  <table>
    <thead>
      <tr>
        <th>Rule Name</th>
        <th>VCL Source</th>
        <th>FMX Output</th>
        <th>What the New Component / Rule Does</th>
        <th>Implemented In</th>
      </tr>
    </thead>
    <tbody>
$(([string](Render-TableRows $analysisRows)).TrimEnd())
    </tbody>
  </table>

  <p class="small">End of reference.</p>
</body>
</html>
"@

[System.IO.File]::WriteAllText($OutputPath, $html, [System.Text.UTF8Encoding]::new($false))
Write-Output 'HTML_REFERENCE_REBUILT'
