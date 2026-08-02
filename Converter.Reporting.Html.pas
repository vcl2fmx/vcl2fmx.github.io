{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v6.0 Navigator
 Written and built in the USA}

unit Converter.Reporting.Html;

interface

uses
  System.Classes,
  Converter.Reporting.Model;

type
  TConversionHtmlReportRenderer = class
  public
    class procedure RenderBody(const AModel: TConversionReportModel;
      const AHtml: TStrings); static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.NetEncoding,
  Converter.Core.Types;

class procedure TConversionHtmlReportRenderer.RenderBody(
  const AModel: TConversionReportModel; const AHtml: TStrings);
var
  Issue: TConversionReportIssue;
  ManualGroup: TConversionReportManualGroup;
  MappingPack: string;
  MappingPackIndex: Integer;
  HasDetailedIssues: Boolean;
  ConversionLog: TStringList;

  function HtmlEncode(const Value: string): string;
  begin
    Result := TNetEncoding.HTML.Encode(Value);
  end;

  function SeverityCssClass(Severity: TConversionSeverity): string;
  begin
    case Severity of
      csInfo: Result := 'info';
      csWarning: Result := 'warning';
      csManualReview: Result := 'manual';
      csError, csCritical: Result := 'error';
    else
      Result := 'neutral';
    end;
  end;

  function UsageTargetText(
    const Usage: TConversionReportMappingUsage): string;
  begin
    if Trim(Usage.FMXClassName) <> '' then
      Result := Usage.FMXClassName
    else
      Result := 'No FMX output generated';
  end;

  function UsageLocationText(
    const Usage: TConversionReportMappingUsage): string;
  begin
    Result := Usage.SourceFile;
    if Usage.LineNumber > 0 then
      Result := Result + ':' + IntToStr(Usage.LineNumber);
  end;

  function IncludeUsage(const Usage: TConversionReportMappingUsage;
    const ActionFilter: string; GeneratedOnly, DetectOnly: Boolean): Boolean;
  begin
    Result := True;
    if ActionFilter <> '' then
      Result := SameText(Usage.Action, ActionFilter);
    if GeneratedOnly then
      Result := Result and Usage.GeneratedOutput;
    if DetectOnly then
      Result := Result and SameText(Usage.Action, 'detect_only');
  end;

  procedure AddUsageSection(const Title, Note, EmptyText, ActionFilter: string;
    GeneratedOnly, DetectOnly: Boolean);
  var
    Usage: TConversionReportMappingUsage;
    AddedAny: Boolean;
  begin
    AddedAny := False;
    for Usage in AModel.MappingUsages do
      if IncludeUsage(Usage, ActionFilter, GeneratedOnly, DetectOnly) then
      begin
        AddedAny := True;
        Break;
      end;
    if not AddedAny then
      Exit;

    AHtml.Add('    <div class="section">');
    AHtml.Add('      <h2>' + HtmlEncode(Title) + '</h2>');
    AHtml.Add('      <p class="section-note">' + HtmlEncode(Note) + '</p>');
    AHtml.Add('      <div class="usage-list">');
    AddedAny := False;
    for Usage in AModel.MappingUsages do
    begin
      if not IncludeUsage(Usage, ActionFilter, GeneratedOnly, DetectOnly) then
        Continue;
      AddedAny := True;
      AHtml.Add('        <div class="usage-card">');
      AHtml.Add('          <div class="usage-title">' +
        HtmlEncode(Usage.ComponentName) + '<span>' + HtmlEncode(Usage.Action) +
        ' | ' + IntToStr(Usage.Confidence) + '%</span></div>');
      AHtml.Add('          <div class="usage-map">' +
        HtmlEncode(Usage.VCLClassName) + ' -> ' +
        HtmlEncode(UsageTargetText(Usage)) + '</div>');
      AHtml.Add('          <div class="usage-meta">');
      if Trim(Usage.PackName) <> '' then
        AHtml.Add('            <span>Pack: ' +
          HtmlEncode(Usage.PackName) + '</span>');
      if Trim(Usage.Vendor) <> '' then
        AHtml.Add('            <span>Vendor: ' +
          HtmlEncode(Usage.Vendor) + '</span>');
      AHtml.Add('          </div>');
      if Trim(UsageLocationText(Usage)) <> '' then
        AHtml.Add('          <div class="usage-path">' +
          HtmlEncode(UsageLocationText(Usage)) + '</div>');
      if Trim(Usage.Notes) <> '' then
        AHtml.Add('          <div class="usage-notes">' +
          HtmlEncode(Usage.Notes) + '</div>');
      AHtml.Add('        </div>');
    end;
    if not AddedAny then
      AHtml.Add('        <div class="empty-state">' +
        HtmlEncode(EmptyText) + '</div>');
    AHtml.Add('      </div>');
    AHtml.Add('    </div>');
  end;

  procedure AddMappingsUsedSection;
  var
    Usage: TConversionReportMappingUsage;
  begin
    if Length(AModel.MappingUsages) = 0 then
      Exit;
    AHtml.Add('    <div class="section">');
    AHtml.Add('      <h2>Mappings used</h2>');
    AHtml.Add('      <p class="section-note">Compact list of mapping-pack rules that fired during this conversion run.</p>');
    AHtml.Add('      <div class="compact-list">');
    for Usage in AModel.MappingUsages do
      AHtml.Add('        <div>' +
        HtmlEncode(Format('%s: %s -> %s (%s, %d%%)',
          [Usage.ComponentName, Usage.VCLClassName, UsageTargetText(Usage),
           Usage.Action, Usage.Confidence])) + '</div>');
    AHtml.Add('      </div>');
    AHtml.Add('    </div>');
  end;

begin
  AHtml.Add('<body>');
  AHtml.Add('  <div class="page">');
  AHtml.Add('    <div class="hero">');
  AHtml.Add('      <div class="eyebrow">VCL to FMX Converter</div>');
  AHtml.Add('      <h1>Conversion Report</h1>');
  AHtml.Add('      <p>' + HtmlEncode(Format('Generated %s',
    [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)])) + '</p>');
  AHtml.Add('      <p>' + HtmlEncode('Source: ' + AModel.SourcePath) + '<br>' +
    HtmlEncode('Output: ' + AModel.OutputPath) + '</p>');
  AHtml.Add('      <div class="status-chip">' +
    HtmlEncode(AModel.StatusText) + '</div>');
  AHtml.Add('      <p>' +
    HtmlEncode('Next step: ' + AModel.NextStepText) + '</p>');
  AHtml.Add('    </div>');
  AHtml.Add('    <div class="meta">');
  AHtml.Add('      <div class="meta-card"><div class="label">Files processed</div><div class="value">' +
    IntToStr(AModel.FilesProcessed) + '</div></div>');
  AHtml.Add('      <div class="meta-card"><div class="label">Files converted</div><div class="value">' +
    IntToStr(AModel.FilesConverted) + '</div></div>');
  AHtml.Add('      <div class="meta-card"><div class="label">Distinct files needing attention</div><div class="value">' +
    IntToStr(AModel.AffectedFileCount) + '</div></div>');
  AHtml.Add('      <div class="meta-card"><div class="label">Manual review items</div><div class="value">' +
    IntToStr(AModel.ManualIssueCount) + '</div></div>');
  AHtml.Add('      <div class="meta-card"><div class="label">Blocking items</div><div class="value">' +
    IntToStr(AModel.BlockingCount) + '</div></div>');
  AHtml.Add('      <div class="meta-card"><div class="label">Files with errors</div><div class="value">' +
    IntToStr(AModel.FilesWithErrors) + '</div></div>');
  AHtml.Add('      <div class="meta-card"><div class="label">Warnings</div><div class="value">' +
    IntToStr(AModel.WarningCount) + '</div></div>');
  AHtml.Add('      <div class="meta-card"><div class="label">Errors</div><div class="value">' +
    IntToStr(AModel.ErrorCount) + '</div></div>');
  AHtml.Add('      <div class="meta-card"><div class="label">Total issues</div><div class="value">' +
    IntToStr(AModel.VisibleIssueCount) + '</div></div>');
  if AModel.InformationalCount > 0 then
    AHtml.Add('      <div class="meta-card"><div class="label">Informational notices</div><div class="value">' +
      IntToStr(AModel.InformationalCount) + '</div></div>');
  if AModel.DryRunPreviewCount > 0 then
    AHtml.Add('      <div class="meta-card"><div class="label">Dry-run notices</div><div class="value">' +
      IntToStr(AModel.DryRunPreviewCount) + '</div></div>');
  AHtml.Add('      <div class="meta-card"><div class="label">Mapping packs loaded</div><div class="value">' +
    IntToStr(AModel.MappingPacksLoaded) + '</div></div>');
  AHtml.Add('      <div class="meta-card"><div class="label">Run time</div><div class="value">' +
    HtmlEncode(AModel.RunTimeText) + '</div></div>');
  AHtml.Add('    </div>');

  AHtml.Add('    <div class="section">');
  AHtml.Add('      <h2>Conversion health</h2>');
  AHtml.Add('      <p class="section-note">Risk categories summarize what kind of review the generated project still needs.</p>');
  AHtml.Add('      <table><tbody>');
  if AModel.HasBlockingOutcome then
    AHtml.Add('        <tr><th>Compile readiness</th><td>Blocked until conversion errors or blocking items are resolved.</td></tr>')
  else if AModel.ManualGroupCount > 0 then
    AHtml.Add('        <tr><th>Compile readiness</th><td>Possible, but manual-review items may still block reliable behavior.</td></tr>')
  else
    AHtml.Add('        <tr><th>Compile readiness</th><td>No blocking or manual-review categories were detected by the converter.</td></tr>');
  AHtml.Add('        <tr><th>Runtime behavior review</th><td>' +
    IfThen(AModel.NeedsRuntimeReview, 'Yes', 'No') + '</td></tr>');
  AHtml.Add('        <tr><th>Visual review</th><td>' +
    IfThen(AModel.NeedsVisualReview, 'Yes', 'No') + '</td></tr>');
  AHtml.Add('        <tr><th>Data binding review</th><td>' +
    IfThen(AModel.NeedsDataBindingReview, 'Yes', 'No') + '</td></tr>');
  AHtml.Add('        <tr><th>Manual code review</th><td>' +
    IfThen(AModel.NeedsManualCodeReview, 'Yes', 'No') + '</td></tr>');
  AHtml.Add('      </tbody></table>');
  AHtml.Add('    </div>');

  AHtml.Add('    <div class="section">');
  AHtml.Add('      <h2>Output files</h2>');
  AHtml.Add('      <p class="section-note">Files and folders produced or updated by this conversion run.</p>');
  AHtml.Add('      <table class="issues-table">');
  AHtml.Add('        <tbody>');
  AHtml.Add('          <tr><th>Output folder</th><td>' +
    HtmlEncode(AModel.OutputPath) + '</td></tr>');
  AHtml.Add('          <tr><th>Text report</th><td>' +
    HtmlEncode(AModel.TextReportFile) + '</td></tr>');
  AHtml.Add('          <tr><th>HTML report</th><td>' +
    HtmlEncode(AModel.HtmlReportFile) + '</td></tr>');
  AHtml.Add('          <tr><th>Converted source files</th><td>Generated Pascal and FMX files are written beside converted source names in the output folder.</td></tr>');
  AHtml.Add('        </tbody>');
  AHtml.Add('      </table>');
  AHtml.Add('    </div>');

  AHtml.Add('    <details class="section disclosure">');
  AHtml.Add('      <summary><h2>Mapping packs loaded (' +
    IntToStr(AModel.MappingPacksLoaded) +
    ')</h2><span>Show/hide loaded packs</span></summary>');
  AHtml.Add('      <p class="section-note">External mapping packs loaded for this conversion run.</p>');
  AHtml.Add('      <div class="mapping-pack-list">');
  if Length(AModel.MappingPacks) = 0 then
    AHtml.Add('        <div class="mapping-pack-row"><div class="mapping-pack-text">No mapping packs were loaded for this run.</div></div>')
  else
  begin
    MappingPackIndex := 0;
    for MappingPack in AModel.MappingPacks do
    begin
      Inc(MappingPackIndex);
      AHtml.Add('        <div class="mapping-pack-row"><div class="mapping-pack-index">' +
        IntToStr(MappingPackIndex) +
        '</div><div class="mapping-pack-text">' +
        HtmlEncode(MappingPack) + '</div></div>');
    end;
  end;
  AHtml.Add('      </div>');
  AHtml.Add('    </details>');

  AddUsageSection('Third-party components converted',
    'Mapping-pack components that generated FMX output with a convert action.',
    'No third-party mapping-pack components were fully converted.',
    'convert', True, False);
  AddUsageSection('Third-party components partially converted',
    'Mapping-pack components that generated FMX output but still require review.',
    'No third-party mapping-pack components were partially converted.',
    'partial', True, False);
  AddUsageSection('Third-party components detected only',
    'Mapping-pack components intentionally reported without generated FMX output.',
    'No detect-only third-party mapping-pack components were found.',
    'detect_only', False, True);
  AddMappingsUsedSection;

  if AModel.DryRunPreviewCount > 0 then
  begin
    AHtml.Add('    <details class="section disclosure">');
    AHtml.Add('      <summary><h2>Dry-run preview (' +
      IntToStr(AModel.DryRunPreviewCount) +
      ')</h2><span>Show/hide preview notices</span></summary>');
    AHtml.Add('      <p class="section-note">Preview mode did not write converted source, form, or project files. These notices are not counted as conversion issues.</p>');
    AHtml.Add('      <div class="compact-list">');
    for Issue in AModel.Issues do
      if Issue.IsDryRunPreview then
        AHtml.Add('        <div>' + HtmlEncode(Issue.MessageText) + '</div>');
    AHtml.Add('      </div>');
    AHtml.Add('    </details>');
  end;

  AHtml.Add('    <div class="section">');
  AHtml.Add('      <h2>Detailed issues</h2>');
  AHtml.Add('      <p class="section-note">Warnings and errors are listed below. Informational run details stay in the text report and conversion log.</p>');
  AHtml.Add('      <div class="issue-list">');
  HasDetailedIssues := False;
  for Issue in AModel.Issues do
  begin
    if not Issue.IncludeInDetailedIssues or
       (Issue.Severity = csInfo) then
      Continue;
    HasDetailedIssues := True;
    AHtml.Add('        <div class="issue-card">');
    AHtml.Add('          <div class="issue-card-header"><span class="severity ' +
      SeverityCssClass(Issue.Severity) + '">' +
      HtmlEncode(Issue.SeverityText) + '</span><strong>' +
      HtmlEncode(IfThen(Issue.ProblemType <> '', Issue.ProblemType,
        Issue.Category)) + '</strong><span class="meta">' +
      HtmlEncode(Issue.Category) + '</span>' +
      IfThen(Issue.SourceStartLine > 0,
        '<span class="meta">Line ' +
        IntToStr(Issue.SourceStartLine) + '</span>', '') + '</div>');
    AHtml.Add('          <div class="issue-message">' +
      HtmlEncode(Issue.MessageText) + '</div>');
    if Trim(Issue.SourceFile) <> '' then
      AHtml.Add('          <div class="issue-path">' +
        HtmlEncode(Issue.SourceFile) + '</div>');
    if Trim(Issue.RecommendedAction) <> '' then
      AHtml.Add('          <div class="issue-fix">' +
        HtmlEncode(Issue.RecommendedAction) + '</div>');
    AHtml.Add('        </div>');
  end;
  if not HasDetailedIssues then
    AHtml.Add('        <div class="empty-state">No warning or error items were recorded outside the grouped manual-review section.</div>');
  AHtml.Add('      </div>');
  AHtml.Add('    </div>');

  AHtml.Add('    <div class="section">');
  AHtml.Add('      <h2>Manual review items</h2>');
  AHtml.Add('      <p class="section-note">These items usually require an IDE review or a deliberate FMX design decision before the converted output is production-ready.<br><strong style="color:#174f8f;">Click the &gt; arrow on each item to view affected locations and recommended fixes.</strong></p>');
  AHtml.Add('      <div class="manual-list">');
  if AModel.ManualGroupCount = 0 then
    AHtml.Add('        <div class="manual-card">No grouped manual-review items were recorded.</div>')
  else
  begin
    MappingPackIndex := 0;
    for ManualGroup in AModel.ManualGroups do
    begin
      Inc(MappingPackIndex);
      AHtml.Add('        <div class="manual-card">');
      AHtml.Add('          <h3>' +
        HtmlEncode(Format('%d. %s',
          [MappingPackIndex, ManualGroup.Title])) + '</h3>');
      AHtml.Add('          <div class="manual-meta">');
      AHtml.Add('            <span>Occurrences: ' +
        IntToStr(ManualGroup.OccurrenceCount) + '</span>');
      if ManualGroup.AffectedLineCount > ManualGroup.OccurrenceCount then
        AHtml.Add('            <span>Affected lines: ' +
          IntToStr(ManualGroup.AffectedLineCount) + '</span>');
      if ManualGroup.IsBlocking then
        AHtml.Add('            <span>Blocking: Yes</span>');
      AHtml.Add('            <span>Risk: ' +
        HtmlEncode(ManualGroup.RiskCategory) + '</span>');
      AHtml.Add('          </div>');
      AHtml.Add('          <p><strong>Detail:</strong> ' +
        HtmlEncode(ManualGroup.DetailText) + '</p>');
      AHtml.Add('          <details class="block">');
      AHtml.Add('            <summary class="block-label">Affected locations</summary>');
      AHtml.Add('            <div class="pre">' +
        HtmlEncode(ManualGroup.AffectedLocations) + '</div>');
      AHtml.Add('          </details>');
      AHtml.Add('          <div class="block">');
      AHtml.Add('            <div class="block-label">Recommended solution</div>');
      AHtml.Add('            <div class="pre">' +
        HtmlEncode(ManualGroup.RecommendedSolution) + '</div>');
      AHtml.Add('          </div>');
      AHtml.Add('        </div>');
    end;
  end;
  AHtml.Add('      </div>');
  AHtml.Add('    </div>');

  if Length(AModel.ConversionLogLines) > 0 then
  begin
    ConversionLog := TStringList.Create;
    try
      ConversionLog.AddStrings(AModel.ConversionLogLines);
      AHtml.Add('    <details class="section disclosure">');
      AHtml.Add('      <summary><h2>Conversion log</h2><span>Show/hide screen log</span></summary>');
      AHtml.Add('      <p class="section-note">Screen log captured during this conversion run.</p>');
      AHtml.Add('      <div class="pre log-block">' +
        HtmlEncode(ConversionLog.Text) + '</div>');
      AHtml.Add('    </details>');
    finally
      ConversionLog.Free;
    end;
  end;

  AHtml.Add('    <div class="section">');
  AHtml.Add('      <h2>Issue summary</h2>');
  AHtml.Add('      <p class="section-note">Use this section for a quick print-friendly tally of the result.</p>');
  AHtml.Add('      <table>');
  AHtml.Add('        <tbody>');
  AHtml.Add('          <tr><th>Informational</th><td>' +
    IntToStr(AModel.InformationalCount) + '</td></tr>');
  AHtml.Add('          <tr><th>Warnings</th><td>' +
    IntToStr(AModel.WarningCount) + '</td></tr>');
  AHtml.Add('          <tr><th>Manual review required</th><td>' +
    IntToStr(AModel.ManualIssueCount) + '</td></tr>');
  AHtml.Add('          <tr><th>Manual review groups</th><td>' +
    IntToStr(AModel.ManualGroupCount) + '</td></tr>');
  AHtml.Add('          <tr><th>Errors</th><td>' +
    IntToStr(AModel.ErrorCount) + '</td></tr>');
  AHtml.Add('          <tr><th>Blocking items</th><td>' +
    IntToStr(AModel.BlockingCount) + '</td></tr>');
  AHtml.Add('          <tr><th>Distinct files needing attention</th><td>' +
    IntToStr(AModel.AffectedFileCount) + '</td></tr>');
  AHtml.Add('          <tr><th>Files with conversion errors</th><td>' +
    IntToStr(AModel.FilesWithErrors) + '</td></tr>');
  AHtml.Add('        </tbody>');
  AHtml.Add('      </table>');
  AHtml.Add('      <div class="footer-note">Next step: ' +
    HtmlEncode(AModel.NextStepText) + '</div>');
  AHtml.Add('      <div class="footer-note">Generated output should still be reviewed in the IDE. Projects with manual-review or blocking items may not run until those items are fixed or mitigated.</div>');
  AHtml.Add('    </div>');
  AHtml.Add('  </div>');
  AHtml.Add('</body>');
  AHtml.Add('</html>');
end;

end.
