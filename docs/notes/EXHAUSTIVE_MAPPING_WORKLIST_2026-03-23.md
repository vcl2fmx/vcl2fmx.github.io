# Exhaustive VCL-to-FMX Mapping Worklist

## Purpose

This file is the reference plan for doing the VCL-to-FMX Migration Assistant "the right way" later, instead of continuing one-off fixes driven by individual test projects.

The goal is to build a mapping-first system that:

- inventories VCL classes and FMX classes
- inventories published properties and events for both frameworks
- compares event signatures, not just event names
- drives parser decisions from a real mapping matrix
- drives report generation from that matrix
- uses real project conversions only as regression tests, not as the primary discovery mechanism

## Current v2 Status Snapshot

The current `v2` codebase now has the foundation of this work in place, even though the overall worklist is not complete yet.

- RTTI inventory export is implemented:
  - `vcl_class_inventory.json`
  - `fmx_class_inventory.json`
- Explicit matrix export is implemented:
  - `class_mapping_matrix.json`
  - `property_mapping_matrix.json`
  - `event_mapping_matrix.json`
- Current compiled-mapper snapshot:
  - class rows: `77`
    - `36` direct
    - `33` substitute
    - `8` unmapped/manual
  - property rows: `632`
    - `291` direct
    - `23` rename
    - `4` transform
    - `48` omit
    - `266` manual review
  - event rows: `221`
    - `69` direct
    - `5` rename
    - `54` incompatible signature
    - `93` manual review
- The live `Component Map`, `Property Map`, and `Event Map` pages now reflect the current compiled mapper and discovery paths rather than stale hand-maintained summaries.
- The converter and report logic still primarily run from compiled mapper code, not from reading the JSON artifacts back as their runtime source of truth.

So the important honest read is:

- `Phase 1` is materially in place.
- `Phase 2` is materially in place for the standard/common surface.
- `Phase 3` and `Phase 4` now have explicit artifact scaffolding and deeper rule coverage, but they are still not exhaustive.
- The long tail of specialty controls, runtime semantics, and deeper property/event classification remains future work.

## Honest Scope

An exhaustive pass can be realistic for:

- standard VCL framework classes
- standard FMX framework classes
- common runtime/Pascal patterns used by VCL applications

It is not realistically "exhaustive" for:

- every third-party VCL component ever made
- every WinAPI/platform integration pattern
- every custom drawing or architecture pattern in legacy applications

So the correct target is:

- exhaustive for standard VCL/FM X classes and published surfaces
- broad and growing coverage for runtime/code patterns
- report-driven manual handling for unsupported third-party and platform-specific behavior

## Time Estimate

If resumed later, a realistic time frame would be:

- `2 to 3 weeks`
  - complete the standard VCL/FM X property/event matrix foundation
  - stabilize report generation around that matrix
- `6 to 10 weeks`
  - materially improve hard-project conversion coverage with runtime/Pascal pattern families
- `3 to 6 months`
  - approach broad, mature migration-assistant coverage across real-world standard VCL projects

## Definition Of Done

The mapping work should not be considered complete until all of the following are true:

1. Standard VCL classes of interest are inventoried by RTTI.
2. Standard FMX classes of interest are inventoried by RTTI.
3. Each VCL class has a classified mapping outcome:
   - direct
   - substitute
   - partial
   - unsupported
4. Each published VCL property is classified:
   - same-name direct map
   - renamed map
   - transformed map
   - omit silently
   - manual review
   - blocking
5. Each published VCL event is classified:
   - same-name direct map
   - renamed map
   - unsupported
   - incompatible signature
6. The DFM parser uses the matrix instead of ad hoc guesses.
7. The Pascal-side audit uses the matrix and runtime-pattern families.
8. The report reflects both stream-level and Pascal/runtime-level truth.
9. The regression corpus passes with expected report outcomes.

## Phase 0: Freeze The Rules Of The System

Before expanding coverage, lock the rules of classification:

- `Direct`
  - same class or safe substitute, same property/event semantics
- `Mapped`
  - different FMX property/event name but safe equivalent exists
- `Transformed`
  - value or syntax conversion required
- `Omit`
  - property/event should not be written to `.fmx`
- `Manual Review`
  - safe automatic handling is not known, but output can still be opened/fixed
- `Blocking`
  - generated output is expected not to open/compile/run until fixed

This classification must be used everywhere:

- mapper
- DFM parser
- Pascal parser
- output audit
- report writer

## Phase 1: Build Exhaustive Framework Inventories

### VCL Units To Inventory

At minimum, inventory classes from:

- `Vcl.Forms`
- `Vcl.Controls`
- `Vcl.StdCtrls`
- `Vcl.ExtCtrls`
- `Vcl.ComCtrls`
- `Vcl.Dialogs`
- `Vcl.Menus`
- `Vcl.ActnList`
- `Vcl.Buttons`
- `Vcl.Mask`
- `Vcl.Grids`
- `Vcl.DBGrids`
- `Vcl.DBCtrls`
- `Vcl.CheckLst`
- `Vcl.ImgList`
- `Vcl.Samples.Spin`
- `Vcl.Samples.Calendar`
- any other standard VCL unit already used by the converter or common test projects

### FMX Units To Inventory

At minimum, inventory classes from:

- `FMX.Forms`
- `FMX.Controls`
- `FMX.StdCtrls`
- `FMX.Edit`
- `FMX.ListBox`
- `FMX.Memo`
- `FMX.Layouts`
- `FMX.Objects`
- `FMX.ExtCtrls`
- `FMX.ScrollBox`
- `FMX.TabControl`
- `FMX.Grid`
- `FMX.Menus`
- `FMX.Dialogs`
- `FMX.ActnList`
- `FMX.TreeView`
- `FMX.DateTimeCtrls`
- `FMX.Colors`
- `FMX.SpinBox`
- `FMX.NumberBox`
- `FMX.Calendar`
- `FMX.Media`

### Inventory Data To Capture

For every class:

- qualified name
- base class
- published properties
- published events
- property types
- event method signatures

### Required Output Artifacts

Generate reference data files for later maintenance:

- `vcl_class_inventory.json`
- `fmx_class_inventory.json`
- optional human-readable summaries:
  - `VCL_CLASS_INVENTORY.md`
  - `FMX_CLASS_INVENTORY.md`

## Phase 2: Build The Real Mapping Matrix

For every VCL class in scope, classify the class mapping:

- exact FMX equivalent
- best substitute
- compatibility helper needed
- unsupported/manual

### Standard Class Families To Cover

- forms and frames
- labels
- edits and masked edits
- memo controls
- buttons and speed buttons
- check boxes and radio buttons
- radio groups
- group boxes and panels
- images and paint surfaces
- shapes
- progress bars and track bars
- combo boxes and list boxes
- date/time edits and pickers
- menus and menu items
- dialogs
- timers
- action lists and actions
- scroll containers and tab containers
- grids and string grids
- tree views
- status bars and tool bars
- spin edits / numeric edits
- color/font chooser controls
- DB-aware controls

### Matrix Fields Per Class

Each matrix row should include:

- VCL class
- FMX class
- mapping type
- confidence
- notes
- parser policy
- runtime-policy notes

### Required Output Artifacts

- `class_mapping_matrix.json`
- optional human-readable:
  - `CLASS_MAPPING_MATRIX.md`

## Phase 3: Property Matrix

For each mapped VCL class, classify every published property.

### Property Classification

Each property must be tagged as one of:

- `direct`
- `rename`
- `transform`
- `omit`
- `manual_review`
- `blocking`

### Property Metadata To Capture

- source class
- source property
- target class
- target property, if any
- source type
- target type
- transformation function, if required
- default report wording
- whether omission should be silent or reportable

### Property Families That Must Be Explicitly Covered

- text/caption
- font families, size, style, color
- alignment and anchors
- margins and padding
- color and fill/stroke
- visibility/enabled
- size/position
- image-related properties
- border and chrome
- scrollbars
- item collections
- value/min/max/range
- state/checked/selected
- tab order / focus
- layout/auto-size/word-wrap
- style and styled settings
- designer-only VCL properties

### Required Output Artifacts

- `property_mapping_matrix.json`
- optional:
  - `PROPERTY_MAPPING_MATRIX.md`

## Phase 4: Event Matrix

For each mapped VCL class, classify every published event.

### Event Classification

Each event must be tagged as one of:

- `direct`
- `rename`
- `incompatible_signature`
- `manual_review`
- `unsupported`

### Event Metadata To Capture

- source class
- source event
- source signature
- target class
- target event
- target signature
- signature compatibility result
- recommended manual reconnection note, if not direct

### Event Families That Must Be Explicitly Covered

- click / double click
- mouse down / move / up / wheel / enter / leave
- key down / key up / key press
- create / show / hide / close / destroy
- resize / paint / repaint
- change / select / enter / exit
- popup / dropdown / closeup / picker events
- grid draw / grid cell events
- media / timer / dialog callbacks

### Required Output Artifacts

- `event_mapping_matrix.json`
- optional:
  - `EVENT_MAPPING_MATRIX.md`

## Phase 5: Streaming And Designer Validity Layer

The matrix must not only know whether a property/event exists.
It must also know whether it is safe to stream into `.fmx`.

### Streaming Rules Must Cover

- properties safe to write into `.fmx`
- properties that exist but should not be streamed
- events safe to stream
- events that must be omitted despite name/signature matches
- root-form-specific differences
- nonvisual component behavior
- compatibility/helper classes vs streamable classes

### Examples Of Issues This Layer Must Prevent

- root form events that are not stream-safe
- VCL-only designer properties such as `DesignSize`
- old buffering or style properties
- incompatible image or shape stream properties

## Phase 6: Parser Integration

### DFM Parser Must Be Driven By Matrix

For every property/event encountered:

1. resolve source VCL class
2. resolve target FMX class
3. consult matrix
4. choose one of:
   - emit directly
   - emit renamed
   - emit transformed
   - omit silently
   - omit and report
   - flag blocking/manual

### Parser Output Must Include

- source line numbers
- offending property/event text
- exact reason for omission or review
- recommendation text from the matrix

## Phase 7: Pascal Runtime/Behavior Layer

This is separate from the `.dfm/.fmx` problem.

A large part of hard-project conversion quality depends on runtime pattern translation.

### Runtime Pattern Families To Inventory

- VCL control properties used in code
- VCL image APIs
- VCL form/window APIs
- message dispatch APIs
- thread marshaling patterns
- canvas/graphics/GDI patterns
- DB-aware APIs
- dialog usage patterns
- tray/startup behaviors
- serial/COM usage patterns

### Runtime Classification

Each detected runtime pattern must be tagged as:

- auto-rewrite safe
- audit-only
- manual review
- blocking

### Examples Already Proven Important

- `TThread.Queue(nil, ...)`
- `Perform(...)`
- `Invalidate`
- `Picture`
- `Stretch`
- `Proportional`
- `BorderStyle := bs...`
- `WindowState := ws...`
- direct `Color :=`
- integer `div` on FMX floating-point size values

### Required Output Artifacts

- `pascal_runtime_pattern_matrix.json`
- optional:
  - `PASCAL_RUNTIME_PATTERN_MATRIX.md`

## Phase 8: Generated Output Audit Layer

After conversion, the generated files must be scanned against the matrix.

### Audit Must Cover

- generated `.pas`
- generated `.fmx`
- generated `.dpr`
- generated `.dproj` when useful

### Audit Must Report

- file
- line number
- offending line
- issue family
- severity
- recommendation

### Audit Must Group Repeated Issues

Repeated findings should be grouped by issue family, with:

- occurrence count
- affected file/line list
- one shared recommendation

## Phase 9: Report Model

The report should be driven from the matrix and audit layers.

### Report Must Distinguish

- informational
- warnings
- manual review
- blocking

### Final Status Values

- `Clean Conversion`
- `Conversion With Manual Review`
- `Partial Conversion - Blocking Items Present`

### Report Must Include

- summary counts
- grouped manual-review items
- offending file/line/code
- recommendation text
- clear note that generated output may still need IDE/manual fixes

## Phase 10: Regression Corpus

Project migrations should be used for regression only.

### Maintain A Standard Corpus

- one very simple forms app
- one medium forms app
- one custom-paint app
- one tray/startup app
- one DB-aware app
- one serial/COM app
- one media/audio app

### Known Good Reference Projects

- Morse Trainer
- SVG Button Maker
- GPS Control / GPSTimeSync
- RealTimeClock
- one schedule/media reference app

### Regression Requirements

For each corpus project, store:

- expected report status
- expected manual-review categories
- known blocking items
- known open/build/run expectations

## Phase 11: Release Gating

Do not promote beyond beta until:

- standard class/property/event matrix is substantially filled out
- report accuracy is trusted across the corpus
- generated output audit catches the major leftover Pascal families
- no false `Clean Conversion` reports remain for known-problem projects

## Immediate Later Priorities

When work resumes later, the next best order is:

1. export and persist the VCL/FM X RTTI inventories
2. make class/property/event matrix files explicit artifacts
3. drive parser decisions from those matrix files
4. expand Pascal runtime pattern families
5. use the regression corpus to verify expected report outcomes

## Bottom Line

The future effort should not be:

- "fix whatever next project breaks"

It should be:

- inventory
- classify
- map
- validate
- audit
- regress

That is the path from a reactive converter to a real migration assistant.
