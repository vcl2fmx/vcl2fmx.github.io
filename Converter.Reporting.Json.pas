{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v6.0 Navigator
 Written and built in the USA}

unit Converter.Reporting.Json;

interface

uses
  Converter.Reporting.Model;

type
  TConversionJsonReportRenderer = class
  public
    class procedure Save(const AModel: TConversionReportModel); static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON;

class procedure TConversionJsonReportRenderer.Save(
  const AModel: TConversionReportModel);
var
  Root: TJSONObject;
  Summary: TJSONObject;
  Risks: TJSONObject;
  Issues: TJSONArray;
  IssueObject: TJSONObject;
  Issue: TConversionReportIssue;
  ManualGroups: TJSONArray;
  ManualGroupObject: TJSONObject;
  ManualGroup: TConversionReportManualGroup;
  MappingPacks: TJSONArray;
  MappingPack: string;
  MappingUsages: TJSONArray;
  MappingUsageObject: TJSONObject;
  MappingUsage: TConversionReportMappingUsage;
  ConversionLog: TJSONArray;
  ConversionLogLine: string;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('schemaVersion', 'vcl2fmx.report.v1');
    Root.AddPair('status', AModel.StatusText);
    Root.AddPair('nextStep', AModel.NextStepText);
    Root.AddPair('sourcePath', AModel.SourcePath);
    Root.AddPair('outputPath', AModel.OutputPath);
    Root.AddPair('runTime', AModel.RunTimeText);
    Root.AddPair('issueCollection', 'raw');

    Summary := TJSONObject.Create;
    Summary.AddPair('filesProcessed', TJSONNumber.Create(AModel.FilesProcessed));
    Summary.AddPair('filesConverted', TJSONNumber.Create(AModel.FilesConverted));
    Summary.AddPair('filesWithErrors', TJSONNumber.Create(AModel.FilesWithErrors));
    Summary.AddPair('filesSkipped', TJSONNumber.Create(AModel.FilesSkipped));
    Summary.AddPair('mappingPacksLoaded', TJSONNumber.Create(AModel.MappingPacksLoaded));
    Summary.AddPair('informational', TJSONNumber.Create(AModel.InformationalCount));
    Summary.AddPair('warnings', TJSONNumber.Create(AModel.WarningCount));
    Summary.AddPair('manualReviewItems', TJSONNumber.Create(AModel.ManualIssueCount));
    Summary.AddPair('manualReviewGroups', TJSONNumber.Create(AModel.ManualGroupCount));
    Summary.AddPair('errors', TJSONNumber.Create(AModel.ErrorCount));
    Summary.AddPair('blockingItems', TJSONNumber.Create(AModel.BlockingCount));
    Summary.AddPair('visibleIssues', TJSONNumber.Create(AModel.VisibleIssueCount));
    Summary.AddPair('affectedFiles', TJSONNumber.Create(AModel.AffectedFileCount));
    Root.AddPair('summary', Summary);

    Risks := TJSONObject.Create;
    Risks.AddPair('blockingOutcome', TJSONBool.Create(AModel.HasBlockingOutcome));
    Risks.AddPair('runtimeReview', TJSONBool.Create(AModel.NeedsRuntimeReview));
    Risks.AddPair('visualReview', TJSONBool.Create(AModel.NeedsVisualReview));
    Risks.AddPair('dataBindingReview', TJSONBool.Create(AModel.NeedsDataBindingReview));
    Risks.AddPair('manualCodeReview', TJSONBool.Create(AModel.NeedsManualCodeReview));
    Root.AddPair('risks', Risks);

    Issues := TJSONArray.Create;
    for Issue in AModel.Issues do
    begin
      IssueObject := TJSONObject.Create;
      IssueObject.AddPair('stableIdentity', Issue.StableIdentity);
      IssueObject.AddPair('severity', Issue.SeverityText);
      IssueObject.AddPair('category', Issue.Category);
      IssueObject.AddPair('problemType', Issue.ProblemType);
      IssueObject.AddPair('message', Issue.MessageText);
      IssueObject.AddPair('sourceFile', Issue.SourceFile);
      IssueObject.AddPair('sourceStartLine',
        TJSONNumber.Create(Issue.SourceStartLine));
      IssueObject.AddPair('sourceEndLine',
        TJSONNumber.Create(Issue.SourceEndLine));
      IssueObject.AddPair('originalEvidence', Issue.OriginalEvidence);
      IssueObject.AddPair('recommendedAction', Issue.RecommendedAction);
      IssueObject.AddPair('blocking', TJSONBool.Create(Issue.IsBlocking));
      IssueObject.AddPair('includeInDetailedIssues',
        TJSONBool.Create(Issue.IncludeInDetailedIssues));
      IssueObject.AddPair('dryRunPreview',
        TJSONBool.Create(Issue.IsDryRunPreview));
      IssueObject.AddPair('actionableInformation',
        TJSONBool.Create(Issue.IsActionableInfo));
      Issues.AddElement(IssueObject);
    end;
    Root.AddPair('issues', Issues);

    ManualGroups := TJSONArray.Create;
    for ManualGroup in AModel.ManualGroups do
    begin
      ManualGroupObject := TJSONObject.Create;
      ManualGroupObject.AddPair('title', ManualGroup.Title);
      ManualGroupObject.AddPair('riskCategory', ManualGroup.RiskCategory);
      ManualGroupObject.AddPair('occurrenceCount',
        TJSONNumber.Create(ManualGroup.OccurrenceCount));
      ManualGroupObject.AddPair('affectedLineCount',
        TJSONNumber.Create(ManualGroup.AffectedLineCount));
      ManualGroupObject.AddPair('detail', ManualGroup.DetailText);
      ManualGroupObject.AddPair('affectedLocations',
        ManualGroup.AffectedLocations);
      ManualGroupObject.AddPair('recommendedSolution',
        ManualGroup.RecommendedSolution);
      ManualGroupObject.AddPair('blocking',
        TJSONBool.Create(ManualGroup.IsBlocking));
      ManualGroups.AddElement(ManualGroupObject);
    end;
    Root.AddPair('manualGroups', ManualGroups);

    MappingPacks := TJSONArray.Create;
    for MappingPack in AModel.MappingPacks do
      MappingPacks.AddElement(TJSONString.Create(MappingPack));
    Root.AddPair('mappingPacks', MappingPacks);

    MappingUsages := TJSONArray.Create;
    for MappingUsage in AModel.MappingUsages do
    begin
      MappingUsageObject := TJSONObject.Create;
      MappingUsageObject.AddPair('componentName', MappingUsage.ComponentName);
      MappingUsageObject.AddPair('vclClassName', MappingUsage.VCLClassName);
      MappingUsageObject.AddPair('fmxClassName', MappingUsage.FMXClassName);
      MappingUsageObject.AddPair('action', MappingUsage.Action);
      MappingUsageObject.AddPair('confidence',
        TJSONNumber.Create(MappingUsage.Confidence));
      MappingUsageObject.AddPair('vendor', MappingUsage.Vendor);
      MappingUsageObject.AddPair('packName', MappingUsage.PackName);
      MappingUsageObject.AddPair('sourceFile', MappingUsage.SourceFile);
      MappingUsageObject.AddPair('lineNumber',
        TJSONNumber.Create(MappingUsage.LineNumber));
      MappingUsageObject.AddPair('notes', MappingUsage.Notes);
      MappingUsageObject.AddPair('generatedOutput',
        TJSONBool.Create(MappingUsage.GeneratedOutput));
      MappingUsages.AddElement(MappingUsageObject);
    end;
    Root.AddPair('mappingUsages', MappingUsages);

    ConversionLog := TJSONArray.Create;
    for ConversionLogLine in AModel.ConversionLogLines do
      ConversionLog.AddElement(TJSONString.Create(ConversionLogLine));
    Root.AddPair('conversionLog', ConversionLog);

    TFile.WriteAllText(AModel.JsonReportFile, Root.ToJSON,
      TEncoding.UTF8);
  finally
    Root.Free;
  end;
end;

end.
