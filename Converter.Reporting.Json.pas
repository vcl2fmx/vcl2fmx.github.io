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
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('schemaVersion', 'vcl2fmx.report.v1');
    Root.AddPair('status', AModel.StatusText);
    Root.AddPair('nextStep', AModel.NextStepText);
    Root.AddPair('sourcePath', AModel.SourcePath);
    Root.AddPair('outputPath', AModel.OutputPath);
    Root.AddPair('runTime', AModel.RunTimeText);

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
      Issues.AddElement(IssueObject);
    end;
    Root.AddPair('issues', Issues);

    TFile.WriteAllText(AModel.JsonReportFile, Root.ToJSON,
      TEncoding.UTF8);
  finally
    Root.Free;
  end;
end;

end.
