param(
  [Parameter(Mandatory = $true)]
  [string]$OutputPath,

  [string]$CopyPath = ''
)

$ErrorActionPreference = 'Stop'

function Add-Paragraph {
  param(
    [Parameter(Mandatory = $true)]$Selection,
    [Parameter(Mandatory = $true)][string]$Text,
    [string]$Style = 'Normal',
    [switch]$Bold,
    [switch]$Italic,
    [int]$Alignment = 0
  )

  $Selection.Style = $Style
  $Selection.ParagraphFormat.Alignment = $Alignment
  $Selection.Font.Bold = [int]$Bold.IsPresent
  $Selection.Font.Italic = [int]$Italic.IsPresent
  $Selection.TypeText($Text)
  $Selection.TypeParagraph()
  $Selection.Font.Bold = 0
  $Selection.Font.Italic = 0
  $Selection.ParagraphFormat.Alignment = 0
}

function Add-BulletList {
  param(
    [Parameter(Mandatory = $true)]$Selection,
    [Parameter(Mandatory = $true)][string[]]$Items
  )

  foreach ($item in $Items) {
    $Selection.Style = 'Normal'
    $Selection.Range.ListFormat.ApplyBulletDefault()
    $Selection.TypeText($item)
    $Selection.TypeParagraph()
  }
  $Selection.Range.ListFormat.RemoveNumbers()
  $Selection.TypeParagraph()
}

function Add-NumberList {
  param(
    [Parameter(Mandatory = $true)]$Selection,
    [Parameter(Mandatory = $true)][string[]]$Items
  )

  foreach ($item in $Items) {
    $Selection.Style = 'Normal'
    $Selection.Range.ListFormat.ApplyNumberDefault()
    $Selection.TypeText($item)
    $Selection.TypeParagraph()
  }
  $Selection.Range.ListFormat.RemoveNumbers()
  $Selection.TypeParagraph()
}

function Fit-TableToPage {
  param(
    [Parameter(Mandatory = $true)]$Table
  )

  try { $Table.Rows.Alignment = 0 } catch {}
  try { $Table.Rows.LeftIndent = 0 } catch {}
  try { $Table.AllowAutoFit = $true } catch {}
  try { $Table.PreferredWidthType = 2 } catch {}
  try { $Table.PreferredWidth = 100 } catch {}
  try { $Table.AutoFitBehavior(2) | Out-Null } catch {}
}

function Add-Table {
  param(
    [Parameter(Mandatory = $true)]$Document,
    [Parameter(Mandatory = $true)]$Selection,
    [Parameter(Mandatory = $true)][string[]]$Headers,
    [Parameter(Mandatory = $true)][object[][]]$Rows
  )

  $table = $Document.Tables.Add($Selection.Range, $Rows.Count + 1, $Headers.Count)
  try { $table.Style = 'Table Grid' } catch {}

  for ($c = 0; $c -lt $Headers.Count; $c++) {
    $cell = $table.Cell(1, $c + 1)
    $cell.Range.Text = [string]$Headers[$c]
    $cell.Range.Bold = $false
    $cell.Shading.BackgroundPatternColor = 15921906
  }

  for ($r = 0; $r -lt $Rows.Count; $r++) {
    for ($c = 0; $c -lt $Headers.Count; $c++) {
      $table.Cell($r + 2, $c + 1).Range.Text = [string]$Rows[$r][$c]
    }
  }

  $table.Rows.Alignment = 0
  $table.Range.ParagraphFormat.SpaceAfter = 4
  Fit-TableToPage -Table $table
  $Selection.SetRange($table.Range.End, $table.Range.End)
  $Selection.TypeParagraph()
  $Selection.TypeParagraph()
}

function Add-ProcessDiagram {
  param(
    [Parameter(Mandatory = $true)]$Document,
    [Parameter(Mandatory = $true)]$Selection,
    [Parameter(Mandatory = $true)][string]$Title,
    [Parameter(Mandatory = $true)][hashtable[]]$Stages,
    [string]$Note = ''
  )

  Add-Paragraph -Selection $Selection -Text $Title -Style 'Heading 2'
  if ($Note -ne '') {
    Add-Paragraph -Selection $Selection -Text $Note -Style 'Normal'
  }

  $cols = ($Stages.Count * 2) - 1
  $table = $Document.Tables.Add($Selection.Range, 1, $cols)
  try { $table.Style = 'Table Grid' } catch {}
  $table.Rows.HeightRule = 1
  $table.Rows.Height = 72

  $colIndex = 1
  foreach ($stage in $Stages) {
    $cell = $table.Cell(1, $colIndex)
    $cell.Shading.BackgroundPatternColor = 15921906
    $cell.Range.ParagraphFormat.Alignment = 1
    $cell.Range.Bold = $false
    $cell.Range.Text = $stage.Title + [Environment]::NewLine + $stage.Detail
    if ($colIndex -lt $cols) {
      $arrowCell = $table.Cell(1, $colIndex + 1)
      $arrowCell.Range.Text = 'Next'
      $arrowCell.Range.ParagraphFormat.Alignment = 1
      $arrowCell.Range.Font.Size = 10
      $arrowCell.Range.Bold = $true
      $arrowCell.Shading.BackgroundPatternColor = 16119285
    }
    $colIndex += 2
  }

  Fit-TableToPage -Table $table
  $Selection.SetRange($table.Range.End, $table.Range.End)
  $Selection.TypeParagraph()
  $Selection.TypeParagraph()
}

function Add-PageBreak {
  param([Parameter(Mandatory = $true)]$Selection)
  $Selection.InsertBreak(7)
}

function Apply-DocumentStyles {
  param([Parameter(Mandatory = $true)]$Document)

  $normal = $Document.Styles.Item('Normal')
  $normal.Font.Name = 'Segoe UI'
  $normal.Font.Size = 10.5
  $normal.ParagraphFormat.SpaceAfter = 8
  $normal.ParagraphFormat.SpaceBefore = 0
  $normal.ParagraphFormat.LineSpacingRule = 0
  $normal.ParagraphFormat.LineSpacing = 15

  $heading1 = $Document.Styles.Item('Heading 1')
  $heading1.Font.Name = 'Cambria'
  $heading1.Font.Size = 18
  $heading1.Font.Bold = $true
  $heading1.Font.Color = 8224125
  $heading1.ParagraphFormat.SpaceBefore = 18
  $heading1.ParagraphFormat.SpaceAfter = 12
  $heading1.ParagraphFormat.KeepWithNext = $true

  $heading2 = $Document.Styles.Item('Heading 2')
  $heading2.Font.Name = 'Cambria'
  $heading2.Font.Size = 13.5
  $heading2.Font.Bold = $true
  $heading2.ParagraphFormat.SpaceBefore = 14
  $heading2.ParagraphFormat.SpaceAfter = 8
  $heading2.ParagraphFormat.KeepWithNext = $true

  $heading3 = $Document.Styles.Item('Heading 3')
  $heading3.Font.Name = 'Segoe UI'
  $heading3.Font.Size = 11
  $heading3.Font.Bold = $true
  $heading3.ParagraphFormat.SpaceBefore = 10
  $heading3.ParagraphFormat.SpaceAfter = 6
  $heading3.ParagraphFormat.KeepWithNext = $true
}

function Add-TopSection {
  param(
    [Parameter(Mandatory = $true)]$Selection,
    [Parameter(Mandatory = $true)][string]$Title,
    [switch]$StartOnNewPage
  )

  if ($StartOnNewPage) {
    Add-PageBreak -Selection $Selection
  }
  Add-Paragraph -Selection $Selection -Text $Title -Style 'Heading 1'
}

$word = $null
$document = $null

try {
  $word = New-Object -ComObject Word.Application
  $word.Visible = $false
  $document = $word.Documents.Add()
  Apply-DocumentStyles -Document $document
  $selection = $word.Selection

  $section = $document.Sections.Item(1)
  $section.PageSetup.TopMargin = 54
  $section.PageSetup.BottomMargin = 54
  $section.PageSetup.LeftMargin = 54
  $section.PageSetup.RightMargin = 54

  Add-Paragraph -Selection $selection -Text 'VCL2FMXConverter' -Style 'Title' -Alignment 1
  Add-Paragraph -Selection $selection -Text 'Engineering Guide' -Style 'Title' -Alignment 1
  Add-Paragraph -Selection $selection -Text 'Detailed Engineering and Maintenance Edition' -Style 'Normal' -Italic -Alignment 1
  Add-Paragraph -Selection $selection -Text 'Version 5.0 Vanguard' -Style 'Normal' -Bold -Alignment 1
  Add-Paragraph -Selection $selection -Text ('Revision date: ' + (Get-Date -Format 'MMMM dd, yyyy')) -Style 'Normal' -Alignment 1
  Add-Paragraph -Selection $selection -Text 'Workspace: C:/New Delphi Projects/VCL2FMXConverterV5' -Style 'Normal' -Alignment 1
  $selection.TypeParagraph()
  Add-Paragraph -Selection $selection -Text 'This manual is intended for developers, maintainers, and technical reviewers who need to understand how the converter works, how its units collaborate, and how future improvements should be made safely and globally.' -Style 'Normal' -Alignment 1
  Add-PageBreak -Selection $selection

  Add-Paragraph -Selection $selection -Text 'Table of Contents' -Style 'Heading 1'
  Add-Paragraph -Selection $selection -Text 'If Word does not populate the table immediately, right-click it and choose Update Field.' -Style 'Normal'
  $document.TablesOfContents.Add($selection.Range, $true, 1, 3) | Out-Null
  $selection.TypeParagraph()

  Add-TopSection -Selection $selection -Title '1. Introduction and Engineering Intent' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'The VCL2FMXConverter is a migration tool for Delphi applications. Its purpose is to read an existing VCL-oriented codebase and emit a first-pass FireMonkey version that is as structurally valid, compilable, and reviewable as possible.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'The converter is not intended to behave like a blind search-and-replace utility. It operates more like a staged migration compiler. It discovers files, parses forms and source units, builds intermediate models, applies mapping and rewrite logic, injects compatibility behavior where needed, and emits a new FMX-oriented project structure.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'The engineering intent behind the current implementation is strongly global. Improvements should be expressed as reusable converter rules whenever possible so that each fix benefits future projects as well as the one currently under review.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text '1.1 Primary Engineering Goals' -Style 'Heading 2'
  Add-NumberList -Selection $selection -Items @(
    'Preserve user intent so the converted application still represents the same business behavior and recognizable user experience as the source project.',
    'Prefer valid FMX output over risky mimicry so unsupported VCL constructs do not become invalid FMX artifacts.',
    'Improve globally so recurring fixes are captured in the converter rather than being repeated manually in each converted project.'
  )
  Add-Paragraph -Selection $selection -Text '1.2 Practical Meaning of a Successful Conversion' -Style 'Heading 2'
  Add-Table -Document $document -Selection $selection -Headers @('Layer','Description','Typical Evidence') -Rows @(
    @('Structural','Generated forms load and units compile.','Delphi opens the project and the code builds.'),
    @('Runtime','Startup, timers, queries, dialogs, and events behave acceptably.','The converted application launches and performs real workflows.'),
    @('Visual','Layout, captions, colors, and images remain usable and recognizable.','Side-by-side comparison with the VCL original is reasonable.'),
    @('Maintainability','Generated code and converter logic remain understandable enough to extend.','A future maintainer can diagnose and improve the system.')
  )

  Add-TopSection -Selection $selection -Title '2. Product Scope and Design Principles' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text '2.1 Scope' -Style 'Heading 2'
  Add-BulletList -Selection $selection -Items @(
    'Delphi Pascal source files (.pas)',
    'VCL form definitions (.dfm), including binary forms normalized to text',
    'Delphi startup and project metadata (.dpr, .dproj, and related artifacts)',
    'Reports and operational status output'
  )
  Add-Paragraph -Selection $selection -Text 'The converter also includes special handling for color translation, images, data-aware controls, grid behavior, WinAPI compatibility, media controls, and unsupported third-party patterns.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text '2.2 Design Principles' -Style 'Heading 2'
  Add-BulletList -Selection $selection -Items @(
    'Use Embarcadero FMX behavior as the reference model wherever the answer is documented or visible in Delphi source code.',
    'Preserve semantic meaning before preserving literal syntax.',
    'Prefer readable output over opaque generated code.',
    'Keep risky fixes centralized and global rather than improvising project-specific patches.',
    'Treat data-aware conversion, custom drawing, and WinAPI migration as high-risk engineering areas.'
  )

  Add-TopSection -Selection $selection -Title '3. System Architecture Overview' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'The converter is organized as a layered system. Each layer has a specific responsibility, and most files belong naturally to one of these roles.' -Style 'Normal'
  Add-ProcessDiagram -Document $document -Selection $selection -Title '3.1 Layer Diagram' -Note 'The diagram below uses real table blocks as visual process stages rather than ASCII line drawings.' -Stages @(
    @{ Title = 'User Interface'; Detail = 'MainForm' },
    @{ Title = 'Engine and Orchestration'; Detail = 'Core.Engine' + [Environment]::NewLine + 'Core.FileManager' + [Environment]::NewLine + 'Core.Integration' },
    @{ Title = 'Parsers and Mappers'; Detail = 'Parser.DFM' + [Environment]::NewLine + 'Parser.Pascal' + [Environment]::NewLine + 'Mapper.Component' },
    @{ Title = 'Output Generation'; Detail = 'FMX source' + [Environment]::NewLine + 'Project files' + [Environment]::NewLine + 'Reports' }
  )
  Add-Paragraph -Selection $selection -Text 'The Advanced modules sit beside the orchestration layer and intervene when specialized rewriting is needed. This includes WinAPI compatibility, data-aware conversion, custom drawing, and unsupported component scenarios.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text '3.2 Responsibility Matrix' -Style 'Heading 2'
  Add-Table -Document $document -Selection $selection -Headers @('Unit Group','Primary Responsibility','Main Files') -Rows @(
    @('User interface','Collect options, launch conversion, and report progress without containing core conversion logic.','MainForm.pas, MainForm.fmx'),
    @('Engine core','Coordinate file scanning, conversion sequencing, issue aggregation, and lifecycle control.','Converter.Core.Engine.pas, Converter.Core.FileManager.pas, Converter.Core.Types.pas'),
    @('Integration','Apply global Pascal rewrites, rebuild uses clauses, inject LiveBindings, and normalize FMX behavior.','Converter.Core.Integration.pas'),
    @('DFM processing','Parse VCL forms, preserve collections and field objects, and regenerate FMX text.','Converter.Parser.DFM.pas'),
    @('Pascal processing','Parse unit structure and support source-safe rewrites.','Converter.Parser.Pascal.pas'),
    @('Mapping layer','Decide FMX class and property equivalents, including fallbacks and confidence rules.','Converter.Mapper.Component.pas'),
    @('Specialized conversion','Rewrite high-risk patterns such as WinAPI, DB controls, custom drawing, and unsupported components.','Converter.Advanced.DataAware.pas, Converter.Advanced.WinAPI.pas, Converter.Advanced.CriticalAreas.pas, Converter.Advanced.ThirdParty.pas'),
    @('Project generation','Produce FMX-aware startup and project metadata.','Converter.Project.Generator.pas')
  )

  Add-TopSection -Selection $selection -Title '4. End-to-End Conversion Workflow' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'A single conversion request proceeds through a predictable sequence. Understanding this pipeline is essential when diagnosing why an output artifact is wrong.' -Style 'Normal'
  Add-ProcessDiagram -Document $document -Selection $selection -Title '4.1 Workflow Diagram' -Note 'This flow shows the major transformation stages from discovery through output emission.' -Stages @(
    @{ Title = 'Discover'; Detail = 'File scan' + [Environment]::NewLine + 'option filter' },
    @{ Title = 'Parse and Analyze'; Detail = 'DFM model' + [Environment]::NewLine + 'Pascal structure' + [Environment]::NewLine + 'mapping lookup' },
    @{ Title = 'Transform and Normalize'; Detail = 'FMX conversion' + [Environment]::NewLine + 'source rewrites' + [Environment]::NewLine + 'binding injection' },
    @{ Title = 'Emit and Report'; Detail = 'Output files' + [Environment]::NewLine + 'reports' + [Environment]::NewLine + 'status log' }
  )
  Add-Paragraph -Selection $selection -Text '4.2 Step-by-Step Narrative' -Style 'Heading 2'
  Add-NumberList -Selection $selection -Items @(
    'The file manager discovers candidate files according to the selected source path, recursion setting, and file-type options.',
    'Each artifact is routed to the correct processing branch. DFM files become component trees; Pascal files become structured source units.',
    'The integration layer applies global normalization, including unit inference, VCL-to-FMX substitutions, resource rewrites, and compatibility injection.',
    'Specialized modules rewrite higher-risk patterns such as WinAPI, custom drawing, media behavior, and data-aware controls.',
    'Output files and reports are written, and the converted project is then validated in Delphi.'
  )

  Add-TopSection -Selection $selection -Title '5. User Interface and Operator Flow' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'The operator-facing layer is intentionally simple. Its job is to collect options, start conversion work, and show progress. It should not become the home for core rewrite logic.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text '5.1 Main Operator Tasks' -Style 'Heading 2'
  Add-BulletList -Selection $selection -Items @(
    'Select the source project or root folder.',
    'Select the output directory.',
    'Choose recursion and file-scope behavior.',
    'Launch the conversion.',
    'Review the log, open the converted project, and validate the output in Delphi.'
  )
  Add-Paragraph -Selection $selection -Text '5.2 UI Responsibilities' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'MainForm is responsible for operator workflow, progress output, and status visibility. Conversion logic should remain in the engine, parser, integration, and mapping units unless the user experience itself needs to change. The current live v5.0 interface is a tabbed operator workspace with a Vanguard release hero, Dashboard, Project Scan, Component Map, Property Map, Event Map, Conversion Output, and Rules. Open Report, Print Report, and Open Output Folder remain UI shell actions, while the rule toggles are passed into explicit engine options rather than treated as decorative markers.' -Style 'Normal'

  Add-TopSection -Selection $selection -Title '6. Core Engine, File Management, and Orchestration' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text '6.1 Core Types' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Core.Types defines shared conversion types, issue tracking, options, and context state. It is the vocabulary layer the rest of the converter relies on.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text '6.2 Engine' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Core.Engine coordinates top-level conversion sequencing, lifecycle control, and status accounting. It should remain focused on orchestration rather than file-format specifics.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text '6.3 File Management' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Core.FileManager handles source discovery and output writing. It is responsible for honoring recursion options, preserving relative structure where practical, preserving encoding, and preventing stale output from being mistaken for current output. In the current v5.0 path it also owns practical output hygiene: the destination folder is created when conversion starts, source-local companion files are copied from the source root only, and stale build subtrees such as Win32, Win64, Debug, Release, deploy, __history, and __recovery are not searched for ambiguous runtime companions.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text '6.4 Integration' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Core.Integration is the highest-leverage engineering unit in the system. It applies cross-file FMX rewrites, uses-clause rebuilding, binding injection, runtime compatibility changes, and late-stage normalization. Recent v5.0 work in this layer is also where many stability fixes now live: combo popup suppression and preservation, data-aware cleanup restoration, DisplayText refresh helpers, runtime text-metric helpers, GDI-to-FMX canvas substitutions with visual review reporting, form-centering float normalization, protected/conditional uses cleanup, and Windows-message review behavior.' -Style 'Normal'

  Add-TopSection -Selection $selection -Title '7. DFM Parsing and FMX Form Generation' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text '7.1 Internal Model' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Parser.DFM builds an intermediate component tree that can retain names, classes, properties, events, child objects, collection items, and dataset field objects. This intermediate structure is what lets the converter preserve more than literal text.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text '7.2 Parsing Responsibilities' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'The parser must correctly handle text DFMs, binary form normalization, nested objects, multiline properties, image payloads, collection items such as DBGrid columns, and dataset field definitions.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text '7.3 Generation Responsibilities' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'The generator must emit FMX-safe form text while preserving class intent, parent-child structure, collection syntax, geometry, and field object definitions.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'Recent generic hardening in this layer focused on form-reader safety and FMX layout fidelity. The DFM generator now strips or remaps several common VCL-only streamed properties before emission, including KeyPreview on root forms, TMemo.ScrollBars, track and progress Position properties, root-form OnDblClick, and MaxLength on numeric FMX controls such as TNumberBox and TSpinBox. It also preserves more of the original label intent by emitting safer AutoSize, anchor, StyledSettings, and text-setting combinations so centered labels and runtime-sized labels survive FMX more faithfully. Root forms and datamodules are also kept out of unsupported-component matching so user-defined form classes do not become false blockers.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Risk Area','Failure Mode','Mitigation Approach') -Rows @(
    @('Collections','Grid columns, menu items, or other nested items disappear.','Preserve collection objects in the intermediate model and regenerate them explicitly.'),
    @('Images','Binary payloads become invalid or disappear.','Normalize image data and emit FMX-safe image payloads.'),
    @('Property leaks','FMX form reader rejects VCL-only properties.','Filter or remap unsupported properties before emission.'),
    @('Layout','Controls appear stacked, hidden, or mis-parented.','Preserve parent-child relationships and emit FMX-native geometry.')
  )

  Add-TopSection -Selection $selection -Title '8. Pascal Parsing and Source Rewriting' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text '8.1 Parser Responsibilities' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Parser.Pascal identifies interface and implementation sections, class declarations, method declarations, resource directives, and other structural boundaries so that rewrites do not corrupt valid Delphi syntax.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text '8.2 Rewrite Objectives' -Style 'Heading 2'
  Add-BulletList -Selection $selection -Items @(
    'Remove or replace VCL-only unit references.',
    'Add the FMX units required by the rewritten code.',
    'Normalize resource directives from *.dfm to *.fmx.',
    'Preserve valid declarations and method boundaries.',
    'Emit FMX-safe replacements or manual-review comments for unsupported constructs.'
  )
  Add-Paragraph -Selection $selection -Text 'Current generic rewrites also normalize several high-friction code patterns discovered in real projects: TMemo.Clear is rewritten to Lines.Clear, numeric Position reads and writes are adapted to FMX Value semantics where appropriate, Windows multimedia code keeps Winapi.MMSystem when wave APIs are present, thread marshaling is normalized toward public TThread.Queue and TThread.Synchronize call shapes that the installed Delphi compiler accepts, folder-only browse logic is redirected toward SelectDirectory, and generated FMX MessageDlg calls now qualify button tokens through TMsgDlgBtn so they match the FMX/System.UITypes API surface.' -Style 'Normal'

  Add-TopSection -Selection $selection -Title '9. Component Mapping and Property Transformation' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'Converter.Mapper.Component acts as the mapping knowledge base. It determines class targets, property equivalents, and some heuristics for how a VCL control should be represented in FMX.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('VCL Class','FMX Target','Engineering Note') -Rows @(
    @('TForm','TForm','Root forms now participate in the explicit class matrix while still flowing through dedicated parser and generator rules.'),
    @('TFrame','TFrame','Frames are treated as first-class FMX targets rather than falling into a generic form-only path.'),
    @('TPanel','TPanel','Preserves visible container behavior better than TLayout.'),
    @('TGroupBox','TGroupBox','Keeps captioned frame semantics visible to the user.'),
    @('TMaskEdit','TEdit','Uses an FMX edit target and leaves mask-specific behavior as explicit manual review.'),
    @('TStaticText','TLabel','Converts cleanly to an FMX label with caption-to-text normalization.'),
    @('TFlowPanel','TFlowLayout','Uses the closest stock FMX flowing container.'),
    @('TGridPanel','TGridPanelLayout','Uses the closest stock FMX grid-layout container.'),
    @('TCheckListBox','TListBox','Maps to an FMX list box and flags checked-item behavior for review.'),
    @('TDBGrid','TStringGrid','Requires FMX DB-aware binding support, not just a renamed class.'),
    @('TDBCtrlGrid','TStringGrid','Requires structural redesign and is kept as a low-confidence substitute with manual review expectations.'),
    @('TDBEdit','TEdit','Usually paired with TLinkControlToField.'),
    @('TDBListBox','TListBox','Uses LiveBindings plus list/lookup review rather than pretending FMX has a direct DB-aware twin.'),
    @('TDBComboBox','TComboEdit','Generated combo/data bridge is safer than a blind class rename.'),
    @('TNumberBox','TNumberBox','Supported directly with numeric property remaps and FMX.NumberBox unit injection.'),
    @('TSpinEdit','TSpinBox','Converted through numeric-property and value-semantics normalization.'),
    @('TColorBox','TColorComboBox','Mapped to the FMX color-picker style control.'),
    @('TPaintBox','TPaintBox','Supported directly when the FMX.Objects unit is present.'),
    @('TRadioGroup','TRadioGroup','Handled through a reusable compatibility path that rebuilds internal FMX radio buttons safely.'),
    @('TRichEdit','TMemo','Uses TMemo as the closest stock FMX text surface and leaves rich-text behavior for review.'),
    @('TDrawGrid','TStringGrid','Uses an FMX string grid and marks custom drawing semantics as a follow-up concern.'),
    @('TFileSaveDialog','TSaveDialog','Normalizes the Vista-style dialog to the closest stock FMX save dialog.'),
    @('TLinkLabel','TLabel','Preserves visible text while leaving hyperlink behavior for review.'),
    @('TFontDialog','TFontDialog','Uses the generated FMX compatibility dialog with Execute and Font semantics.'),
    @('TTaskDialog','Manual review','No stock FMX task dialog exists, so this remains an explicit manual-review row.')
  )
  Add-Paragraph -Selection $selection -Text 'A class rename alone is rarely enough. Mapping also depends on property filtering, event translation, runtime compatibility rewrites, and in many cases additional FMX infrastructure.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'The current mapper/export toolchain supports explicit RTTI-backed reference artifacts such as vcl_class_inventory.json, fmx_class_inventory.json, class_mapping_matrix.json, property_mapping_matrix.json, and event_mapping_matrix.json. When those matrix artifacts are not present in the expected build directories, the documentation rebuild tooling can reconstruct the current class/property/event surface directly from Converter.Mapper.Component.pas so the reference set still reflects the live v5.0 rules instead of an older hand-maintained snapshot.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'These broader mappings and matrices were added only after they were verified as generic patterns across multiple independent projects. They are a reminder that release-quality coverage depends on repeated corpus testing, not on one successful application.' -Style 'Normal'

  Add-TopSection -Selection $selection -Title '10. Data-Aware Conversion and LiveBindings' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'Data-aware conversion is one of the most sensitive parts of the converter because VCL DB controls and FMX controls differ both visually and architecturally.' -Style 'Normal'
  Add-ProcessDiagram -Document $document -Selection $selection -Title '10.1 Current Binding Relationship' -Note 'The current preferred binding model uses an FMX data source bridge and then control-specific binding components.' -Stages @(
    @{ Title = 'Dataset'; Detail = 'TFDQuery or other dataset' },
    @{ Title = 'Data Source'; Detail = 'TDataSource' },
    @{ Title = 'FMX Bridge'; Detail = 'TBindSourceDB' },
    @{ Title = 'Binding Link'; Detail = 'Control or DB grid binding component' },
    @{ Title = 'FMX Control'; Detail = 'Edit, checkbox, or string grid' }
  )
  Add-Paragraph -Selection $selection -Text '10.2 Current Preferred Binding Model' -Style 'Heading 2'
  Add-BulletList -Selection $selection -Items @(
    'TBindSourceDB as the bridge from a dataset-backed data source into FMX LiveBindings.',
    'TLinkControlToField for most edit-like controls.',
    'TLinkPropertyToField for property-based cases such as IsChecked.',
    'TBindDBGridLink for converted DB grids.'
  )
  Add-Paragraph -Selection $selection -Text '10.3 Why the Grid Needed Special Handling' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'A converted VCL DBGrid should not rely on the generic FMX grid-link class. The FMX platform exposes a DB-specific binding path for database grids. Without that DB-aware path, the grid may remain empty or generate the wrong columns even while the dataset itself is active.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text '10.4 Column Preservation' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Preserving the original VCL DBGrid.Columns collection is essential. Without it, FMX tends to generate default columns for every dataset field, which can expose irrelevant fields and render memo-backed values as generic blob placeholders.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'Recent stabilization in the data-aware path also tightened the hand-off between generated FMX controls and live dataset state. Generated combo setup no longer fires popup logic during form creation, external datasource OnDataChange handlers are restored on cleanup instead of being nilled out, external navigator BeforeAction handlers are restored after teardown, and explicit TDBEdit.Field.DisplayText refresh code now survives conversion through a generated helper instead of collapsing to self-assignment.' -Style 'Normal'

  Add-TopSection -Selection $selection -Title '11. Special-Case Conversion Modules' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'Converter.Advanced.CriticalAreas handles high-risk patterns such as custom painting, owner-draw behavior, synchronization, and message-oriented code. Converter.Advanced.WinAPI covers selected Windows compatibility rewrites. Converter.Advanced.ThirdParty provides a home for unsupported and third-party control handling.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'The WinAPI module is intentionally more selective now than some earlier blanket downgrade passes. Valid Windows-targeted FMX patterns such as ShellExecute help/document launch flows, serial-port and named-pipe CreateFile / WriteFile communication paths, and surrounding process-control calls are preserved when the converter can identify them safely, while more ambiguous file/message rewrites stay on the warning or manual-review path.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'These modules exist to keep the rest of the system cleaner. If a rule is especially risky or specialized, it generally belongs here rather than in a broad parser pass.' -Style 'Normal'

  Add-TopSection -Selection $selection -Title '12. Project Generation and Output Artifacts' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'Converter.Project.Generator is responsible for making the converted project openable and buildable as an FMX application rather than leaving the user with only transformed units and form files.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'The current generator also copies common companion assets more broadly than the earlier baseline, including items such as .res, .ico, and .manifest files plus selected project-referenced local assets when they can be resolved safely. It inventories real runtime-support candidates from the source root and from existing build-output folders such as Win32, Win64, Debug, Release, and deploy, stages selected companions into the FMX output directory, filters out the primary project executable, and reports what was staged versus what still requires manual deployment. It also reports blocking issues honestly, so unsupported controls or hard conversion gaps stop being presented as a clean success.' -Style 'Normal'
  Add-BulletList -Selection $selection -Items @(
    'Converted Pascal units',
    'Converted FMX form files',
    'FMX-aware startup and project metadata',
    'Reports and issue summaries'
  )
  Add-Paragraph -Selection $selection -Text 'Timestamped snapshots are recommended so each converter iteration is preserved independently. This makes regression tracking easier and prevents accidental overwriting of known-good backup states. Before a public release, run tools\\run_release_readiness_audit.ps1 and tools\\run_regression_guards.ps1. Treat any blocker as a release stop rather than as a documentation-only reminder. The release audit covers shipped-tree cleanliness such as local paths, debug leftovers, packaging assets, and license presence, while the regression guards watch converter invariants that should remain true as internals evolve.' -Style 'Normal'

  Add-TopSection -Selection $selection -Title '13. Validation, Maintenance, and Enhancement Guidance' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'A disciplined validation sequence is one of the strongest defenses against converter regressions.' -Style 'Normal'
  Add-NumberList -Selection $selection -Items @(
    'Rebuild the converter itself.',
    'Run a fresh conversion into a clean output folder.',
    'Open the converted project in Delphi.',
    'Resolve structural and syntax issues first.',
    'Run the application and validate real workflows.',
    'Review layout, colors, captions, images, and data presentation after runtime stability is in place.'
  )
  Add-Table -Document $document -Selection $selection -Headers @('Stage','What to Check','Common Defects') -Rows @(
    @('IDE load','Forms open and units parse.','Invalid FMX properties, malformed collections, wrong form class names.'),
    @('Compile','Project and units build cleanly.','Missing uses, bad rewrites, wrong event names, visibility issues.'),
    @('Runtime','Application launches and executes real logic.','Access violations, binding exceptions, canvas misuse, startup ordering bugs.'),
    @('UX review','Layout and presentation fidelity.','Stacked controls, unreadable captions, wrong columns, missing images.')
  )

  Add-TopSection -Selection $selection -Title '14. Unit-by-Unit Technical Reference' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'This section is a technical reference for the twelve primary converter units. It is intentionally more detailed than the earlier architectural overview because future maintainers need to know where to place a change, what each unit owns, and what kinds of edits are likely to cause regressions.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'Each subsection below explains the unit''s role, major structures or routines, how it interacts with the rest of the converter, and what kinds of changes belong there.' -Style 'Normal'

  Add-Paragraph -Selection $selection -Text '14.1 Converter.Core.Types.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Core.Types.pas is the vocabulary layer of the converter. It defines the issue model, the mapping model, the conversion options container, and the conversion context object used to carry state across the run. The current live v5.0 options container carries explicit per-run flags for Critical Areas, Data Aware, ThirdParty, and WinAPI passes. Keep the UI, manuals, and code in sync around those real engine flags, and do not describe a hidden or legacy field as an operator-ready option until the runtime path actually honors it.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Provide shared types, issue objects, mapping records, run options, and the shared context so the rest of the converter can exchange structured information.'),
    @('Key structures','TConversionIssue, TComponentMapping, TConversionOptions, TConversionContext, and the severity and file-type enums.'),
    @('Important interactions','Used by the engine, file manager, parser, mapper, integration layer, and project generator as the common state and diagnostics model.'),
    @('Change guidance','Add new context or issue fields here when a new cross-cutting capability is needed. Avoid storing transient parsing logic here; this unit should remain a stable shared contract.')
  )

  Add-Paragraph -Selection $selection -Text '14.2 Converter.Core.Engine.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Core.Engine.pas is the runtime coordinator of a conversion session. It creates and owns the file manager, orchestrator, and project generator, dispatches work per file, tracks counts, writes the report, scans Pascal include directives for analysis-first handling, writes detailed issue excerpts, and manages logging and encoding-safe file reads. The current report path in this unit is also responsible for the clearer v5.0 wording: Blocking issues present, Manual review required, Clean conversion, Distinct files needing attention, original code excerpts, and HTML-first report actions in the UI.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Orchestrate one conversion run from startup through report generation and shutdown.'),
    @('Key routines','Convert, ProcessPasFile, ProcessDfmFile, ScanPascalIncludeDirectives, CopyPascalIncludeFile, GenerateReport, UILog, LogToFile, TryReadWithEncoding, DetectFileEncoding, and StripInvalidCharacters.'),
    @('Important interactions','Consumes TConversionContext, delegates file discovery and save work to TFileManager, delegates transformation to TConversionOrchestrator, and delegates startup/project output to TProjectGenerator.'),
    @('Change guidance','Put top-level sequencing, counters, and report decisions here. Do not bury file-format-specific rewrites here; push those down into parser, mapper, or integration code.')
  )

  Add-Paragraph -Selection $selection -Text '14.3 Converter.Core.FileManager.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Core.FileManager.pas is the filesystem-facing part of the converter. It scans source trees, respects file-type and recursion options, builds relative output paths, sanitizes output text, and preserves the source encoding style when saving converted files. It is also where the output tree is prepared at run time, including the cleanup of stale build artifacts before regenerated files and reports are written.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Discover source files and write converted output safely and predictably.'),
    @('Key routines','Reset, PrepareOutput, MatchesSelectedFileTypes, BuildOutputFileName, SanitizeOutputText, SaveTextPreservingSourceEncoding, and SaveConvertedFile.'),
    @('Important interactions','Uses TConversionContext for source/output settings and issue reporting. Feeds discovered files into the engine and writes transformed artifacts after integration completes.'),
    @('Change guidance','File path policy, output filtering, and encoding-preservation rules belong here. Avoid mixing semantic code rewrites into this unit.')
  )

  Add-Paragraph -Selection $selection -Text '14.4 Converter.Parser.Pascal.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Parser.Pascal.pas gives the converter structural awareness over Delphi source units. It tracks interface, implementation, initialization, and finalization regions; class declarations; method declarations and bodies; and uses clauses so later rewrites can be inserted safely. Its routine model covers constructors and destructors as well as ordinary procedures and functions, which is why later integration logic needs to stay aligned with the parser when inserting or classifying code.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Parse Pascal units into a structure detailed enough for safe transformations.'),
    @('Key structures','TPascalMethod, TPascalClass, TPascalUnit, and TPascalParser.'),
    @('Important routines','ParseUnit, ParseUsesClause, ParseMethod, ParseTypeSection, ParseImplementationUses, FindMethod, and FindMethodsByPattern.'),
    @('Change guidance','Any change that affects method detection, class boundaries, or safe insertion points belongs here. This is the right place to improve syntax awareness, not to make FMX-specific business decisions.')
  )

  Add-Paragraph -Selection $selection -Text '14.5 Converter.Parser.DFM.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Parser.DFM.pas parses VCL form definitions into an internal component tree and regenerates them as FMX form text. It handles nested components, collections, multiline properties, dataset field objects, property filtering, image payloads, and many layout-oriented translation rules.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Convert VCL DFM structure into FMX form structure while preserving hierarchy and semantics.'),
    @('Key responsibilities','Child object parsing, collection preservation, dataset field emission, string quoting, property filtering, root-form safety, numeric-property suppression, status bar panel generation, root-form mouse-event adaptation, label AutoSize/anchor/StyledSettings handling, and size/font translation.'),
    @('Important interactions','Feeds on mapping information, collaborates with integration-generated Pascal code, and must remain consistent with rewritten field declarations and event names.'),
    @('Change guidance','FMX form-reader errors are often rooted here. Put DFM-to-FMX property and structure fixes here instead of compensating later in manual output edits.')
  )

  Add-Paragraph -Selection $selection -Text '14.6 Converter.Mapper.Component.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Mapper.Component.pas is the mapping knowledge base. It stores built-in mappings, loads FMX component knowledge, researches likely class matches, and produces property and event mappings that later passes can act on.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'Recent mapping additions in this unit broaden the standard class surface materially. Beyond TNumberBox, TSpinEdit, TColorBox, and TPaintBox, the mapper now includes explicit class rows for TForm, TFrame, TMaskEdit, TStaticText, TFlowPanel, TGridPanel, TCheckListBox, TDBListBox, TRichEdit, TDrawGrid, TDBCtrlGrid, TFileSaveDialog, TLinkLabel, and explicit manual-review rows for TTaskDialog, TClientDataSet, TQuery, TADODataSet, and TSQLDataSet. Property and event knowledge has also been deepened through explicit matrix rows instead of relying only on name matching.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'This unit now exports RTTI inventories and explicit class/property/event matrices so the current mapper surface can be audited directly from the compiled converter. Property-level knowledge such as ScrollBars-to-ShowScrollBars, numeric Min/Max/Decimal translation, masked-edit review paths, and picker-event renames should remain centralized here rather than being scattered across later passes.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Translate VCL control identity into the most appropriate FMX target and supporting mapping metadata.'),
    @('Key structures','TComponentResearch, TFMXComponentInfo, and TComponentMapper.'),
    @('Important routines','LoadBuiltInMappings, LoadFMXComponentCatalog, ResearchVCLComponent, FindFMXMatch, CalculateMatchScore, and ResearchPropertyMapping.'),
    @('Change guidance','Class-name mapping, confidence, and property/event relationship knowledge belong here. Runtime behavior patches usually belong in integration, not in the mapper.')
  )

  Add-Paragraph -Selection $selection -Text '14.7 Converter.Core.Integration.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Core.Integration.pas is the global rewrite engine and the highest-leverage unit in the project. It repairs uses clauses, injects helper routines, adapts runtime behavior, preserves startup semantics, stabilizes event timing, and applies category-wide FMX normalization rules discovered during real-world testing. Recent stabilization work in this unit also preserves and chains existing handlers when generated FMX support needs to hook lifecycle or data-aware behavior, instead of overwriting those handlers blindly.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'Important newer generic behaviors in this unit include TMemo.Clear to Lines.Clear rewrites, Position and Value normalization for numeric slider-style controls, preservation and reinjection of Winapi.MMSystem for waveOut-style code, public TThread.Queue and TThread.Synchronize call normalization, plain ShowMessage preservation, qualified FMX MessageDlg button generation, folder-picker helper insertion, root-form double-click adaptation through a generated mouse-up adapter, runtime font-size helpers that release StyledSettings.Size, VCL-style text-layout helpers for label stacking, DisplayText refresh helpers for manually bound edits, combo popup suppression during startup, combo OnClosePopup preservation, and generated chaining around existing OnDestroy, OnCalcFields, dataset AfterOpen, datasource OnDataChange, and navigator BeforeAction handlers where FMX cleanup or binding support must be injected.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Apply global FMX compatibility and behavior rewrites across generated Pascal output.'),
    @('Key responsibilities','Uses-clause reconstruction, helper injection, startup adaptation, typed Pascal rewrites, grid and combo support, data-aware edit/display synchronization, media cleanup, graphics scene safety, thread marshaling normalization, and many post-processing rules.'),
    @('Important interactions','Consumes parser and mapper output, emits code that must stay in sync with FMX forms, and frequently coordinates with DataAware and Project.Generator behavior.'),
    @('Change guidance','Most global fixes land here. Because this unit affects many projects at once, every change should be tied to a repeatable pattern and regression-tested against previously fixed paths.')
  )

  Add-Paragraph -Selection $selection -Text '14.8 Converter.Advanced.DataAware.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Advanced.DataAware.pas exists because VCL data-aware controls do not map cleanly to FMX. It classifies DB-aware controls, identifies appropriate binding strategies, and supports the integration layer in deciding whether a control becomes a direct FMX control, a LiveBindings-driven control, a grid bridge, or a special-case combo/navigator path. The current v5.0 path uses normalized class matching with mapper-backed ancestry instead of loose substring checks, which keeps DB-aware detection tighter and more trustworthy across derived component classes.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Provide specialized knowledge about data-aware control conversion.'),
    @('Key focus areas','DB edits, DB combo boxes, DB grids, navigator controls, and the binding metadata needed for runtime hookup.'),
    @('Important interactions','Works closely with the integration layer, mapper, and generated FMX bindings to preserve database-driven workflows.'),
    @('Change guidance','If a problem is fundamentally about DB-aware control semantics, binding type, or dataset interaction, start here before changing more general parser logic.')
  )

  Add-Paragraph -Selection $selection -Text '14.9 Converter.Advanced.WinAPI.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Advanced.WinAPI.pas isolates Windows-specific rewrite logic. It exists so WinAPI-dependent source patterns can be preserved, adapted, or constrained without polluting the general parser and integration code with platform-specific branches.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Handle Windows API compatibility and rewrite patterns during conversion.'),
    @('Typical responsibilities','ShellExecute preservation, Windows-unit handling, serial/named-pipe/device CreateFile and WriteFile preservation, process-control preservation, message or API call normalization, and selected compatibility substitutions.'),
    @('Important interactions','Influences uses-clause requirements and any generated code that still needs explicit Windows units in FMX projects.'),
    @('Change guidance','Keep platform-specific logic here when it is truly Windows-focused. General FMX startup or event logic should still live in integration.')
  )

  Add-Paragraph -Selection $selection -Text '14.10 Converter.Advanced.CriticalAreas.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Advanced.CriticalAreas.pas is a reserved module for high-risk conversion categories that do not belong in broad, always-on parser passes. It provides a safer home for patterns such as custom drawing, owner-draw style behavior, synchronization concerns, or other specialized logic that can destabilize output if handled too casually.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Contain risky or specialized conversion behavior in a bounded unit.'),
    @('Typical use','Future expansion for difficult painting, synchronization, or message-driven scenarios that require isolated logic.'),
    @('Important interactions','Supports the integration layer by keeping dangerous rules out of general-purpose code paths until they are stable.'),
    @('Change guidance','When a fix is powerful but risky and should not immediately become a blanket global parser rule, this is an appropriate staging area.')
  )

  Add-Paragraph -Selection $selection -Text '14.11 Converter.Advanced.ThirdParty.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Advanced.ThirdParty.pas provides a controlled home for unsupported or third-party component handling. Real-world Delphi projects often depend on controls that do not have first-party FMX equivalents, so the converter needs a place to record approximations, fallbacks, or explicit manual-review guidance.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Support third-party and unsupported component conversion strategies.'),
    @('Typical responsibilities','Fallback mapping, warning generation, or controlled substitutions for controls outside the built-in VCL/FMXX mapping set.'),
    @('Important interactions','Works with the mapper and integration layer to avoid silent failure when a control class is recognized as nonstandard.'),
    @('Change guidance','Put vendor-specific or unsupported-control logic here instead of hard-coding it into broad parser decisions.')
  )

  Add-Paragraph -Selection $selection -Text '14.12 Converter.Project.Generator.pas' -Style 'Heading 2'
  Add-Paragraph -Selection $selection -Text 'Converter.Project.Generator.pas makes the final output openable and runnable in Delphi. It locates original project files, transforms DPR and DPROJ content, adapts FMX startup semantics, and copies or regenerates the project artifacts needed to load the converted application. The current v5.0 path breaks DPR startup handling into smaller helper routines for startup normalization, splash-sequence detection, Application.Run placement, and immediate CreateForm/Show cleanup so that startup fixes remain easier to reason about.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'This unit now also carries more responsibility for practical project portability. It should preserve the source Application.CreateForm list where appropriate, normalize namespace settings for FMX, inventory real runtime-support files from the source root and existing build-output folders, stage selected companions into the FMX output directory, report which support files were staged versus merely found, ensure that serious unsupported conditions become blocking results in the report rather than misleading successful conversions, and keep public source distributions clean enough to ship with a root LICENSE.txt and without local-machine release noise.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Aspect','Detail') -Rows @(
    @('Primary purpose','Generate FMX-aware project startup and project metadata.'),
    @('Key routines','FindOriginalDPR, FindOriginalDPROJ, TransformDPRContent, TransformDPROJContent, TransformDeployProjContent, companion-asset copy logic, and GenerateProject.'),
    @('Important interactions','Depends on the overall conversion context and must stay aligned with startup assumptions introduced by integration logic.'),
    @('Change guidance','Fix splash handling, Application.CreateForm ordering, project-search rules, and other project-level semantics here rather than inside individual generated target units.')
  )

  Add-TopSection -Selection $selection -Title '15. v5.0 Conversion Contract System' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'The v5.0 contract system is the central engineering safeguard for structural converter changes. A contract is a small Delphi source fixture paired with a .expected.json file. The fixture demonstrates a known conversion problem or behavior family; the expectation file declares the required output patterns, forbidden output patterns, report patterns, unit additions/removals, and status expectations. The runner converts the fixture and compares generated Pascal/FMX/DPR/INC output separately from report text so report excerpts cannot accidentally satisfy generated-code assertions.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'Contracts are not used during ordinary user conversions. They are executable regression fixtures for the converter itself. The normal converter pipeline still parses and rewrites user projects directly through the file manager, parsers, mapper, integration layer, advanced modules, and project generator. The contracts prove that those rule families continue to behave as intended.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Contract Folder','Engineering Coverage') -Rows @(
    @('include_analysis','Pascal include directives in brace and paren-star forms, source-subfolder resolution, missing includes, outside-tree warnings, nested include analysis, recursion guards, conditional directives, commented directives, Winapi/VCL/message usage inside includes, and UTF-8 include text.'),
    @('winapi_messages','SendMessage, PostMessage, DispatchMessage, PeekMessage, GetMessage, Perform, WM/CM/CN/common-control families, TWM/TCM records, WndProc, message declarations, WM_USER/custom offsets, false-positive method names, comments, strings, and system-command policy.'),
    @('uses_clause','VCL/Winapi unit removal and preservation, implementation-only Windows unit handling, conditional/protected uses blocks, and the former leftover Vcl.Themes case.'),
    @('graphics','VCL Canvas and GDI conversions to FMX canvas calls where reliable, plus explicit visual-review reporting for drawing code that still requires human inspection.'),
    @('dfm_pairs and component/event fixtures','TMemo/TStrings collection preservation, TStringGrid child/event ordering, root-form events, WndProc/message declarations, component mapping, and paired Pascal/DFM behavior.'),
    @('project_integration','Whole-project fixtures for include copying, report shape, Windows messaging, uses cleanup, DFM/FMXL behavior, and generated compile-ready scenarios.')
  )
  Add-Paragraph -Selection $selection -Text 'The final v5.0 release-candidate contract run contains 175 expectations and passed with 175 passing and 0 failing. Regression guards passed separately with 0 blockers and 0 warnings. The runner also supports -CompileGenerated for compile-ready project fixtures and skip_generated_compile for fixtures that intentionally preserve missing/manual-review dependencies.' -Style 'Normal'
  Add-Paragraph -Selection $selection -Text 'When a real beta project reveals a reusable issue, the preferred engineering workflow is: reduce the problem to a fixture, add or strengthen the expected JSON, verify that the contract fails for the current behavior, fix the converter globally, then rerun the focused contract, the full contract suite, regression guards, and a real project pass. This prevents Carillon-style findings from becoming Carillon-only fixes.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Expectation Field','Purpose') -Rows @(
    @('input_file','Identifies the fixture source path relative to the project root.'),
    @('expected_status','Declares whether conversion should succeed, convert with review, or fail.'),
    @('expected_units_added / expected_units_absent','Verifies generated uses clauses and unit injection/removal behavior.'),
    @('expected_output_patterns / forbidden_output_patterns','Checks generated Pascal, FMX, DPR, and INC output only.'),
    @('expected_report_patterns / forbidden_report_patterns','Checks report text and HTML only.'),
    @('copy_case_directory','Copies a whole fixture folder for project-level tests.'),
    @('skip_generated_compile','Exempts intentionally incomplete fixtures from -CompileGenerated.')
  )

  Add-TopSection -Selection $selection -Title 'Appendix A. File Inventory' -StartOnNewPage
  Add-Table -Document $document -Selection $selection -Headers @('File','Engineering Role') -Rows @(
    @('MainForm.pas / MainForm.fmx','Operator-facing front end and progress display.'),
    @('Converter.Core.Types.pas','Shared types, options, issue model, and context.'),
    @('Converter.Core.Engine.pas','Top-level conversion sequencing and status control.'),
    @('Converter.Core.FileManager.pas','File discovery and output writing.'),
    @('Converter.Core.Integration.pas','Global rewrite and FMX normalization layer.'),
    @('Converter.Parser.DFM.pas','DFM parsing and FMX regeneration.'),
    @('Converter.Parser.Pascal.pas','Pascal structure parsing and source-safe rewriting.'),
    @('Converter.Mapper.Component.pas','Class and property mapping knowledge base.'),
    @('Converter.Advanced.DataAware.pas','Detection and support metadata for DB-aware control conversion.'),
    @('Converter.Project.Generator.pas','FMX-aware project startup and project generation.')
  )

  Add-TopSection -Selection $selection -Title 'Appendix B. Operational Checklists' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'Before Editing Converter Logic' -Style 'Heading 2'
  Add-BulletList -Selection $selection -Items @(
    'Confirm which stage is making the wrong decision.',
    'Confirm whether the defect is structural, compile-time, runtime, or visual.',
    'Gather the original VCL artifact and the generated FMX output.',
    'Prefer a documented global rule over a speculative one-off patch.'
  )
  Add-Paragraph -Selection $selection -Text 'Before Declaring a Fix Complete' -Style 'Heading 2'
  Add-BulletList -Selection $selection -Items @(
    'Rebuild the converter.',
    'Run a fresh conversion into an empty output directory.',
    'Open the generated project in Delphi.',
    'Compile and run the converted application.',
    'Check for regressions in previously stabilized forms or units.'
  )

  Add-TopSection -Selection $selection -Title 'Appendix C. Current Limitations and Forward Work' -StartOnNewPage
  Add-BulletList -Selection $selection -Items @(
    'Owner-draw and custom paint logic often require manual review or targeted FMX redesign.',
    'Some data-aware controls still need conservative handling because there is no safe generic FMX substitute.',
    'Third-party components require either explicit mapping knowledge or a disciplined fallback strategy.',
    'Visual fidelity often converges only after structural and runtime validity are already achieved.'
  )

  Add-TopSection -Selection $selection -Title 'Index' -StartOnNewPage
  Add-Paragraph -Selection $selection -Text 'This manual index is intentionally simple and uses section references rather than page references so it remains stable while the document is still evolving.' -Style 'Normal'
  Add-Table -Document $document -Selection $selection -Headers @('Term','Section Reference') -Rows @(
    @('Bindings','Sections 4, 6, and 10'),
    @('Blob display','Sections 7 and 10'),
    @('DBGrid','Sections 9 and 10'),
    @('DFM parser','Section 7'),
    @('Integration layer','Sections 3, 6, 8, and 10'),
    @('Mapper','Sections 3 and 9'),
    @('Project generator','Section 12'),
    @('Runtime validation','Sections 4 and 13')
  )

  $document.TablesOfContents.Item(1).Update() | Out-Null
  $wdFormatXMLDocument = 16
  $document.SaveAs([ref][object]$OutputPath, [ref][object]$wdFormatXMLDocument) | Out-Null
  if ($CopyPath -ne '') {
    Copy-Item -Path $OutputPath -Destination $CopyPath -Force
  }
}
finally {
  if ($document -ne $null) {
    try { $document.Close($true) | Out-Null } catch { }
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($document) | Out-Null } catch { }
  }
  if ($word -ne $null) {
    try { $word.Quit() | Out-Null } catch { }
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null } catch { }
  }
  [gc]::Collect()
  [gc]::WaitForPendingFinalizers()
}




