{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v6.0 Navigator
 Written and built in the USA}

unit Converter.Reporting.Text;

interface

uses
  System.Classes,
  Converter.Reporting.Model;

type
  TConversionTextReportRenderer = class
  public
    class procedure Render(const AModel: TConversionReportModel;
      const AReport: TStrings); static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils;

class procedure TConversionTextReportRenderer.Render(
  const AModel: TConversionReportModel; const AReport: TStrings);
var
  Issue: TConversionReportIssue;
  ManualGroup: TConversionReportManualGroup;
  MappingPack: string;
  LogLine: string;
  UnknownThirdPartyCount: Integer;
  MappingIndex: Integer;
  ManualIndex: Integer;

  procedure AddIndentedBlock(const Header, Text: string);
  var
    Block: TStringList;
    I: Integer;
  begin
    if Trim(Text) = '' then
      Exit;
    AReport.Add(Header);
    Block := TStringList.Create;
    try
      Block.Text := StringReplace(Text, #13#10, sLineBreak, [rfReplaceAll]);
      for I := 0 to Block.Count - 1 do
        AReport.Add('  ' + Block[I]);
    finally
      Block.Free;
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

  procedure AddUsageSection(const Title, EmptyText, ActionFilter: string;
    GeneratedOnly, DetectOnly: Boolean);
  var
    Usage: TConversionReportMappingUsage;
    Index: Integer;
  begin
    AReport.Add('');
    AReport.Add(Title);
    AReport.Add(StringOfChar('-', 40));
    Index := 0;
    for Usage in AModel.MappingUsages do
    begin
      if not IncludeUsage(Usage, ActionFilter, GeneratedOnly, DetectOnly) then
        Continue;

      Inc(Index);
      AReport.Add(Format('%d. %s: %s -> %s',
        [Index, Usage.ComponentName, Usage.VCLClassName,
         UsageTargetText(Usage)]));
      AReport.Add(Format('   Action: %s  Confidence: %d%%',
        [Usage.Action, Usage.Confidence]));
      if Trim(Usage.PackName) <> '' then
        AReport.Add('   Pack: ' + Usage.PackName);
      if Trim(Usage.Vendor) <> '' then
        AReport.Add('   Vendor: ' + Usage.Vendor);
      if Trim(UsageLocationText(Usage)) <> '' then
        AReport.Add('   Location: ' + UsageLocationText(Usage));
      if Trim(Usage.Notes) <> '' then
        AReport.Add('   Notes: ' + Usage.Notes);
    end;

    if Index = 0 then
      AReport.Add(EmptyText);
  end;

  procedure AddMappingsUsedSection;
  var
    Usage: TConversionReportMappingUsage;
    Index: Integer;
  begin
    AReport.Add('');
    AReport.Add('MAPPINGS USED');
    AReport.Add(StringOfChar('-', 40));
    Index := 0;
    for Usage in AModel.MappingUsages do
    begin
      Inc(Index);
      AReport.Add(Format('%d. %s: %s -> %s (%s, %d%%)',
        [Index, Usage.ComponentName, Usage.VCLClassName,
         UsageTargetText(Usage), Usage.Action, Usage.Confidence]));
    end;
    if Index = 0 then
      AReport.Add('No mapping-pack rules were used during this run.');
  end;

begin
  AReport.Add('');
  AReport.Add(StringOfChar('=', 50));
  AReport.Add('CONVERSION SUMMARY');
  AReport.Add(StringOfChar('=', 50));
  AReport.Add('');
  AReport.Add('Total time: ' + AModel.RunTimeText);
  AReport.Add(Format('Files processed: %d', [AModel.FilesProcessed]));
  AReport.Add(Format('Files converted: %d', [AModel.FilesConverted]));
  AReport.Add(Format('Files with errors: %d', [AModel.FilesWithErrors]));
  AReport.Add(Format('Files skipped: %d', [AModel.FilesSkipped]));
  AReport.Add(Format('Mapping packs loaded: %d', [AModel.MappingPacksLoaded]));
  AReport.Add('');
  AReport.Add('OUTPUT FILES');
  AReport.Add(StringOfChar('-', 40));
  AReport.Add('Output folder: ' + AModel.OutputPath);
  AReport.Add('Text report: ' + AModel.TextReportFile);
  AReport.Add('HTML report: ' + AModel.HtmlReportFile);
  AReport.Add('JSON report: ' + AModel.JsonReportFile);
  AReport.Add('Converted Pascal files are written beside converted source names in the output folder.');
  AReport.Add('Converted FMX files are written beside converted source names in the output folder.');
  AReport.Add('');
  AReport.Add(Format('Total issues: %d', [AModel.VisibleIssueCount]));
  if AModel.InformationalCount > 0 then
    AReport.Add(Format('Informational notices: %d', [AModel.InformationalCount]));
  if AModel.DryRunPreviewCount > 0 then
    AReport.Add(Format('Dry-run preview notices: %d', [AModel.DryRunPreviewCount]));
  AReport.Add(Format('Distinct files needing attention: %d', [AModel.AffectedFileCount]));
  AReport.Add(Format('Final status: %s', [AModel.StatusText]));
  AReport.Add(Format('Manual review items: %d', [AModel.ManualIssueCount]));
  AReport.Add(Format('Manual review groups: %d', [AModel.ManualGroupCount]));
  AReport.Add(Format('Blocking items: %d', [AModel.BlockingCount]));
  AReport.Add(Format('Files with conversion errors: %d', [AModel.FilesWithErrors]));
  AReport.Add('Recommended next step: ' + AModel.NextStepText);
  AReport.Add('');
  AReport.Add('Review note: Generated output should be reviewed in the IDE. Projects with manual-review or blocking items may not run until those items are fixed or mitigated.');

  AReport.Add('');
  AReport.Add('CONVERSION HEALTH');
  AReport.Add(StringOfChar('-', 40));
  if AModel.HasBlockingOutcome then
    AReport.Add('Compile readiness: blocked until conversion errors or blocking items are resolved.')
  else if AModel.ManualGroupCount > 0 then
    AReport.Add('Compile readiness: possible, but manual-review items may still block reliable behavior.')
  else
    AReport.Add('Compile readiness: no blocking or manual-review categories were detected by the converter.');
  AReport.Add('Runtime behavior review: ' + IfThen(AModel.NeedsRuntimeReview, 'Yes', 'No'));
  AReport.Add('Visual review: ' + IfThen(AModel.NeedsVisualReview, 'Yes', 'No'));
  AReport.Add('Data binding review: ' + IfThen(AModel.NeedsDataBindingReview, 'Yes', 'No'));
  AReport.Add('Manual code review: ' + IfThen(AModel.NeedsManualCodeReview, 'Yes', 'No'));

  AReport.Add('');
  AReport.Add('MAPPING PACKS LOADED');
  AReport.Add(StringOfChar('-', 40));
  if Length(AModel.MappingPacks) = 0 then
    AReport.Add('No mapping packs were loaded for this run.')
  else
  begin
    MappingIndex := 0;
    for MappingPack in AModel.MappingPacks do
    begin
      Inc(MappingIndex);
      AReport.Add(Format('%d. %s',
        [MappingIndex, MappingPack]));
    end;
  end;

  AddUsageSection('THIRD-PARTY COMPONENTS CONVERTED',
    'No third-party mapping-pack components were fully converted.',
    'convert', True, False);
  AddUsageSection('THIRD-PARTY COMPONENTS PARTIALLY CONVERTED',
    'No third-party mapping-pack components were partially converted.',
    'partial', True, False);
  AddUsageSection('THIRD-PARTY COMPONENTS DETECTED ONLY',
    'No detect-only third-party mapping-pack components were found.',
    'detect_only', False, True);

  AReport.Add('');
  AReport.Add('UNKNOWN THIRD-PARTY COMPONENTS');
  AReport.Add(StringOfChar('-', 40));
  UnknownThirdPartyCount := 0;
  for Issue in AModel.Issues do
    if SameText(Issue.ProblemType, 'Unknown third-party component') then
    begin
      AReport.Add('- ' + Issue.MessageText);
      Inc(UnknownThirdPartyCount);
    end;
  if UnknownThirdPartyCount = 0 then
    AReport.Add('No unknown third-party components were found.');
  AddMappingsUsedSection;

  if AModel.DryRunPreviewCount > 0 then
  begin
    AReport.Add('');
    AReport.Add('DRY-RUN PREVIEW');
    AReport.Add(StringOfChar('-', 40));
    AReport.Add('Preview mode did not write converted source, form, or project files. These notices are not counted as conversion issues.');
    for Issue in AModel.Issues do
      if Issue.IsDryRunPreview then
        AReport.Add('- ' + Issue.MessageText);
  end;

  AReport.Add('');
  AReport.Add('DETAILED ISSUES');
  AReport.Add(StringOfChar('-', 40));
  for Issue in AModel.Issues do
  begin
    if not Issue.IncludeInDetailedIssues then
      Continue;
    AReport.Add(Format('[%s] %s', [Issue.SeverityText, Issue.MessageText]));
    if Issue.SourceFile <> '' then
      AReport.Add('  File: ' + Issue.SourceFile);
    if Issue.SourceStartLine > 0 then
      AReport.Add('  Line: ' + IntToStr(Issue.SourceStartLine));
    if Issue.IsBlocking then
      AReport.Add('  Blocking: Yes');
    if Issue.ProblemType <> '' then
      AReport.Add('  Problem type: ' + Issue.ProblemType);
    AReport.Add('  Risk category: ' + Issue.Category);
    if Trim(Issue.OriginalEvidence) <> '' then
      AReport.Add('  Original: ' + StringReplace(
        Trim(Issue.OriginalEvidence), sLineBreak, ' | ', [rfReplaceAll]));
    if Issue.RecommendedAction <> '' then
      AReport.Add('  Recommendation: ' + Issue.RecommendedAction);
    AReport.Add('');
  end;

  if AModel.ManualGroupCount > 0 then
  begin
    AReport.Add('MANUAL REVIEW ITEMS');
    AReport.Add(StringOfChar('-', 40));
    AReport.Add('');
    ManualIndex := 0;
    for ManualGroup in AModel.ManualGroups do
    begin
      Inc(ManualIndex);
      AReport.Add(Format('%d. %s',
        [ManualIndex, ManualGroup.Title]));
      if ManualGroup.IsBlocking then
        AReport.Add('Blocking: Yes');
      AReport.Add('Risk category: ' + ManualGroup.RiskCategory);
      AReport.Add('Occurrences: ' + IntToStr(ManualGroup.OccurrenceCount));
      if ManualGroup.AffectedLineCount > ManualGroup.OccurrenceCount then
        AReport.Add('Affected lines: ' + IntToStr(ManualGroup.AffectedLineCount));
      AReport.Add('Detail: ' + ManualGroup.DetailText);
      AddIndentedBlock('Affected locations:', ManualGroup.AffectedLocations);
      AddIndentedBlock('Recommended solution:', ManualGroup.RecommendedSolution);
      AReport.Add('');
    end;
  end;

  AReport.Add('');
  AReport.Add('ISSUE SUMMARY');
  AReport.Add(StringOfChar('-', 30));
  AReport.Add(Format('Informational: %d', [AModel.InformationalCount]));
  AReport.Add(Format('Warnings: %d', [AModel.WarningCount]));
  AReport.Add(Format('Manual review required: %d', [AModel.ManualGroupCount]));
  AReport.Add(Format('Errors: %d', [AModel.ErrorCount]));
  AReport.Add(Format('Blocking items: %d', [AModel.BlockingCount]));

  if Length(AModel.ConversionLogLines) > 0 then
  begin
    AReport.Add('');
    AReport.Add('CONVERSION LOG');
    AReport.Add(StringOfChar('-', 80));
    for LogLine in AModel.ConversionLogLines do
      AReport.Add(LogLine);
  end;
end;

end.
