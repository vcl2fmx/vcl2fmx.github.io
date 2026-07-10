param(
  [Parameter(Mandatory = $true)]
  [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

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

function Add-Bullets {
  param($Selection, [string[]]$Items)
  foreach ($item in $Items) {
    $Selection.Style = 'Normal'
    $Selection.Range.ListFormat.ApplyBulletDefault()
    $Selection.TypeText($item)
    $Selection.TypeParagraph()
  }
  $Selection.Range.ListFormat.RemoveNumbers()
  $Selection.TypeParagraph()
}

function Add-Numbers {
  param($Selection, [string[]]$Items)
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
  param($Table)
  try { $Table.Rows.Alignment = 0 } catch {}
  try { $Table.Rows.LeftIndent = 0 } catch {}
  try { $Table.AllowAutoFit = $true } catch {}
  try { $Table.PreferredWidthType = 2 } catch {}
  try { $Table.PreferredWidth = 100 } catch {}
  try { $Table.AutoFitBehavior(2) | Out-Null } catch {}
}

function Add-Table {
  param($Document, $Selection, [string[]]$Headers, [object[][]]$Rows)
  $table = $Document.Tables.Add($Selection.Range, $Rows.Count + 1, $Headers.Count)
  try { $table.Style = 'Table Grid' } catch {}
  $table.Range.Font.Name = 'Segoe UI'
  $table.Range.Font.Size = 9.5
  $table.Range.ParagraphFormat.SpaceAfter = 2
  for ($c = 0; $c -lt $Headers.Count; $c++) {
    $cell = $table.Cell(1, $c + 1)
    $cell.Range.Text = $Headers[$c]
    $cell.Range.Bold = $true
    $cell.Range.Font.Color = 16777215
    $cell.Shading.BackgroundPatternColor = 8404992
  }
  for ($r = 0; $r -lt $Rows.Count; $r++) {
    for ($c = 0; $c -lt $Headers.Count; $c++) {
      $table.Cell($r + 2, $c + 1).Range.Text = [string]$Rows[$r][$c]
    }
  }
  Fit-TableToPage $table
  $Selection.SetRange($table.Range.End, $table.Range.End)
  $Selection.TypeParagraph()
  $Selection.TypeParagraph()
}

function Add-Diagram {
  param($Document, $Selection, [string]$Title, [hashtable[]]$Stages, [string]$Note = '')
  Add-Paragraph $Selection $Title 'Heading 2'
  if ($Note -ne '') {
    Add-Paragraph $Selection $Note
  }
  $cols = ($Stages.Count * 2) - 1
  $table = $Document.Tables.Add($Selection.Range, 1, $cols)
  try { $table.Style = 'Table Grid' } catch {}
  $table.Rows.Height = 72
  $table.Range.Font.Name = 'Segoe UI'
  $table.Range.Font.Size = 9.5
  $i = 1
  foreach ($stage in $Stages) {
    $cell = $table.Cell(1, $i)
    $cell.Shading.BackgroundPatternColor = 15128749
    $cell.Range.ParagraphFormat.Alignment = 1
    $cell.Range.Bold = $false
    $cell.Range.Text = $stage.Title + [Environment]::NewLine + $stage.Detail
    if ($i -lt $cols) {
      $arrow = $table.Cell(1, $i + 1)
      $arrow.Range.Text = 'Next'
      $arrow.Range.ParagraphFormat.Alignment = 1
      $arrow.Range.Font.Size = 10
      $arrow.Range.Bold = $true
      $arrow.Shading.BackgroundPatternColor = 15986394
    }
    $i += 2
  }
  Fit-TableToPage $table
  $Selection.SetRange($table.Range.End, $table.Range.End)
  $Selection.TypeParagraph()
  $Selection.TypeParagraph()
}

function Add-PageBreak {
  param($Selection)
  $Selection.InsertBreak(7)
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
  $footer = $section.Footers.Item(1).Range
  $footer.ParagraphFormat.Alignment = 1
  $footer.Text = ''
  $doc.Fields.Add($footer, -1, 'PAGE') | Out-Null

  $normal = $doc.Styles.Item('Normal')
  $normal.Font.Name = 'Segoe UI'
  $normal.Font.Size = 10.5
  $normal.ParagraphFormat.SpaceAfter = 8
  $normal.ParagraphFormat.LineSpacingRule = 0
  $normal.ParagraphFormat.LineSpacing = 15

  $title = $doc.Styles.Item('Title')
  $title.Font.Name = 'Cambria'
  $title.Font.Size = 24
  $title.Font.Bold = $true
  $title.Font.Color = 7352422

  $h1 = $doc.Styles.Item('Heading 1')
  $h1.Font.Name = 'Cambria'
  $h1.Font.Size = 18
  $h1.Font.Bold = $true
  $h1.Font.Color = 7352422
  $h1.ParagraphFormat.SpaceBefore = 18
  $h1.ParagraphFormat.SpaceAfter = 12
  $h1.ParagraphFormat.KeepWithNext = $true

  $h2 = $doc.Styles.Item('Heading 2')
  $h2.Font.Name = 'Cambria'
  $h2.Font.Size = 13.5
  $h2.Font.Bold = $true
  $h2.ParagraphFormat.SpaceBefore = 12
  $h2.ParagraphFormat.SpaceAfter = 8
  $h2.ParagraphFormat.KeepWithNext = $true

  Add-Paragraph $sel 'VCL2FMXConverter' 'Title' 1
  Add-Paragraph $sel 'User Guide' 'Title' 1
  Add-Paragraph $sel 'Detailed Operator, Validation, and Workflow Manual' 'Normal' 1 -Italic
  Add-Paragraph $sel 'Version 5.0 Vanguard' 'Normal' 1 -Bold
  Add-Paragraph $sel ('Revision date: ' + (Get-Date -Format 'MMMM dd, yyyy')) 'Normal' 1
  Add-Paragraph $sel 'Audience: developers, technical operators, project owners, and maintainers who will run the converter and validate converted Delphi projects.' 'Normal' 1
  Add-PageBreak $sel

  Add-Paragraph $sel 'Table of Contents' 'Heading 1'
  Add-Paragraph $sel 'If Word does not populate the table immediately, right-click and choose Update Field.'
  $doc.TablesOfContents.Add($sel.Range, $true, 1, 3) | Out-Null
  $sel.TypeParagraph()

  $sections = @(
    '1. Purpose and Audience',
    '2. What the Converter Is, and What It Is Not',
    '3. System Requirements and Workspace Preparation',
    '4. Building and Launching the Converter',
    '5. Main Window and Control-by-Control Walkthrough',
    '6. Recommended Conversion Workflow',
    '7. Preparing a Source Project for Best Results',
    '8. Running a Conversion',
    '9. Reading the Log and the Conversion Report',
    '10. Understanding the Output Folder and Files',
    '11. Opening the Converted Project in Delphi',
    '12. Validating the Converted Application',
    '13. Troubleshooting and Recovery Procedures',
    '14. Working Iteratively with Codex',
    '15. Operational Best Practices',
    '16. Frequently Asked Questions',
    '17. Conversion Contracts in v5.0',
    'Appendix A. Quick Start Checklist',
    'Appendix B. Pre-Conversion Checklist',
    'Appendix C. Post-Conversion Review Checklist',
    'Appendix D. Glossary',
    'Index'
  )

  foreach ($titleText in $sections) {
    Add-PageBreak $sel
    Add-Paragraph $sel $titleText 'Heading 1'

    switch ($titleText) {
      '1. Purpose and Audience' {
        Add-Paragraph $sel 'The VCL2FMXConverter exists to automate the majority of the engineering work involved in moving a Delphi application from VCL to FMX. It is intended to reduce repetitive migration labor, surface the most important conversion risks early, and leave the user with an FMX project that can be compiled, tested, and polished in Delphi.'
        Add-Paragraph $sel 'This manual is written for people who will actually operate the converter. That includes developers converting their own applications, technical staff helping with migration efforts, project owners supervising conversion work, and maintainers who need to understand how to rerun the tool safely and interpret its output.'
        Add-Bullets $sel @(
          'Use this guide when you need to run the converter, interpret its output, and validate the converted FMX project.',
          'Use the engineering guide when you need to understand the converter internals or change its code.',
          'Use both guides together when a conversion is being actively refined and stabilized.'
        )
      }
      '2. What the Converter Is, and What It Is Not' {
        Add-Table $doc $sel @('Converter Behavior','What It Means in Practice') @(
          @('Automates most of the migration work','The converter handles the majority of syntax, form, mapping, and startup translation work automatically.'),
          @('Works as a migration system, not a blind text replacer','It uses parsing, mapping, and rewrite logic rather than relying only on global text substitution.'),
          @('Aims for buildable and reviewable output','The goal is not merely changed text; the goal is a project that can be opened, built, and exercised in Delphi.'),
          @('Leaves a small review tail','A converted application can still need font, layout, or minor behavioral review after the automated pass.'),
          @('Does not replace software testing','A successful conversion still needs compile, runtime, and user validation to confirm the result is correct.')
        )
        Add-Paragraph $sel 'A useful way to think about the converter is this: it is a serious productivity accelerator, not a promise that every converted application is instantly production-ready without verification. In practice, it can bring the vast majority of a migration under control and make the remaining issues understandable.'
        Add-Paragraph $sel 'The current generic baseline is broader than the earlier public-review drafts. It now includes safer FMX form emission, broader standard-control coverage for items such as TMaskEdit, TStaticText, TFlowPanel, TGridPanel, TCheckListBox, TRichEdit, TDrawGrid, TDBCtrlGrid, TFileSaveDialog, and TLinkLabel, direct numeric-control handling for items such as TNumberBox and converted TSpinBox workflows, generated compatibility paths for TRadioGroup and TFontDialog, and more honest blocking-issue reporting when the converter knows the output is not yet trustworthy.'
        Add-Paragraph $sel 'The live Component Map, Property Map, and Event Map pages are backed by the same current mapper knowledge used during conversion. That makes them the best quick-reference view of what the current live v5.0 build knows about standard component, property, and event coverage.'
      }
      '3. System Requirements and Workspace Preparation' {
        Add-Bullets $sel @(
          'A Windows development environment with Delphi installed and working.',
          'Access to the original VCL source code and form files.',
          'A separate target directory for generated FMX output.',
          'Sufficient disk space for source, output, reports, and milestone backups.',
          'A backup strategy before major converter runs or large rule changes.'
        )
        Add-Paragraph $sel 'A clean folder layout is strongly recommended. Keep the converter source, the original VCL project, and the converted FMX output in separate locations. This prevents stale output files from being mistaken for current results and makes it much easier to compare source and target artifacts during troubleshooting.'
        Add-Table $doc $sel @('Workspace Area','Recommended Use') @(
          @('Converter folder','Contains the converter source and its own documentation/scripts.'),
          @('Source project folder','Contains the original VCL application being migrated.'),
          @('Output folder','Contains only the newly generated FMX project for the current run.'),
          @('Backup storage','Contains milestone snapshots, cloud copies, or archived converter states.')
        )
      }
      '4. Building and Launching the Converter' {
        Add-Numbers $sel @(
          'Open the VCL2FMXConverter project in Delphi.',
          'Build the converter and confirm the build completes cleanly.',
          'Run the converter application.',
          'Verify that the tabbed workspace opens and that Dashboard, Project Scan, Component Map, Property Map, Event Map, Conversion Output, and Rules are available.'
        )
        Add-Paragraph $sel 'If the converter itself does not build, stop there and resolve that issue before attempting any project migration. The converter must be treated like any other software tool: it needs a healthy build before its output can be trusted.'
      }
      '5. Main Window and Control-by-Control Walkthrough' {
        Add-Table $doc $sel @('Control','Purpose','How a User Should Think About It') @(
          @('Source project','Points at the original VCL project or source root.','This is the source of truth the converter will scan.'),
          @('Output folder','Points at the output directory for generated FMX artifacts.','Treat this as disposable and regenerable output, not as your only copy of the application.'),
          @('Files to convert','Chooses PAS only, DFM only, or both.','Use narrower scopes for focused retests, and use both for full conversions.'),
          @('Include subfolders','Controls whether subdirectories are scanned.','Leave it enabled for complete projects unless you intentionally want to limit the run.'),
          @('Report and output actions','Opens the generated report, prints it when supported, or opens the output folder.','Use these after every run so report review is part of the normal workflow. When both formats exist, the HTML report is preferred.'),
          @('Critical Areas / Data Aware / 3rd Party / WinAPI','Per-run rule toggles for the specialized conversion families.','Leave these enabled for a normal full pass, and only turn one off when intentionally isolating behavior.'),
          @('Convert Project','Starts the conversion process.','Only press this after source, output, scope, and rule choices are correct.'),
          @('Conversion Output log','Displays progress and key messages while also supporting report review.','Read it after every run; it is the first indicator of what happened.')
        )
        Add-Paragraph $sel 'The current v5.0 main window is a tabbed workspace with a Vanguard release hero. Dashboard shows the latest run summary and quick actions, Project Scan holds the path and scope controls, Component Map / Property Map / Event Map expose the live mapper reference surface, Conversion Output shows the live log and report status, and Rules controls the specialized conversion families. The converter still does its real work behind the scenes, but the operator needs to use the front end carefully because path mistakes, stale output folders, and poorly scoped runs can create misleading results.'
        Add-Paragraph $sel 'The live Component Map, Property Map, and Event Map screens are no longer static showcase text. They are generated from the same current mapper knowledge used during conversion, so they are the quickest way to inspect what the live build knows about standard class, property, and event coverage.'
      }
      '6. Recommended Conversion Workflow' {
        Add-Diagram $doc $sel '6.1 Practical Operator Workflow' @(
          @{ Title = 'Prepare'; Detail = 'check source' + [Environment]::NewLine + 'set clean target' },
          @{ Title = 'Run'; Detail = 'select options' + [Environment]::NewLine + 'start conversion' },
          @{ Title = 'Open'; Detail = 'load FMX project' + [Environment]::NewLine + 'build in Delphi' },
          @{ Title = 'Validate'; Detail = 'run app' + [Environment]::NewLine + 'exercise real workflows' },
          @{ Title = 'Refine'; Detail = 'improve converter' + [Environment]::NewLine + 'rerun cleanly' }
        )
        Add-Numbers $sel @(
          'Prepare a clean output directory.',
          'Run the converter against the selected VCL project.',
          'Open the generated FMX project in Delphi.',
          'Resolve structural and compile issues first.',
          'Run the converted app and validate real user workflows.',
          'Only after runtime stability, review and tune layout or styling details.'
        )
        Add-Paragraph $sel 'This sequence matters. Trying to perfect colors or spacing before the application builds and runs cleanly is usually wasted effort. Stabilize structure first, runtime second, and presentation third.'
      }
      '7. Preparing a Source Project for Best Results' {
        Add-Paragraph $sel 'Some preparation work in the source project can make the converter easier to use and the output easier to validate. This is not always required, but it is often helpful.'
        Add-Bullets $sel @(
          'Know which folder is the real source root and which files are truly active in the project.',
          'Be aware of duplicated unit names or old backup copies inside the source tree.',
          'Understand any database, media, or file-path dependencies that the converted application will need at runtime.',
          'Keep note of major workflows that must be validated after conversion, such as startup, scheduling, playback, database edits, dialogs, and reporting.',
          'If possible, have the original VCL application available for side-by-side behavior comparison.'
        )
        Add-Paragraph $sel 'The converter can do a great deal, but it is still easier to use when the operator knows which source files matter and which business workflows are critical.'
      }
      '8. Running a Conversion' {
        Add-Numbers $sel @(
          'Enter or browse to the source folder.',
          'Enter or browse to the target folder.',
          'Choose PAS only, DFM only, or both.',
          'Set the include-subfolders option and the four rule toggles as needed.',
          'Review the specialized rule choices if your workflow needs a focused retest.',
          'Click Convert and allow the process to complete.',
          'Read the log before opening the output in Delphi. When the HTML report exists, use Open Report or Print Report directly from the converter, and use Open Output Folder when you need the generated files immediately.'
        )
        Add-Paragraph $sel 'For full project migrations, the normal choice is to convert both PAS and DFM files recursively into a clean output folder. Targeted runs are useful only when you already know that a specific phase is the thing under review.'
        Add-Paragraph $sel 'When you browse to a source folder, the converter can suggest a sibling target named `ProjectName - FMX Output`, but that suggestion is only a path proposal. The output directory itself is created when the run starts, and the converter also clears stale build subfolders such as Win32, Win64, Debug, Release, deploy, and __history from the output tree before writing the new run.'
        Add-Paragraph $sel 'During the same run, the generator can inventory real support files in the source root and in existing build-output folders. That makes the report more trustworthy because helper executables, DLLs, library files, sound-font files, and similar runtime companions are reported from real locations instead of being guessed from quoted Pascal strings.'
      }
      '9. Reading the Log and the Conversion Report' {
        Add-Paragraph $sel 'Every conversion run should be reviewed through two channels: the live log in the converter UI and the generated report files in the output folder. When the HTML report exists, the Open Report and Print Report buttons use it first. These are not optional extras; they are part of the operating workflow.'
        Add-Table $doc $sel @('Information Source','What It Tells You','How to Use It') @(
          @('Conversion Output log','Live progress and immediate messages during the run.','Use it to see which files were processed and whether the run completed normally.'),
          @('Conversion reports','Persistent text and HTML records of what the converter saw and reported.','Use them for later review, troubleshooting, printing, and communication with other engineers.'),
          @('Delphi compile output','The authoritative correctness check after generation.','Use it to identify real syntax, unit, and form-reader issues.'),
          @('Runtime behavior','The final reality check for workflow correctness.','Use it to confirm that the converted application actually behaves acceptably.')
        )
        Add-Paragraph $sel 'Pay special attention to the final run status. The current v5.0 report flow distinguishes Blocking issues present, Manual review required, and Clean conversion, and the generated report calls out a recommended next step, Distinct files needing attention, and files with conversion errors. Treat blocking issues as stop conditions even if files were generated. Informational messages about external project assets are different: they warn that companion files may still need manual copying or relocation before runtime testing.'
        Add-Paragraph $sel 'The current report also distinguishes between support files that were actually staged into the FMX output directory and support files that were only found in the source root or beside an existing built executable. Read those companion-file notes carefully, because staging a helper file into the output tree is not the same thing as confirming it will deploy beside the final built executable.'
        Add-Paragraph $sel 'If the report and the compiler disagree, the compiler wins. If Code Insight and the real compiler disagree, the compiler wins again. The memo log and report are aids, not replacements for build and run validation.'
      }
      '10. Understanding the Output Folder and Files' {
        Add-Table $doc $sel @('Output Artifact','Purpose','User Action') @(
          @('Converted .pas files','FMX-oriented Pascal source units derived from the original VCL source.','Open in Delphi and build as part of the generated project.'),
          @('Converted .fmx files','FireMonkey form definitions derived from DFM files.','Allow Delphi to load them and watch for reader errors.'),
          @('Project files','The FMX project shell and startup metadata.','Open the project file in Delphi and build it.'),
          @('Conversion report','Text summary of the run.','Keep it for diagnostics and engineering review.'),
          @('Milestone backups','Snapshots of converter state or other preserved artifacts.','Store separately so they do not pollute source or output folders.')
        )
        Add-Paragraph $sel 'Project files now include a more complete FMX shell, and the generator attempts to carry along common companion assets such as .res, .ico, .manifest, and safe local project references. If the source project points at an absolute external asset outside the source tree, you should expect to verify or copy that file manually before runtime testing.'
        Add-Paragraph $sel 'The output folder may now also contain staged runtime companions such as helper executables, DLLs, library files, or sound-font style support files when the generator found real candidates in the source root or in existing build-output folders such as Win32, Win64, Debug, Release, or deploy. Those files are copied to make review easier, but you still need to verify the final deployment location expected by the generated app.'
        Add-Paragraph $sel 'A clean output folder is one of the most important habits in using the converter. Stale generated units and forms can create false problems, hide real changes, and lead Delphi to load the wrong copy of a file.'
      }
      '11. Opening the Converted Project in Delphi' {
        Add-Numbers $sel @(
          'Open the generated project in Delphi.',
          'Let Delphi load the forms and watch for form-reader errors first.',
          'Build the project and capture the real compiler results.',
          'Fix structural problems before pursuing visual polish.',
          'Rebuild and rerun after each significant converter improvement.'
        )
        Add-Paragraph $sel 'The converter now strips or remaps several common VCL-only form properties before Delphi sees the FMX output, so some earlier reader failures no longer appear. Even so, form-reader errors still deserve first priority because they block every later stage of validation.'
        Add-Paragraph $sel 'The first successful load of the project is a major milestone, but it is not the end of validation. A project can open and still fail at compile time, or compile and still fail at runtime. Treat these as separate checkpoints.'
      }
      '12. Validating the Converted Application' {
        Add-Table $doc $sel @('Validation Layer','Goal','Typical Questions') @(
          @('Structural','Can Delphi read the generated forms and units?','Are there reader errors, malformed collections, or invalid properties?'),
          @('Compile-time','Does the project build on the first pass?','Are units missing, events wrong, or symbols unresolved?'),
          @('Runtime','Does the application start and execute real workflows?','Do timers, media, data, dialogs, and navigation work?'),
          @('Visual','Does the application look acceptable and remain usable?','Are fonts, labels, colors, and layouts readable and sensible?')
        )
        Add-Paragraph $sel 'Validation should now explicitly cover the newer generic support surface: numeric entry controls, radio-group style selections, font-picking workflows, scrollable long-message dialogs, and any wave-audio paths that depend on Winapi.MMSystem or waveOut APIs.'
        Add-Paragraph $sel 'Real validation means exercising the actual workflows that matter to the application: data entry, startup, scheduling, media playback, dialogs, and reporting. A converted app is only as good as the workflows it can successfully perform.'
        Add-Bullets $sel @(
          'Test startup and shutdown behavior.',
          'Test any timers or schedules if the original app depended on them.',
          'Test data-aware screens and save/cancel workflows.',
          'Test media or file operations where applicable.',
          'Test secondary forms, help, menus, and common user actions.',
          'Test numeric entry controls such as TNumberBox and converted TSpinBox screens.',
          'Test TRadioGroup and TFontDialog workflows if the original application used them.',
          'Test wave-audio or WinMM paths where the source project uses MMSystem or waveOut APIs.'
        )
        Add-Bullets $sel @(
          'If a form uses shared datasets, shared datasources, shared navigators, or shared combo controls, close and reopen the form and verify the shared object still behaves correctly afterward.',
          'If the application launches help files, external documents, URLs, or utility executables, test those paths explicitly in the converted FMX build.'
        )
      }
      '13. Troubleshooting and Recovery Procedures' {
        Add-Table $doc $sel @('Symptom','Likely Cause','Recommended Response') @(
          @('Form reader error','An unsupported VCL property or malformed FMX output was emitted.','Fix the converter rule, regenerate into a clean output folder, and retest.'),
          @('Compiler errors after regeneration','A converter rule is missing or incomplete.','Treat the compiler message as the next engineering target and improve the converter globally.'),
          @('Runtime access violation','A startup, event, media, drawing, or binding mismatch remains.','Trace the workflow, isolate the phase, and improve the converter behavior globally.'),
          @('Visual mismatch only','The app is basically working but presentation differs.','Defer deep visual polishing until structural and runtime behavior are stable.'),
          @('Code Insight disagreement','The IDE parser is stale or confused.','Trust the real compiler and reopen files or restart the IDE if needed.'),
          @('Conversion completed with blocking issues','A real unsupported component or blocking rule gap was detected.','Stop there, read the report, and improve the converter globally before trusting the output.'),
          @('External project asset reference not copied','The project shell references a file outside the source tree or in an unresolved path.','Copy or relocate the asset manually, then decide whether the generator needs a new generic asset-copy rule.')
        )
        Add-Paragraph $sel 'If a run goes badly, do not try to repair everything at once. The fastest route is usually to identify the highest-severity problem, improve the converter globally, regenerate clean output, and retest.'
      }
      '14. Working Iteratively with Codex' {
        Add-Paragraph $sel 'Codex is most effective in this workflow when it is used to make the converter itself better, not when it is used to permanently hand-edit one generated target unit. The healthier workflow is: use the generated project to expose a pattern, fix the converter globally, regenerate, and verify that future projects will benefit too.'
        Add-Bullets $sel @(
          'Provide exact compiler and runtime symptoms when asking for converter help.',
          'Prefer one real issue at a time over vague lists of everything that looks wrong.',
          'Rebuild the converter and regenerate after each significant change.',
          'Keep milestone backups so good states are not lost.'
        )
        Add-Paragraph $sel 'This iterative method is not a weakness; it is the normal way to mature a migration tool against real-world software.'
      }
      '15. Operational Best Practices' {
        Add-Bullets $sel @(
          'Always keep the source project, output project, and converter workspace separate.',
          'Use clean output folders for serious test cycles.',
          'Back up milestone converter states before risky changes.',
          'Keep zipped milestone backups out of the live converter workspace so later workspace backups do not recurse and grow uncontrollably.',
          'Treat real compiler output as the authority over IDE-only hints or stale parse errors.',
          'Record what was fixed globally so later projects benefit immediately.',
          'Do not burn time on tiny visual tweaks until the application builds and runs correctly.'
        )
      }
      '16. Frequently Asked Questions' {
        Add-Table $doc $sel @('Question','Answer') @(
          @('Will every project convert perfectly on the first run?','No. The converter is powerful, but real-world projects still expose new patterns that may need another global rule.'),
          @('Should I hand-edit the generated FMX project permanently?','Only for temporary testing or minor final polish. The real fix should go into the converter whenever the pattern is reusable.'),
          @('Why do I still need Delphi after conversion?','Because the generated project still has to be built, run, and validated in the real Delphi environment.'),
          @('Why are backups important?','Because converter improvements are cumulative, and known-good milestone states are valuable when comparing behavior or recovering from regressions.'),
          @('When should I review visuals?','After the project loads, compiles, and runs acceptably. Visual polish is usually the last phase.'),
          @('What does blocking issues mean?','It means the converter found a serious unsupported pattern or rule gap. Generated files may exist, but you should resolve the blocking issue before treating the output as a valid converted project.')
        )
      }
      '17. Conversion Contracts in v5.0' {
        Add-Paragraph $sel 'Version 5.0 adds an executable conversion-contract system. Contracts are small Delphi fixture projects and units that describe a known conversion problem, the expected generated Pascal/FMX output, and the expected conversion report behavior. They are not loaded during a normal user conversion. Instead, they are run by the engineering test runner before release so the converter does not silently lose behavior that was already fixed.'
        Add-Paragraph $sel 'For operators, contracts matter because they explain why v5.0 is more disciplined than earlier releases. The converter is no longer trusted merely because a single project looks good. Each structural rule should have a small fixture, an expectation file, and a regression guard that proves the rule still works after later changes.'
        Add-Table $doc $sel @('Contract Area','What It Protects') @(
          @('Include analysis','Beside-source, subfolder, nested, recursive, missing, outside-tree, conditional, commented, and UTF-8 Pascal include directives.'),
          @('Windows messaging','SendMessage, PostMessage, Perform, WndProc, message declarations, WM/CM/CN/common-control families, WM_USER, false positives, and system-command handling.'),
          @('Uses cleanup','Removal of unused VCL and Winapi units, including conditional/protected uses blocks and the former Vcl.Themes leftover case.'),
          @('DFM/FMXL generation','TMemo/TStrings collection preservation, TStringGrid event ordering, accented text, and paired Pascal/DFM form behavior.'),
          @('Graphics and GDI','Safe FMX canvas substitutions where possible, plus visual-review reporting when drawing code still needs human verification.'),
          @('Project integration','Whole-project fixtures that exercise include copying, report shape, Windows messaging, uses cleanup, and generated output together.')
        )
        Add-Paragraph $sel 'The current v5.0 contract set contains 175 expectations. The final release-candidate run passed with 175 passing and 0 failing contracts. Regression guards also passed with 0 blockers and 0 warnings.'
        Add-Paragraph $sel 'A normal conversion does not compare each user file against every contract. Contracts are engineering fixtures used by the test runner. User source files are converted by the parser, mapper, rewrite, integration, and project-generation rules. The contracts verify those rules ahead of time.'
        Add-Paragraph $sel 'When a real project such as Carillon exposes a new reusable pattern, the preferred v5.0 workflow is to add or strengthen a contract first, then update the converter until that contract passes. This keeps the fix useful for the wider user base instead of becoming a project-only workaround.'
      }
      'Appendix A. Quick Start Checklist' {
        Add-Numbers $sel @(
          'Build the converter.',
          'Choose source and target folders.',
          'Use a clean output directory.',
          'Run conversion.',
          'Open the FMX project in Delphi.',
          'Build, run, and validate the converted app.',
          'Improve the converter globally and regenerate as needed.'
        )
      }
      'Appendix B. Pre-Conversion Checklist' {
        Add-Bullets $sel @(
          'Confirm the real source root folder.',
          'Confirm the target output folder is correct and clean.',
          'Know which workflows are critical in the original application.',
          'Ensure supporting files such as databases or media are available for runtime testing.',
          'Plan where milestone backups will be stored.'
        )
      }
      'Appendix C. Post-Conversion Review Checklist' {
        Add-Bullets $sel @(
          'Did the forms open without reader errors?',
          'Did the project compile on the first pass?',
          'Did the application start and close normally?',
          'Did core workflows run correctly?',
          'Are the remaining issues structural, runtime, or merely visual?',
          'Was the converter fixed globally if a reusable defect was found?'
        )
      }
      'Appendix D. Glossary' {
        Add-Table $doc $sel @('Term','Meaning') @(
          @('VCL','Visual Component Library, Delphi''s traditional Windows UI framework.'),
          @('FMX','FireMonkey, Delphi''s multi-platform UI framework.'),
          @('DFM','A Delphi form definition file used by VCL projects.'),
          @('FMX form','The converted FireMonkey form file, typically emitted as .fmx.'),
          @('LiveBindings','The FMX binding model used for data-aware behavior.'),
          @('Global fix','A converter change that benefits multiple current or future projects, not just one output file.')
        )
      }
      'Index' {
        Add-Table $doc $sel @('Term','Section Reference') @(
          @('Backups','Sections 3, 10, and 15'),
          @('Codex workflow','Section 14'),
          @('Delphi validation','Sections 11 and 12'),
          @('Output folder','Section 10'),
          @('Troubleshooting','Section 13')
        )
      }
    }
  }

  if ($doc.TablesOfContents.Count -gt 0) {
    $doc.TablesOfContents.Item(1).Update() | Out-Null
  }
  $doc.SaveAs([ref]$OutputPath, [ref]16)
}
finally {
  if ($doc -ne $null) {
    try { $doc.Close($true) | Out-Null } catch { }
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null } catch { }
  }
  if ($word -ne $null) {
    try { $word.Quit() | Out-Null } catch { }
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null } catch { }
  }
  [gc]::Collect()
  [gc]::WaitForPendingFinalizers()
}


