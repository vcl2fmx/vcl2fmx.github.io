{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v6.0 Navigator
 Written and built in the USA}

unit Converter.Reporting.Model;

interface

uses
  Converter.Core.Types;

type
  TConversionReportIssue = record
    StableIdentity: string;
    Severity: TConversionSeverity;
    Category: string;
    ProblemType: string;
    MessageText: string;
    SourceFile: string;
    SourceStartLine: Integer;
    SourceEndLine: Integer;
    OriginalEvidence: string;
    RecommendedAction: string;
    IsBlocking: Boolean;
    IncludeInDetailedIssues: Boolean;
    IsDryRunPreview: Boolean;
    IsActionableInfo: Boolean;
    SeverityText: string;
    class function Create(const AIssue: TConversionIssue;
      const ACategory, AStableIdentity: string): TConversionReportIssue; static;
  end;

  TConversionReportManualGroup = record
    Title: string;
    RiskCategory: string;
    OccurrenceCount: Integer;
    AffectedLineCount: Integer;
    DetailText: string;
    AffectedLocations: string;
    RecommendedSolution: string;
    IsBlocking: Boolean;
  end;

  TConversionReportMappingUsage = record
    ComponentName: string;
    VCLClassName: string;
    FMXClassName: string;
    Action: string;
    Confidence: Integer;
    Vendor: string;
    PackName: string;
    SourceFile: string;
    LineNumber: Integer;
    Notes: string;
    GeneratedOutput: Boolean;
    class function Create(const AUsage: TMappingPackUsage):
      TConversionReportMappingUsage; static;
  end;

  TConversionReportModel = record
    SourcePath: string;
    OutputPath: string;
    TextReportFile: string;
    HtmlReportFile: string;
    JsonReportFile: string;
    RunTimeText: string;
    StatusText: string;
    NextStepText: string;
    FilesProcessed: Integer;
    FilesConverted: Integer;
    FilesWithErrors: Integer;
    FilesSkipped: Integer;
    MappingPacksLoaded: Integer;
    InformationalCount: Integer;
    WarningCount: Integer;
    ManualIssueCount: Integer;
    ManualGroupCount: Integer;
    ErrorCount: Integer;
    BlockingCount: Integer;
    DryRunPreviewCount: Integer;
    VisibleIssueCount: Integer;
    AffectedFileCount: Integer;
    HasBlockingOutcome: Boolean;
    NeedsRuntimeReview: Boolean;
    NeedsVisualReview: Boolean;
    NeedsDataBindingReview: Boolean;
    NeedsManualCodeReview: Boolean;
    Issues: TArray<TConversionReportIssue>;
    ManualGroups: TArray<TConversionReportManualGroup>;
    MappingPacks: TArray<string>;
    MappingUsages: TArray<TConversionReportMappingUsage>;
    ConversionLogLines: TArray<string>;
  end;

implementation

class function TConversionReportIssue.Create(const AIssue: TConversionIssue;
  const ACategory, AStableIdentity: string): TConversionReportIssue;
begin
  Result := Default(TConversionReportIssue);
  Result.StableIdentity := AStableIdentity;
  Result.Severity := AIssue.Severity;
  Result.Category := ACategory;
  Result.ProblemType := AIssue.ProblemType;
  Result.MessageText := AIssue.Message;
  Result.SourceFile := AIssue.FileName;
  Result.SourceStartLine := AIssue.LineNumber;
  Result.SourceEndLine := AIssue.LineNumber;
  Result.OriginalEvidence := AIssue.OriginalCode;
  Result.RecommendedAction := AIssue.SuggestedFix;
  Result.IsBlocking := AIssue.IsBlocking;
end;

class function TConversionReportMappingUsage.Create(
  const AUsage: TMappingPackUsage): TConversionReportMappingUsage;
begin
  Result := Default(TConversionReportMappingUsage);
  Result.ComponentName := AUsage.ComponentName;
  Result.VCLClassName := AUsage.VCLClassName;
  Result.FMXClassName := AUsage.FMXClassName;
  Result.Action := AUsage.Action;
  Result.Confidence := AUsage.Confidence;
  Result.Vendor := AUsage.Vendor;
  Result.PackName := AUsage.PackName;
  Result.SourceFile := AUsage.SourceFile;
  Result.LineNumber := AUsage.LineNumber;
  Result.Notes := AUsage.Notes;
  Result.GeneratedOutput := AUsage.GeneratedOutput;
end;

end.
