{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
Version v7.0 Atlas Build 001
 Written and built in the USA}

unit MainForm;

interface

{$IFNDEF MSWINDOWS}
  {$MESSAGE FATAL 'VCL2FMXConverter v7.0 Atlas desktop UI is currently supported only on Windows.'}
{$ENDIF}

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.IOUtils,
  System.NetEncoding,
  System.Variants,
  System.Threading,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Memo,
  FMX.Edit,
  FMX.ListBox,
  FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.TabControl,
  FMX.Objects,
  FMX.WebBrowser,
  FMX.Controls.Presentation,
  FMX.DialogService,
  IdHTTPServer,
  IdCustomHTTPServer,
  IdContext,
  DAT.Components.Core,
  DAT.Runtime.Manager,
  DAT.Components.FMX,
  DAT.Components.FMX.LanguageSelector,
  Converter.Core.Types,
  Converter.Mapper.Component,
  Converter.Core.Engine;

type
  TConversionCompletionSnapshot = record
    TargetPath: string;
    StatusText: string;
    FilesProcessed: Integer;
    FilesConverted: Integer;
    FilesWithErrors: Integer;
    FilesSkipped: Integer;
    ManualReviewCount: Integer;
    BlockingCount: Integer;
    RunDurationText: string;
    TextReportPath: string;
    HtmlReportPath: string;
  end;

  TfrmMain = class(TForm)
    HelpServer: TIdHTTPServer;
    DATLanguageManager: TDATFMXLanguageManager;
    lblLanguage: TLabel;
    cmbLanguage: TDATFMXLanguageComboBox;
    RootLayout: TLayout;
    SourcePathRow: TLayout;
    TargetPathRow: TLayout;
    ProjectOptionsRow: TLayout;
    HeroCard: TRectangle;
    HeroArtworkLayer: TLayout;
    HeroAccentRibbonLarge: TRectangle;
    HeroAccentRibbonMid: TRectangle;
    HeroAccentRibbonSmall: TRectangle;
    HeroAtlasLayout: TLayout;
    HeroAtlasGhost: TLabel;
    HeroVersionBadge: TRectangle;
    TabNavBar: TLayout;
    TabButtonDashboard: TRectangle;
    lblTabDashboard: TLabel;
    TabButtonProjectScan: TRectangle;
    lblTabProjectScan: TLabel;
    TabButtonComponentMap: TRectangle;
    lblTabComponentMap: TLabel;
    TabButtonPropertyMap: TRectangle;
    lblTabPropertyMap: TLabel;
    TabButtonEventMap: TRectangle;
    lblTabEventMap: TLabel;
    TabButtonIssues: TRectangle;
    lblTabIssues: TLabel;
    TabButtonRules: TRectangle;
    lblTabRules: TLabel;
    btnCloseApp: TRectangle;
    lblCloseApp: TLabel;
    lblHeader: TLabel;
    lblSubHeader: TLabel;
    lblVersion: TLabel;
    lblStatusCaption: TLabel;
    lblStatusValue: TLabel;
    btnConvert: TButton;
    btnReset: TButton;
    btnOpenReport: TButton;
    btnPrintReport: TButton;
    btnHelp: TButton;
    TabControlMain: TTabControl;
    tabDashboard: TTabItem;
    tabProjectScan: TTabItem;
    tabComponentMap: TTabItem;
    tabPropertyMap: TTabItem;
    tabEventMap: TTabItem;
    tabIssues: TTabItem;
    tabRules: TTabItem;
    DashboardScrollBox: TVertScrollBox;
    ProjectScanScrollBox: TVertScrollBox;
    ComponentMapScrollBox: TVertScrollBox;
    PropertyMapScrollBox: TVertScrollBox;
    EventMapScrollBox: TVertScrollBox;
    IssuesScrollBox: TVertScrollBox;
    RulesScrollBox: TVertScrollBox;
    RulesSummaryScrollBox: TVertScrollBox;
    DashboardStatusCard: TRectangle;
    lblDashboardStatusTitle: TLabel;
    lblDashboardStatusValue: TLabel;
    lblDashboardOutputTitle: TLabel;
    lblDashboardOutputValue: TLabel;
    lblDashboardReportTitle: TLabel;
    lblDashboardReportValue: TLabel;
    DashboardModulesCard: TRectangle;
    lblDashboardModulesTitle: TLabel;
    lblDashboardModulesValue: TLabel;
    DashboardNextCard: TRectangle;
    lblDashboardNextTitle: TLabel;
    lblDashboardNextBody: TLabel;
    ProjectCard: TRectangle;
    lblProjectTitle: TLabel;
    lblProjectHint: TLabel;
    lblSourceCaption: TLabel;
    edtSource: TEdit;
    btnBrowseSource: TButton;
    lblTargetCaption: TLabel;
    edtTarget: TEdit;
    btnBrowseTarget: TButton;
    lblFileTypeCaption: TLabel;
    cmbFileTypes: TComboBox;
    chkRecursive: TCheckBox;
    chkDryRunPreview: TCheckBox;
    ProjectActionCard: TRectangle;
    lblProjectActionTitle: TLabel;
    lblProjectActionBody: TLabel;
    btnOpenOutput: TButton;
    ComponentCard: TRectangle;
    lblComponentTitle: TLabel;
    lblComponentHint: TLabel;
    MemoComponentMap: TMemo;
    ComponentMapBrowser: TWebBrowser;
    PropertyCard: TRectangle;
    lblPropertyTitle: TLabel;
    lblPropertyHint: TLabel;
    MemoPropertyMap: TMemo;
    PropertyMapBrowser: TWebBrowser;
    EventCard: TRectangle;
    lblEventTitle: TLabel;
    lblEventHint: TLabel;
    MemoEventMap: TMemo;
    EventMapBrowser: TWebBrowser;
    IssuesSummaryCard: TRectangle;
    lblIssuesSummaryTitle: TLabel;
    lblIssuesSummaryHint: TLabel;
    lblIssuesReportTitle: TLabel;
    lblIssuesReportValue: TLabel;
    lblIssuesOutputTitle: TLabel;
    lblIssuesOutputValue: TLabel;
    IssuesLogCard: TRectangle;
    lblLogTitle: TLabel;
    lblLogHint: TLabel;
    MemoLog: TMemo;
    RulesCard: TRectangle;
    lblRulesTitle: TLabel;
    lblRulesHint: TLabel;
    chkCritical: TCheckBox;
    lblCriticalHint: TLabel;
    chkDataAware: TCheckBox;
    lblDataAwareHint: TLabel;
    chkThirdParty: TCheckBox;
    lblThirdPartyHint: TLabel;
    chkWinAPI: TCheckBox;
    lblWinAPIHint: TLabel;
    RulesSummaryCard: TRectangle;
    lblRulesSummaryTitle: TLabel;
    lblRulesSummaryValue: TLabel;
    lblRulesSummaryNote: TLabel;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnConvertClick(Sender: TObject);
    procedure btnBrowseSourceClick(Sender: TObject);
    procedure btnBrowseTargetClick(Sender: TObject);
    procedure btnOpenReportClick(Sender: TObject);
    procedure btnPrintReportClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure HelpServerCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure btnOpenOutputClick(Sender: TObject);
    procedure btnCloseAppClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure RuleOptionChanged(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TabControlMainChange(Sender: TObject);
    procedure TabNavClick(Sender: TObject);
  private
    FHelpRoot: string;
    FConversionThread: TThread;
    FLastOutputPath: string;
    FLastTextReportPath: string;
    FLastHTMLReportPath: string;
    FPendingCompletion: TConversionCompletionSnapshot;
    FActiveEngine: TConverterEngine;
    FActiveEngineLock: TObject;
    FTabButtons: array[0..6] of TRectangle;
    FTabLabels: array[0..6] of TLabel;
    FTabScrollBoxes: array[0..6] of TVertScrollBox;
    FComponentMapHtml: string;
    FComponentMapPlainText: string;
    FPropertyMapHtml: string;
    FPropertyMapPlainText: string;
    FEventMapHtml: string;
    FEventMapPlainText: string;
    FHasCompletedRun: Boolean;
    FClosing: Boolean;
    FLastRunStatusText: string;
    FLastFilesProcessed: Integer;
    FLastFilesConverted: Integer;
    FLastFilesWithErrors: Integer;
    FLastFilesSkipped: Integer;
    FLastManualReviewCount: Integer;
    FLastBlockingCount: Integer;
    FLastRunDurationText: string;
    procedure Log(const Msg: string);
    function ConversionThreadProc(SourcePath, TargetPath, ReportLanguage: string;
      FileTypeIndex: Integer; Recursive, EnableCritical, EnableDataAware,
      EnableThirdParty, EnableWinAPI, DryRunPreview: Boolean;
      var Completion: TConversionCompletionSnapshot): string;
    procedure ResetToStartupState;
    procedure UpdateUIForConversion(Starting: Boolean);
    procedure UpdateArtifactsAfterConversion(const TargetPath,
      StatusText: string);
    procedure ResetArtifacts;
    procedure UpdateReportActions;
    procedure UpdateRuleSummary;
    procedure PopulateReferencePages;
    procedure SuggestTargetFromSource(const SourcePath: string);
    procedure CompleteConversionOnUIThread;
    procedure ResetRunSummary;
    procedure UpdateConversionOutputSummary(const ARunning: Boolean);
    function FormatReportDisplayText(const ReportPath: string): string;
    function FormatDurationText(const AStartTime, AEndTime: TDateTime): string;
    procedure ShowError(const Msg: string);
    function GetPreferredReportPath: string;
    function ExecuteShellVerb(const AVerb, ATarget: string;
      const HideWindow: Boolean = False): Boolean;
    procedure BuildTabChrome;
    procedure ApplyTabTheme;
    procedure UpdateTabChrome;
    function GetTabForNavIndex(const AIndex: Integer): TTabItem;
    procedure LoadComponentMapReference;
    procedure BuildComponentMapContent(out AHtml, APlainText: string);
    procedure LoadPropertyMapReference;
    procedure BuildPropertyMapContent(out AHtml, APlainText: string);
    procedure LoadEventMapReference;
    procedure BuildEventMapContent(out AHtml, APlainText: string);
    procedure AppendReferencePageHead(ABuilder: TStringBuilder;
      const ATitle: string; const ATableMinWidth: Integer;
      const AExtraCss: string; const AStickyHeader: Boolean);
    procedure AppendReferenceHeroStart(ABuilder: TStringBuilder;
      const AEyebrow, AHeading, ADescription: string);
    procedure AppendReferenceMetricCard(ABuilder: TStringBuilder;
      const AValue: Integer; const ALabel: string);
    procedure AppendReferenceHeroEnd(ABuilder: TStringBuilder);
    procedure AppendReferenceSectionStart(ABuilder: TStringBuilder;
      const AHeading, ADescription, ATableHeaderHtml: string);
    procedure AppendReferencePageEnd(ABuilder: TStringBuilder);
    procedure AppendReferenceTextIntro(ABuilder: TStringBuilder;
      const ATitle, ADescription: string);
    function HtmlEncode(const AValue: string): string;
    function GetMappingBadgeCssClass(const AMappingType: string): string;
    function GetPropertyRuleCssClass(const AKind: string): string;
    function GetEventSignatureCssClass(const AKind: string): string;
  public
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows,
  Winapi.ShellAPI;
{$ENDIF}

{$R *.fmx}


resourcestring
  SDisplayManualReplacementRequired = 'Manual replacement required';
  SDisplayMappingPack = 'Mapping pack';
  SDisplayDerivedFromLiveRttiAndFmxCatalog = 'Derived from live RTTI and FMX catalog research.';
  SDisplayNoSuitableFmxComponentMatchIsCurrently = 'No suitable FMX component match is currently known.';
  SDisplayStandardBuiltInMappingWithNoAdditional = 'Standard built-in mapping with no additional notes.';
  SDisplayTransformed = 'Transformed';
  SDisplayUsesAnExplicitTransformationRuleFromThe = 'Uses an explicit transformation rule from the built-in mapper.';
  SDisplayDerivedFromConverterHeuristicColorMapsTo = 'Derived from converter heuristic: Color maps to Fill.Color using TransformColor.';
  SDisplayDerivedFromConverterHeuristicColorRequiresTransformcolor = 'Derived from converter heuristic: Color requires TransformColor on the FMX target.';
  SDisplayDirect = 'Direct';
  SDisplayUsesAnExplicitDirectPropertyRuleFrom = 'Uses an explicit direct property rule from the built-in mapper.';
  SDisplayDerivedFromRttiInventoryBecauseTheSame = 'Derived from RTTI inventory because the same published property exists on the FMX target.';
  SDisplayRenamed = 'Renamed';
  SDisplayUsesAnExplicitRenamedPropertyRuleFrom = 'Uses an explicit renamed property rule from the built-in mapper.';
  SDisplayDerivedFromConverterHeuristicCaptionMapsTo = 'Derived from converter heuristic: Caption maps to Text on the FMX target.';
  SDisplayDerivedFromRttiInventoryBecauseTheProperty = 'Derived from RTTI inventory because the property resolves to a different FMX target name.';
  SDisplayManualReviewRequired = 'Manual review required';
  SDisplayManualReview = 'Manual review';
  SDisplayNoFmxTargetPropertyIsDefinedIn = 'No FMX target property is defined in the explicit mapper rule.';
  SDisplayTheResearchedComponentMappingDoesNotCurrently = 'The researched component mapping does not currently resolve this property to an FMX target.';
  SDisplayThisComponentDoesNotCurrentlyResolveTo = 'This component does not currently resolve to an FMX target class.';
  SDisplayNoExplicitOrRttiDerivedFmxTarget = 'No explicit or RTTI-derived FMX target property was identified.';
  SDisplaySSS = '%s.%s -> %s';
  SDisplayRuleType = '  Rule type: ';
  SDisplaySourceType = '  Source type: ';
  SDisplayRuleSourceExplicitMapperRule = '  Rule source: explicit mapper rule';
  SDisplayRuleSourceRttiInventory = '  Rule source: RTTI inventory';
  SDisplayRuleSourceUnresolved = '  Rule source: unresolved';
  SDisplayTransformer = '  Transformer: ';
  SDisplayNotes = '  Notes: ';
  SDisplayCompatible = 'Compatible';
  SDisplayReviewRequired = 'Review required';
  SDisplayUsesAnExplicitEventRuleFromThe = 'Uses an explicit event rule from the built-in mapper.';
  SDisplayUsesAnExplicitEventRuleButThe = 'Uses an explicit event rule, but the stored signature check requires review.';
  SDisplayDerivedFromRttiInventoryBecauseTheSame2 = 'Derived from RTTI inventory because the same published event exists on the FMX target.';
  SDisplayDerivedFromRttiInventoryButTheEvent = 'Derived from RTTI inventory, but the event signatures require review.';
  SDisplayNoFmxTargetEventIsDefinedIn = 'No FMX target event is defined in the explicit mapper rule.';
  SDisplayTheResearchedComponentMappingDoesNotCurrently2 = 'The researched component mapping does not currently resolve this event to an FMX target.';
  SDisplayNoExplicitOrRttiDerivedFmxEvent = 'No explicit or RTTI-derived FMX event was identified.';
  SDisplayVclSignature = '  VCL signature: ';
  SDisplayFmxSignature = '  FMX signature: ';
  SDisplaySignatureStatus = '  Signature status: ';
  SDisplayChooseAVclSourceFolderAndAn = 'Choose a VCL source folder and an FMX output folder, then start the conversion.';
  SDisplayPreparingConversion = 'Preparing conversion...';
  SDisplayStartingConversionEngine = 'Starting conversion engine...';

resourcestring
  SReferenceComponentMappingReference = 'Component Mapping Reference';
  SReferenceComponentReference = 'Component reference';
  SReferenceGeneratedFromTheConverterSComponentMapping = 'Generated from the converter''s component mapping database and RTTI inventories for operator review and migration planning.';
  SReferenceDiscoverableComponents = 'Discoverable components';
  SReferenceDirectConversions = 'Direct conversions';
  SReferenceSubstituteMappings = 'Substitute mappings';
  SReferenceManualReview = 'Manual review';
  SReferenceReferenceNotes = 'Reference notes';
  SReferenceEachRowShowsADiscoverableVclComponent = 'Each row shows a discoverable VCL component class, the FMX target class the converter currently routes toward, the mapping strategy, the confidence score, and any notes that still require operator attention. Property and event counts reflect the published VCL inventory currently discoverable for each source class.';
  SReferenceComponentMappingReference2 = 'Component mapping reference';
  SReferenceBuiltFromTheLiveMappingDatabaseAnd = 'Built from the live mapping database and RTTI inventories.';
  SReferencePropertyMappingReference = 'Property Mapping Reference';
  SReferencePropertyReference = 'Property reference';
  SReferenceGeneratedFromTheConverterSExplicitProperty = 'Generated from the converter''s explicit property rules plus RTTI inventories so operators can review direct carries, renames, transformations, and review items before conversion.';
  SReferencePropertyRules = 'Property rules';
  SReferenceDirectRules = 'Direct rules';
  SReferenceRenamedRules = 'Renamed rules';
  SReferenceTransformedRules = 'Transformed rules';
  SReferenceThisScreenCurrentlyCoversDMappedComponent = 'This screen currently covers %d mapped component classes with discoverable published properties. Use it to verify when a property carries across unchanged, when the converter renames the target property, when a value transformation routine is required, and when a property still needs review.';
  SReferencePropertyMappingReference2 = 'Property mapping reference';
  SReferenceBuiltFromExplicitPropertyRulesPlusRtti = 'Built from explicit property rules plus RTTI inventories.';
  SReferenceEventMappingReference = 'Event Mapping Reference';
  SReferenceEventReference = 'Event reference';
  SReferenceGeneratedFromTheConverterSExplicitEvent = 'Generated from the converter''s explicit event rules plus RTTI inventories so operators can review handler carry-forward, renamed targets, and signature compatibility.';
  SReferenceEventRules = 'Event rules';
  SReferenceDirectEvents = 'Direct events';
  SReferenceRenamedEvents = 'Renamed events';
  SReferenceSignatureReview = 'Signature review';
  SReferenceThisScreenCurrentlyCoversDMappedComponent2 = 'This screen currently covers %d mapped component classes with discoverable published events. Use it to verify whether a VCL handler can carry forward directly, whether the target event name changes, and whether the mapped signatures remain compatible. Rows flagged for review need operator attention before relying on automatic migration.';
  SReferenceEventMappingReference2 = 'Event mapping reference';
  SReferenceBuiltFromExplicitEventRulesPlusRtti = 'Built from explicit event rules plus RTTI inventories.';


procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FHelpRoot := IncludeTrailingPathDelimiter(ExpandFileName(
    ExtractFilePath(ParamStr(0)) + '..\..\docs\Help'));
  if not FileExists(FHelpRoot + 'index.html') then
    FHelpRoot := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + 'docs\Help');
  FActiveEngineLock := TObject.Create;

  PopulateReferencePages;
  LoadComponentMapReference;
  LoadPropertyMapReference;
  LoadEventMapReference;
  ResetArtifacts;
  UpdateRuleSummary;
  UpdateUIForConversion(False);
  BuildTabChrome;
  RulesSummaryScrollBox.ViewportPosition := PointF(0, 0);
  TabControlMain.ActiveTab := tabProjectScan;
  UpdateTabChrome;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  if not Assigned(TabControlMain.ActiveTab) then
    TabControlMain.ActiveTab := tabDashboard;
  ApplyTabTheme;
  UpdateTabChrome;
  LoadComponentMapReference;
  LoadPropertyMapReference;
  LoadEventMapReference;
end;

destructor TfrmMain.Destroy;
begin
  FClosing := True;
  if Assigned(HelpServer) then
    HelpServer.Active := False;
  if Assigned(FConversionThread) then
  begin
    if Assigned(FActiveEngineLock) then
    begin
      TMonitor.Enter(FActiveEngineLock);
      try
        if Assigned(FActiveEngine) then
          FActiveEngine.Cancel;
      finally
        TMonitor.Exit(FActiveEngineLock);
      end;
    end;

    while not FConversionThread.Finished do
    begin
      CheckSynchronize(50);
      if Assigned(FActiveEngineLock) then
      begin
        TMonitor.Enter(FActiveEngineLock);
        try
          if Assigned(FActiveEngine) then
            FActiveEngine.Cancel;
        finally
          TMonitor.Exit(FActiveEngineLock);
        end;
      end;
    end;

    TThread.RemoveQueuedEvents(FConversionThread);
    FreeAndNil(FConversionThread);
  end;
  FreeAndNil(FActiveEngineLock);
  inherited;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Assigned(FConversionThread) and FConversionThread.Finished then
  begin
    TThread.RemoveQueuedEvents(FConversionThread);
    FreeAndNil(FConversionThread);
  end;

  CanClose := not Assigned(FConversionThread);
  FClosing := CanClose;
  if not CanClose then
    TDialogService.ShowMessage(
      'A conversion is still running. Please wait for it to finish before closing the program.');
end;

procedure TfrmMain.PopulateReferencePages;
begin
  MemoComponentMap.Lines.Text := 'Building component mapping reference...';

  MemoPropertyMap.Lines.Text := 'Building property mapping reference...';

  MemoEventMap.Lines.Text := 'Building event mapping reference...';
end;

procedure TfrmMain.LoadComponentMapReference;
begin
  if (FComponentMapHtml = '') or (FComponentMapPlainText = '') then
  begin
    try
      BuildComponentMapContent(FComponentMapHtml, FComponentMapPlainText);
    except
      on E: Exception do
      begin
        FComponentMapHtml := '';
        FComponentMapPlainText :=
          'Component mapping reference could not be generated.' + sLineBreak +
          sLineBreak + E.Message;
      end;
    end;
  end;

  MemoComponentMap.Lines.Text := FComponentMapPlainText;

  if Assigned(ComponentMapBrowser) and (FComponentMapHtml <> '') then
    try
      ComponentMapBrowser.LoadFromStrings(FComponentMapHtml, TEncoding.UTF8,
        'about:blank');
      ComponentMapBrowser.Visible := True;
      ComponentMapBrowser.BringToFront;
      MemoComponentMap.Visible := False;
    except
      ComponentMapBrowser.Visible := False;
      MemoComponentMap.Visible := True;
    end
  else
    MemoComponentMap.Visible := True;
end;

procedure TfrmMain.LoadPropertyMapReference;
begin
  if (FPropertyMapHtml = '') or (FPropertyMapPlainText = '') then
  begin
    try
      BuildPropertyMapContent(FPropertyMapHtml, FPropertyMapPlainText);
    except
      on E: Exception do
      begin
        FPropertyMapHtml := '';
        FPropertyMapPlainText :=
          'Property mapping reference could not be generated.' + sLineBreak +
          sLineBreak + E.Message;
      end;
    end;
  end;

  MemoPropertyMap.Lines.Text := FPropertyMapPlainText;

  if Assigned(PropertyMapBrowser) and (FPropertyMapHtml <> '') then
    try
      PropertyMapBrowser.LoadFromStrings(FPropertyMapHtml, TEncoding.UTF8,
        'about:blank');
      PropertyMapBrowser.Visible := True;
      PropertyMapBrowser.BringToFront;
      MemoPropertyMap.Visible := False;
    except
      PropertyMapBrowser.Visible := False;
      MemoPropertyMap.Visible := True;
    end
  else
    MemoPropertyMap.Visible := True;
end;

procedure TfrmMain.LoadEventMapReference;
begin
  if (FEventMapHtml = '') or (FEventMapPlainText = '') then
  begin
    try
      BuildEventMapContent(FEventMapHtml, FEventMapPlainText);
    except
      on E: Exception do
      begin
        FEventMapHtml := '';
        FEventMapPlainText :=
          'Event mapping reference could not be generated.' + sLineBreak +
          sLineBreak + E.Message;
      end;
    end;
  end;

  MemoEventMap.Lines.Text := FEventMapPlainText;

  if Assigned(EventMapBrowser) and (FEventMapHtml <> '') then
    try
      EventMapBrowser.LoadFromStrings(FEventMapHtml, TEncoding.UTF8,
        'about:blank');
      EventMapBrowser.Visible := True;
      EventMapBrowser.BringToFront;
      MemoEventMap.Visible := False;
    except
      EventMapBrowser.Visible := False;
      MemoEventMap.Visible := True;
    end
  else
    MemoEventMap.Visible := True;
end;

procedure TfrmMain.BuildComponentMapContent(out AHtml, APlainText: string);
var
  Context: TConversionContext;
  Mapper: TComponentMapper;
  Mapping: TComponentMapping;
  HtmlBuilder: TStringBuilder;
  TextBuilder: TStringBuilder;
  ComponentNames: TStringList;
  VCLClassName: string;
  TotalMappings: Integer;
  DirectCount: Integer;
  SubstituteCount: Integer;
  UnmappedCount: Integer;
  ResearchedCount: Integer;
  OtherCount: Integer;
  FMXDisplay: string;
  NotesDisplay: string;
  MappingClass: string;
  MappingTypeDisplay: string;
  VCLInventory: TRttiClassInventory;
  VCLPropertyCount: Integer;
  VCLEventCount: Integer;
begin
  AHtml := '';
  APlainText := '';

  Context := TConversionContext.Create;
  try
    Mapper := TComponentMapper.Create(Context);
    try
      ComponentNames := TStringList.Create;
      HtmlBuilder := TStringBuilder.Create;
      TextBuilder := TStringBuilder.Create;
      try
        ComponentNames.Sorted := True;
        ComponentNames.Duplicates := dupIgnore;

        Mapper.PopulateDiscoverableVCLComponentClasses(ComponentNames);

        TotalMappings := ComponentNames.Count;
        DirectCount := 0;
        SubstituteCount := 0;
        UnmappedCount := 0;
        ResearchedCount := 0;
        OtherCount := 0;

        for VCLClassName in ComponentNames do
        begin
          Mapping := Mapper.FindBestMatch(VCLClassName);
          if not Assigned(Mapping) then
            Continue;

          if SameText(Mapping.MappingType, 'Direct') then
            Inc(DirectCount)
          else if SameText(Mapping.MappingType, 'Substitute') then
            Inc(SubstituteCount)
          else if SameText(Mapping.MappingType, 'Unmapped') then
            Inc(UnmappedCount)
          else if SameText(Mapping.MappingType, 'Researched') then
            Inc(ResearchedCount)
          else
            Inc(OtherCount);
        end;

        AppendReferencePageHead(HtmlBuilder, SReferenceComponentMappingReference, 940,
          '.component-name { font-weight: 700; color: #17395d; } ' +
          '.fmx-name { font-weight: 600; color: #24527f; } ' +
          '.missing { color: #8a3a28; font-weight: 700; } ' +
          '.badge { display: inline-block; padding: 5px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; letter-spacing: 0.03em; } ' +
          '.badge.direct { background: #dff4e8; color: #1f6a43; } ' +
          '.badge.substitute { background: #e5efff; color: #2c5fa8; } ' +
          '.badge.unmapped { background: #fde8e4; color: #9b3e2e; } ' +
          '.badge.researched { background: #efe5ff; color: #6c44a3; } ' +
          '.badge.other { background: #eef1f4; color: #4e6278; } ' +
          '.count { color: #5c7893; white-space: nowrap; } ' +
          '.note { color: #4b6784; }', True);
        AppendReferenceHeroStart(HtmlBuilder, SReferenceComponentReference,
          SReferenceComponentMappingReference,
          SReferenceGeneratedFromTheConverterSComponentMapping);
        AppendReferenceMetricCard(HtmlBuilder, TotalMappings,
          SReferenceDiscoverableComponents);
        AppendReferenceMetricCard(HtmlBuilder, DirectCount,
          SReferenceDirectConversions);
        AppendReferenceMetricCard(HtmlBuilder, SubstituteCount,
          SReferenceSubstituteMappings);
        AppendReferenceMetricCard(HtmlBuilder, UnmappedCount,
          SReferenceManualReview);
        AppendReferenceHeroEnd(HtmlBuilder);
        AppendReferenceSectionStart(HtmlBuilder, SReferenceReferenceNotes,
          SReferenceEachRowShowsADiscoverableVclComponent,
          '<thead><tr><th>VCL component</th><th>FMX target</th><th>Mapping</th><th>Confidence</th><th>Published properties</th><th>Published events</th><th>Notes</th></tr></thead>');

        AppendReferenceTextIntro(TextBuilder, SReferenceComponentMappingReference2,
          SReferenceBuiltFromTheLiveMappingDatabaseAnd);

        for VCLClassName in ComponentNames do
        begin
          Mapping := Mapper.FindBestMatch(VCLClassName);
          if not Assigned(Mapping) then
            Continue;

          VCLInventory := Mapper.GetVCLInventory(VCLClassName);
          if Assigned(VCLInventory) then
          begin
            VCLPropertyCount := VCLInventory.Properties.Count;
            VCLEventCount := VCLInventory.Events.Count;
          end
          else
          begin
            VCLPropertyCount := Mapping.PropertyMaps.Count;
            VCLEventCount := Mapping.EventMaps.Count;
          end;

          FMXDisplay := Mapping.FMXClassName;
          if FMXDisplay = '' then
            FMXDisplay := SDisplayManualReplacementRequired;

          NotesDisplay := Trim(Mapping.Notes);
          if NotesDisplay = '' then
            if SameText(Mapping.MappingType, 'Researched') then
              NotesDisplay := SDisplayDerivedFromLiveRttiAndFmxCatalog
            else if SameText(Mapping.MappingType, 'Unmapped') then
              NotesDisplay := SDisplayNoSuitableFmxComponentMatchIsCurrently
            else
              NotesDisplay := SDisplayStandardBuiltInMappingWithNoAdditional;

          MappingClass := GetMappingBadgeCssClass(Mapping.MappingType);
          MappingTypeDisplay := Mapping.MappingType;
          if SameText(MappingTypeDisplay, 'Pack') then
            MappingTypeDisplay := SDisplayMappingPack;

          HtmlBuilder.AppendLine('<tr>');
          HtmlBuilder.AppendFormat('<td><div class="component-name"><code>%s</code></div></td>',
            [HtmlEncode(VCLClassName)]).AppendLine;
          if Mapping.FMXClassName <> '' then
            HtmlBuilder.AppendFormat('<td><div class="fmx-name"><code>%s</code></div></td>',
              [HtmlEncode(FMXDisplay)]).AppendLine
          else
            HtmlBuilder.AppendFormat('<td><div class="missing">%s</div></td>',
              [HtmlEncode(FMXDisplay)]).AppendLine;
          HtmlBuilder.AppendFormat('<td><span class="badge %s">%s</span></td>',
            [MappingClass, HtmlEncode(MappingTypeDisplay)]).AppendLine;
          HtmlBuilder.AppendFormat('<td class="count">%d%%</td>',
            [Mapping.Confidence]).AppendLine;
          HtmlBuilder.AppendFormat('<td class="count">%d</td>',
            [VCLPropertyCount]).AppendLine;
          HtmlBuilder.AppendFormat('<td class="count">%d</td>',
            [VCLEventCount]).AppendLine;
          HtmlBuilder.AppendFormat('<td class="note">%s</td>',
            [HtmlEncode(NotesDisplay)]).AppendLine;
          HtmlBuilder.AppendLine('</tr>');

          TextBuilder.AppendLine(Format('%s -> %s', [VCLClassName, FMXDisplay]));
          TextBuilder.AppendLine(Format('  Mapping type: %s  Confidence: %d%%',
            [MappingTypeDisplay, Mapping.Confidence]));
          TextBuilder.AppendLine(Format('  Published properties: %d  Published events: %d',
            [VCLPropertyCount, VCLEventCount]));
          TextBuilder.AppendLine('  Notes: ' + NotesDisplay);
          TextBuilder.AppendLine('');
        end;

        AppendReferencePageEnd(HtmlBuilder);

        AHtml := HtmlBuilder.ToString;
        APlainText := TextBuilder.ToString;
      finally
        ComponentNames.Free;
        HtmlBuilder.Free;
        TextBuilder.Free;
      end;
    finally
      Mapper.Free;
    end;
  finally
    Context.Free;
  end;
end;

procedure TfrmMain.BuildPropertyMapContent(out AHtml, APlainText: string);
var
  Context: TConversionContext;
  Mapper: TComponentMapper;
  ComponentNames: TStringList;
  Mapping: TComponentMapping;
  PropMap: TPropertyMapping;
  StoredPropMap: TPropertyMapping;
  ResolvedPropMap: TPropertyMapping;
  HtmlBuilder: TStringBuilder;
  TextBuilder: TStringBuilder;
  RowsHtml: TStringBuilder;
  RowsText: TStringBuilder;
  TotalRules: Integer;
  DirectRules: Integer;
  RenamedRules: Integer;
  TransformedRules: Integer;
  ReviewRules: Integer;
  ComponentsWithRules: Integer;
  RuleKind: string;
  TargetDisplay: string;
  TransformerDisplay: string;
  NotesDisplay: string;
  MappingNotes: string;
  VCLClassName: string;
  PropName: string;
  PropTypeName: string;
  VCLInventory: TRttiClassInventory;
  PropertyNames: TStringList;
  ResolveSucceeded: Boolean;
  HasStoredRule: Boolean;
  HasExplicitRule: Boolean;
  IsInventoryDerived: Boolean;
begin
  AHtml := '';
  APlainText := '';

  Context := TConversionContext.Create;
  try
    Mapper := TComponentMapper.Create(Context);
    try
      ComponentNames := TStringList.Create;
      HtmlBuilder := TStringBuilder.Create;
      TextBuilder := TStringBuilder.Create;
      RowsHtml := TStringBuilder.Create;
      RowsText := TStringBuilder.Create;
      try
        ComponentNames.Sorted := True;
        ComponentNames.Duplicates := dupIgnore;
        Mapper.PopulateDiscoverableVCLComponentClasses(ComponentNames);

        TotalRules := 0;
        DirectRules := 0;
        RenamedRules := 0;
        TransformedRules := 0;
        ReviewRules := 0;
        ComponentsWithRules := 0;

        for VCLClassName in ComponentNames do
        begin
          Mapping := Mapper.FindBestMatch(VCLClassName);
          VCLInventory := Mapper.GetVCLInventory(VCLClassName);
          PropertyNames := TStringList.Create;
          try
            PropertyNames.Sorted := True;
            PropertyNames.Duplicates := dupIgnore;
            Mapper.PopulateDiscoverablePropertyNames(VCLClassName, PropertyNames);

            if PropertyNames.Count > 0 then
              Inc(ComponentsWithRules);

            for PropName in PropertyNames do
            begin
              Inc(TotalRules);
              HasStoredRule := False;
              IsInventoryDerived := False;
              StoredPropMap.VCLProp := '';
              StoredPropMap.FMXProp := '';
              StoredPropMap.NeedsTransformation := False;
              StoredPropMap.TransformerFunc := '';
              ResolvedPropMap.VCLProp := '';
              ResolvedPropMap.FMXProp := '';
              ResolvedPropMap.NeedsTransformation := False;
              ResolvedPropMap.TransformerFunc := '';

              if Assigned(Mapping) then
                for PropMap in Mapping.PropertyMaps do
                  if (Trim(PropMap.VCLProp) <> '') and
                     (SameText(PropMap.VCLProp, PropName) or
                      PropName.StartsWith(PropMap.VCLProp + '.')) then
                  begin
                    StoredPropMap := PropMap;
                    HasStoredRule := True;
                    Break;
                  end;

              if Assigned(VCLInventory) and
                 VCLInventory.Properties.TryGetValue(PropName, PropTypeName) then
              begin
                if PropTypeName = '' then
                  PropTypeName := 'published property';
              end
              else
                PropTypeName := 'published property';

              ResolveSucceeded := Mapper.ResolvePropertyMapping(VCLClassName,
                PropName, ResolvedPropMap);
              HasExplicitRule := HasStoredRule and Assigned(Mapping) and
                not SameText(Mapping.MappingType, 'Researched');

              if ResolveSucceeded then
              begin
                TargetDisplay := ResolvedPropMap.FMXProp;
                TransformerDisplay := ResolvedPropMap.TransformerFunc;

                if ResolvedPropMap.NeedsTransformation then
                begin
                  RuleKind := SDisplayTransformed;
                  if HasExplicitRule then
                    NotesDisplay := SDisplayUsesAnExplicitTransformationRuleFromThe
                  else if SameText(TargetDisplay, 'Fill.Color') then
                  begin
                    IsInventoryDerived := True;
                    NotesDisplay := SDisplayDerivedFromConverterHeuristicColorMapsTo;
                  end
                  else
                  begin
                    IsInventoryDerived := True;
                    NotesDisplay := SDisplayDerivedFromConverterHeuristicColorRequiresTransformcolor;
                  end;
                end
                else if SameText(ResolvedPropMap.VCLProp, ResolvedPropMap.FMXProp) then
                begin
                  RuleKind := SDisplayDirect;
                  if HasExplicitRule then
                    NotesDisplay := SDisplayUsesAnExplicitDirectPropertyRuleFrom
                  else
                  begin
                    IsInventoryDerived := True;
                    NotesDisplay := SDisplayDerivedFromRttiInventoryBecauseTheSame;
                  end;
                end
                else
                begin
                  RuleKind := SDisplayRenamed;
                  if HasExplicitRule then
                    NotesDisplay := SDisplayUsesAnExplicitRenamedPropertyRuleFrom
                  else
                  begin
                    IsInventoryDerived := True;
                    if SameText(PropName, 'Caption') and
                       SameText(TargetDisplay, 'Text') then
                      NotesDisplay := SDisplayDerivedFromConverterHeuristicCaptionMapsTo
                    else
                      NotesDisplay := SDisplayDerivedFromRttiInventoryBecauseTheProperty;
                  end;
                end;
              end
              else
              begin
                TargetDisplay := SDisplayManualReviewRequired;
                TransformerDisplay := '';
                RuleKind := SDisplayManualReview;
                if HasExplicitRule then
                  NotesDisplay := SDisplayNoFmxTargetPropertyIsDefinedIn
                else if HasStoredRule then
                  NotesDisplay := SDisplayTheResearchedComponentMappingDoesNotCurrently
                else if not Assigned(Mapping) or (Trim(Mapping.FMXClassName) = '') then
                  NotesDisplay := SDisplayThisComponentDoesNotCurrentlyResolveTo
                else
                  NotesDisplay := SDisplayNoExplicitOrRttiDerivedFmxTarget;
              end;

              if TransformerDisplay = '' then
                TransformerDisplay := '-';

              if Assigned(Mapping) then
                MappingNotes := Trim(Mapping.Notes)
              else
                MappingNotes := '';
              if MappingNotes <> '' then
                NotesDisplay := NotesDisplay + ' ' + MappingNotes;

              if SameText(RuleKind, 'Direct') then
                Inc(DirectRules)
              else if SameText(RuleKind, 'Renamed') then
                Inc(RenamedRules)
              else if SameText(RuleKind, 'Transformed') then
                Inc(TransformedRules)
              else
                Inc(ReviewRules);

              RowsHtml.AppendLine('<tr>');
              RowsHtml.AppendFormat('<td><div class="component-name"><code>%s</code></div></td>',
                [HtmlEncode(VCLClassName)]).AppendLine;
              RowsHtml.AppendFormat('<td><div class="prop-name"><code>%s</code></div></td>',
                [HtmlEncode(PropName)]).AppendLine;
              if not SameText(TargetDisplay, 'Manual review required') then
                RowsHtml.AppendFormat('<td><div class="target-name"><code>%s</code></div></td>',
                  [HtmlEncode(TargetDisplay)]).AppendLine
              else
                RowsHtml.AppendFormat('<td><div class="missing">%s</div></td>',
                  [HtmlEncode(TargetDisplay)]).AppendLine;
              RowsHtml.AppendFormat('<td><span class="badge %s">%s</span></td>',
                [GetPropertyRuleCssClass(RuleKind), HtmlEncode(RuleKind)]).AppendLine;
              RowsHtml.AppendFormat('<td class="transformer">%s</td>',
                [HtmlEncode(TransformerDisplay)]).AppendLine;
              RowsHtml.AppendFormat('<td class="note">%s</td>',
                [HtmlEncode(NotesDisplay)]).AppendLine;
              RowsHtml.AppendLine('</tr>');

              RowsText.AppendLine(Format(SDisplaySSS,
                [VCLClassName, PropName, TargetDisplay]));
              RowsText.AppendLine(SDisplayRuleType + RuleKind);
              RowsText.AppendLine(SDisplaySourceType + PropTypeName);
              if HasExplicitRule then
                RowsText.AppendLine(SDisplayRuleSourceExplicitMapperRule)
              else if IsInventoryDerived or ResolveSucceeded then
                RowsText.AppendLine(SDisplayRuleSourceRttiInventory)
              else
                RowsText.AppendLine(SDisplayRuleSourceUnresolved);
              RowsText.AppendLine(SDisplayTransformer + TransformerDisplay);
              RowsText.AppendLine(SDisplayNotes + NotesDisplay);
              RowsText.AppendLine('');
            end;
          finally
            PropertyNames.Free;
          end;
        end;

        AppendReferencePageHead(HtmlBuilder, SReferencePropertyMappingReference, 980,
          '.component-name { font-weight: 700; color: #17395d; } ' +
          '.prop-name { font-weight: 700; color: #24527f; } ' +
          '.target-name { font-weight: 600; color: #24527f; } ' +
          '.missing { color: #8a3a28; font-weight: 700; } ' +
          '.badge { display: inline-block; padding: 5px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; letter-spacing: 0.03em; } ' +
          '.badge.direct { background: #dff4e8; color: #1f6a43; } ' +
          '.badge.renamed { background: #e5efff; color: #2c5fa8; } ' +
          '.badge.transformed { background: #efe5ff; color: #6c44a3; } ' +
          '.badge.review { background: #fde8e4; color: #9b3e2e; } ' +
          '.transformer { color: #5c7893; white-space: nowrap; } ' +
          '.note { color: #4b6784; }', False);
        AppendReferenceHeroStart(HtmlBuilder, SReferencePropertyReference,
          SReferencePropertyMappingReference,
          SReferenceGeneratedFromTheConverterSExplicitProperty);
        AppendReferenceMetricCard(HtmlBuilder, TotalRules, SReferencePropertyRules);
        AppendReferenceMetricCard(HtmlBuilder, DirectRules, SReferenceDirectRules);
        AppendReferenceMetricCard(HtmlBuilder, RenamedRules, SReferenceRenamedRules);
        AppendReferenceMetricCard(HtmlBuilder, TransformedRules,
          SReferenceTransformedRules);
        AppendReferenceHeroEnd(HtmlBuilder);
        AppendReferenceSectionStart(HtmlBuilder, SReferenceReferenceNotes,
          Format(SReferenceThisScreenCurrentlyCoversDMappedComponent,
            [ComponentsWithRules]),
          '<thead><tr><th>VCL component</th><th>VCL property</th><th>FMX property</th><th>Rule type</th><th>Transformer</th><th>Notes</th></tr></thead>');

        AppendReferenceTextIntro(TextBuilder, SReferencePropertyMappingReference2,
          SReferenceBuiltFromExplicitPropertyRulesPlusRtti);

        HtmlBuilder.Append(RowsHtml.ToString);

        AppendReferencePageEnd(HtmlBuilder);

        TextBuilder.Append(RowsText.ToString);

        AHtml := HtmlBuilder.ToString;
        APlainText := TextBuilder.ToString;
      finally
        ComponentNames.Free;
        HtmlBuilder.Free;
        TextBuilder.Free;
        RowsHtml.Free;
        RowsText.Free;
      end;
    finally
      Mapper.Free;
    end;
  finally
    Context.Free;
  end;
end;

procedure TfrmMain.BuildEventMapContent(out AHtml, APlainText: string);
var
  Context: TConversionContext;
  Mapper: TComponentMapper;
  ComponentNames: TStringList;
  Mapping: TComponentMapping;
  EventMap: TEventMapping;
  StoredEventMap: TEventMapping;
  ResolvedEventMap: TEventMapping;
  HtmlBuilder: TStringBuilder;
  TextBuilder: TStringBuilder;
  RowsHtml: TStringBuilder;
  RowsText: TStringBuilder;
  TotalRules: Integer;
  DirectRules: Integer;
  RenamedRules: Integer;
  SignatureWarnings: Integer;
  ComponentsWithRules: Integer;
  RuleKind: string;
  TargetDisplay: string;
  SignatureDisplay: string;
  NotesDisplay: string;
  MappingNotes: string;
  VCLClassName: string;
  EventName: string;
  VCLSignature: string;
  FMXSignature: string;
  VCLInventory: TRttiClassInventory;
  FMXInventory: TRttiClassInventory;
  EventNames: TStringList;
  ResolveSucceeded: Boolean;
  HasStoredRule: Boolean;
  HasExplicitRule: Boolean;
  IsInventoryDerived: Boolean;
begin
  AHtml := '';
  APlainText := '';

  Context := TConversionContext.Create;
  try
    Mapper := TComponentMapper.Create(Context);
    try
      ComponentNames := TStringList.Create;
      HtmlBuilder := TStringBuilder.Create;
      TextBuilder := TStringBuilder.Create;
      RowsHtml := TStringBuilder.Create;
      RowsText := TStringBuilder.Create;
      try
        ComponentNames.Sorted := True;
        ComponentNames.Duplicates := dupIgnore;
        Mapper.PopulateDiscoverableVCLComponentClasses(ComponentNames);

        TotalRules := 0;
        DirectRules := 0;
        RenamedRules := 0;
        SignatureWarnings := 0;
        ComponentsWithRules := 0;

        for VCLClassName in ComponentNames do
        begin
          Mapping := Mapper.FindBestMatch(VCLClassName);
          VCLInventory := Mapper.GetVCLInventory(VCLClassName);
          if Assigned(Mapping) and (Mapping.FMXClassName <> '') then
            FMXInventory := Mapper.GetFMXInventory(Mapping.FMXClassName)
          else
            FMXInventory := nil;

          EventNames := TStringList.Create;
          try
            EventNames.Sorted := True;
            EventNames.Duplicates := dupIgnore;
            Mapper.PopulateDiscoverableEventNames(VCLClassName, EventNames);

            if EventNames.Count > 0 then
              Inc(ComponentsWithRules);

            for EventName in EventNames do
            begin
              Inc(TotalRules);
              HasStoredRule := False;
              IsInventoryDerived := False;
              StoredEventMap.VCLEvent := '';
              StoredEventMap.FMXEvent := '';
              StoredEventMap.SignatureMatch := False;
              ResolvedEventMap.VCLEvent := '';
              ResolvedEventMap.FMXEvent := '';
              ResolvedEventMap.SignatureMatch := False;

              if Assigned(Mapping) then
                for EventMap in Mapping.EventMaps do
                  if (Trim(EventMap.VCLEvent) <> '') and
                     SameText(EventMap.VCLEvent, EventName) then
                  begin
                    StoredEventMap := EventMap;
                    HasStoredRule := True;
                    Break;
                  end;

              if Assigned(VCLInventory) and
                 VCLInventory.Events.TryGetValue(EventName, VCLSignature) then
              begin
                if VCLSignature = '' then
                  VCLSignature := 'published event';
              end
              else
                VCLSignature := 'published event';

              ResolveSucceeded := Mapper.ResolveEventMapping(VCLClassName,
                EventName, ResolvedEventMap);
              HasExplicitRule := HasStoredRule and Assigned(Mapping) and
                not SameText(Mapping.MappingType, 'Researched');

              FMXSignature := '';

              if ResolveSucceeded then
              begin
                TargetDisplay := ResolvedEventMap.FMXEvent;
                if SameText(ResolvedEventMap.VCLEvent, ResolvedEventMap.FMXEvent) then
                  RuleKind := SDisplayDirect
                else
                  RuleKind := SDisplayRenamed;

                if ResolvedEventMap.SignatureMatch then
                  SignatureDisplay := SDisplayCompatible
                else
                  SignatureDisplay := SDisplayReviewRequired;

                if HasExplicitRule then
                begin
                  if SignatureDisplay = 'Compatible' then
                    NotesDisplay := SDisplayUsesAnExplicitEventRuleFromThe
                  else
                    NotesDisplay := SDisplayUsesAnExplicitEventRuleButThe;
                end
                else
                begin
                  IsInventoryDerived := True;
                  if SignatureDisplay = 'Compatible' then
                    NotesDisplay := SDisplayDerivedFromRttiInventoryBecauseTheSame2
                  else
                    NotesDisplay := SDisplayDerivedFromRttiInventoryButTheEvent;
                end;
              end
              else
              begin
                TargetDisplay := SDisplayManualReviewRequired;
                RuleKind := SDisplayManualReview;
                SignatureDisplay := SDisplayReviewRequired;
                if HasExplicitRule then
                  NotesDisplay := SDisplayNoFmxTargetEventIsDefinedIn
                else if HasStoredRule then
                  NotesDisplay := SDisplayTheResearchedComponentMappingDoesNotCurrently2
                else if not Assigned(Mapping) or (Mapping.FMXClassName = '') then
                  NotesDisplay := SDisplayThisComponentDoesNotCurrentlyResolveTo
                else
                  NotesDisplay := SDisplayNoExplicitOrRttiDerivedFmxEvent;
              end;

              if (TargetDisplay <> 'Manual review required') and Assigned(FMXInventory) and
                 FMXInventory.Events.TryGetValue(TargetDisplay, FMXSignature) and
                 (FMXSignature = '') then
                FMXSignature := 'published event';

              if Assigned(Mapping) then
                MappingNotes := Trim(Mapping.Notes)
              else
                MappingNotes := '';
              if MappingNotes <> '' then
                NotesDisplay := NotesDisplay + ' ' + MappingNotes;

              if SameText(RuleKind, 'Direct') then
                Inc(DirectRules)
              else if SameText(RuleKind, 'Renamed') then
                Inc(RenamedRules);

              if not SameText(SignatureDisplay, 'Compatible') then
                Inc(SignatureWarnings);

              RowsHtml.AppendLine('<tr>');
              RowsHtml.AppendFormat('<td><div class="component-name"><code>%s</code></div></td>',
                [HtmlEncode(VCLClassName)]).AppendLine;
              RowsHtml.AppendFormat('<td><div class="event-name"><code>%s</code></div></td>',
                [HtmlEncode(EventName)]).AppendLine;
              if not SameText(TargetDisplay, 'Manual review required') then
                RowsHtml.AppendFormat('<td><div class="target-name"><code>%s</code></div></td>',
                  [HtmlEncode(TargetDisplay)]).AppendLine
              else
                RowsHtml.AppendFormat('<td><div class="missing">%s</div></td>',
                  [HtmlEncode(TargetDisplay)]).AppendLine;
              RowsHtml.AppendFormat('<td><span class="badge %s">%s</span></td>',
                [GetPropertyRuleCssClass(RuleKind), HtmlEncode(RuleKind)]).AppendLine;
              RowsHtml.AppendFormat('<td><span class="badge %s">%s</span></td>',
                [GetEventSignatureCssClass(SignatureDisplay),
                 HtmlEncode(SignatureDisplay)]).AppendLine;
              RowsHtml.AppendFormat('<td class="note">%s</td>',
                [HtmlEncode(NotesDisplay)]).AppendLine;
              RowsHtml.AppendLine('</tr>');

              RowsText.AppendLine(Format(SDisplaySSS,
                [VCLClassName, EventName, TargetDisplay]));
              RowsText.AppendLine(SDisplayRuleType + RuleKind);
              if HasExplicitRule then
                RowsText.AppendLine(SDisplayRuleSourceExplicitMapperRule)
              else if IsInventoryDerived or ResolveSucceeded then
                RowsText.AppendLine(SDisplayRuleSourceRttiInventory)
              else
                RowsText.AppendLine(SDisplayRuleSourceUnresolved);
              RowsText.AppendLine(SDisplayVclSignature + VCLSignature);
              if FMXSignature <> '' then
                RowsText.AppendLine(SDisplayFmxSignature + FMXSignature);
              RowsText.AppendLine(SDisplaySignatureStatus + SignatureDisplay);
              RowsText.AppendLine(SDisplayNotes + NotesDisplay);
              RowsText.AppendLine('');
            end;
          finally
            EventNames.Free;
          end;
        end;

        AppendReferencePageHead(HtmlBuilder, SReferenceEventMappingReference, 980,
          '.component-name { font-weight: 700; color: #17395d; } ' +
          '.event-name { font-weight: 700; color: #24527f; } ' +
          '.target-name { font-weight: 600; color: #24527f; } ' +
          '.missing { color: #8a3a28; font-weight: 700; } ' +
          '.badge { display: inline-block; padding: 5px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; letter-spacing: 0.03em; } ' +
          '.badge.direct { background: #dff4e8; color: #1f6a43; } ' +
          '.badge.renamed { background: #e5efff; color: #2c5fa8; } ' +
          '.badge.review { background: #fde8e4; color: #9b3e2e; } ' +
          '.badge.compatible { background: #dff4e8; color: #1f6a43; } ' +
          '.badge.warning { background: #fde8e4; color: #9b3e2e; } ' +
          '.note { color: #4b6784; }', False);
        AppendReferenceHeroStart(HtmlBuilder, SReferenceEventReference,
          SReferenceEventMappingReference,
          SReferenceGeneratedFromTheConverterSExplicitEvent);
        AppendReferenceMetricCard(HtmlBuilder, TotalRules, SReferenceEventRules);
        AppendReferenceMetricCard(HtmlBuilder, DirectRules, SReferenceDirectEvents);
        AppendReferenceMetricCard(HtmlBuilder, RenamedRules, SReferenceRenamedEvents);
        AppendReferenceMetricCard(HtmlBuilder, SignatureWarnings,
          SReferenceSignatureReview);
        AppendReferenceHeroEnd(HtmlBuilder);
        AppendReferenceSectionStart(HtmlBuilder, SReferenceReferenceNotes,
          Format(SReferenceThisScreenCurrentlyCoversDMappedComponent2,
            [ComponentsWithRules]),
          '<thead><tr><th>VCL component</th><th>VCL event</th><th>FMX event</th><th>Rule type</th><th>Signature</th><th>Notes</th></tr></thead>');

        AppendReferenceTextIntro(TextBuilder, SReferenceEventMappingReference2,
          SReferenceBuiltFromExplicitEventRulesPlusRtti);

        HtmlBuilder.Append(RowsHtml.ToString);

        AppendReferencePageEnd(HtmlBuilder);

        TextBuilder.Append(RowsText.ToString);

        AHtml := HtmlBuilder.ToString;
        APlainText := TextBuilder.ToString;
      finally
        ComponentNames.Free;
        HtmlBuilder.Free;
        TextBuilder.Free;
        RowsHtml.Free;
        RowsText.Free;
      end;
    finally
      Mapper.Free;
    end;
  finally
    Context.Free;
  end;
end;

procedure TfrmMain.AppendReferencePageHead(ABuilder: TStringBuilder;
  const ATitle: string; const ATableMinWidth: Integer;
  const AExtraCss: string; const AStickyHeader: Boolean);
var
  HeaderCss: string;
begin
  if AStickyHeader then
    HeaderCss :=
      'thead th { position: sticky; top: 0; background: #edf4fc; color: #23496f; font-size: 12px; text-transform: uppercase; letter-spacing: 0.08em; text-align: left; padding: 14px 14px; border-bottom: 1px solid #d2e0f0; }'
  else
    HeaderCss :=
      'thead th { background: #edf4fc; color: #23496f; font-size: 12px; text-transform: uppercase; letter-spacing: 0.08em; text-align: left; padding: 14px 14px; border-bottom: 1px solid #d2e0f0; }';

  ABuilder.AppendLine('<!DOCTYPE html>');
  ABuilder.AppendLine('<html lang="en">');
  ABuilder.AppendLine('<head>');
  ABuilder.AppendLine('<meta charset="utf-8">');
  ABuilder.AppendLine('<meta name="viewport" content="width=device-width, initial-scale=1">');
  ABuilder.AppendFormat('<title>%s</title>', [HtmlEncode(ATitle)]).AppendLine;
  ABuilder.AppendLine('<style>');
  ABuilder.AppendLine('body { margin: 0; padding: 22px; background: #eef4fb; color: #17385c; font-family: "Segoe UI", Tahoma, sans-serif; }');
  ABuilder.AppendLine('code { font: inherit; color: inherit; }');
  ABuilder.AppendLine('.page { width: 100%; margin: 0; box-sizing: border-box; }');
  ABuilder.AppendLine('.hero { background: #e9f2ff; border: 1px solid #d2e2f6; border-radius: 20px; padding: 24px 26px; box-shadow: 0 10px 22px rgba(21, 49, 85, 0.08); }');
  ABuilder.AppendLine('.eyebrow { font-size: 12px; text-transform: uppercase; letter-spacing: 0.16em; color: #557699; margin-bottom: 10px; }');
  ABuilder.AppendLine('h1 { margin: 0 0 10px 0; font-size: 28px; line-height: 1.15; color: #163a63; }');
  ABuilder.AppendLine('.hero p { margin: 0; font-size: 15px; line-height: 1.45; color: #365674; }');
  ABuilder.AppendLine('.summary-table { width: 100%; margin-top: 18px; border-collapse: separate; border-spacing: 0 10px; }');
  ABuilder.AppendLine('.summary-table td { width: 25%; padding-right: 12px; vertical-align: top; }');
  ABuilder.AppendLine('.metric-line { display: block; background: #ffffff; border: 1px solid #d7e5f6; border-radius: 14px; padding: 12px 14px; color: #163a63; font-weight: 700; white-space: nowrap; }');
  ABuilder.AppendLine('.metric-value { display: inline; font-size: 26px; font-weight: 700; line-height: 1; color: #163a63; }');
  ABuilder.AppendLine('.metric-label { display: inline; margin-left: 10px; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; line-height: 1; color: #163a63; }');
  ABuilder.AppendLine('.section { margin-top: 20px; background: #ffffff; border: 1px solid #d8e5f4; border-radius: 20px; padding: 22px 24px; box-shadow: 0 10px 22px rgba(21, 49, 85, 0.08); }');
  ABuilder.AppendLine('.section h2 { margin: 0 0 8px 0; font-size: 20px; color: #163a63; }');
  ABuilder.AppendLine('.section p { margin: 0; color: #476788; line-height: 1.55; }');
  ABuilder.AppendLine('.table-wrap { overflow-x: auto; margin-top: 18px; }');
  ABuilder.AppendFormat('table { width: 100%%; border-collapse: collapse; min-width: %dpx; }',
    [ATableMinWidth]).AppendLine;
  ABuilder.AppendLine(HeaderCss);
  ABuilder.AppendLine('tbody td { padding: 14px 14px; border-bottom: 1px solid #e2ebf5; vertical-align: top; font-size: 14px; line-height: 1.5; }');
  ABuilder.AppendLine('tbody tr:nth-child(even) { background: #f8fbff; }');
  if Trim(AExtraCss) <> '' then
    ABuilder.AppendLine(AExtraCss);
  ABuilder.AppendLine('@media (max-width: 980px) { body { padding: 14px; } .summary-table td { display: block; width: 100%; padding-right: 0; } }');
  ABuilder.AppendLine('@media (max-width: 620px) { h1 { font-size: 24px; } }');
  ABuilder.AppendLine('</style>');
  ABuilder.AppendLine('</head>');
end;

procedure TfrmMain.AppendReferenceHeroStart(ABuilder: TStringBuilder;
  const AEyebrow, AHeading, ADescription: string);
begin
  ABuilder.AppendLine('<body>');
  ABuilder.AppendLine('<div class="page">');
  ABuilder.AppendLine('<div class="hero">');
  ABuilder.AppendFormat('<div class="eyebrow">%s</div>', [HtmlEncode(AEyebrow)]).AppendLine;
  ABuilder.AppendFormat('<h1>%s</h1>', [HtmlEncode(AHeading)]).AppendLine;
  ABuilder.AppendFormat('<p>%s</p>', [HtmlEncode(ADescription)]).AppendLine;
  ABuilder.AppendLine('<table class="summary-table" cellpadding="0" cellspacing="0" border="0">');
  ABuilder.AppendLine('<tr>');
end;

procedure TfrmMain.AppendReferenceMetricCard(ABuilder: TStringBuilder;
  const AValue: Integer; const ALabel: string);
begin
  ABuilder.AppendFormat(
    '<td><span class="metric-line"><span class="metric-value">%d</span><span class="metric-label">%s</span></span></td>',
    [AValue, HtmlEncode(ALabel)]).AppendLine;
end;

procedure TfrmMain.AppendReferenceHeroEnd(ABuilder: TStringBuilder);
begin
  ABuilder.AppendLine('</tr>');
  ABuilder.AppendLine('</table>');
  ABuilder.AppendLine('</div>');
end;

procedure TfrmMain.AppendReferenceSectionStart(ABuilder: TStringBuilder;
  const AHeading, ADescription, ATableHeaderHtml: string);
begin
  ABuilder.AppendLine('<div class="section">');
  ABuilder.AppendFormat('<h2>%s</h2>', [HtmlEncode(AHeading)]).AppendLine;
  ABuilder.AppendFormat('<p>%s</p>', [HtmlEncode(ADescription)]).AppendLine;
  ABuilder.AppendLine('<div class="table-wrap">');
  ABuilder.AppendLine('<table>');
  ABuilder.AppendLine(ATableHeaderHtml);
  ABuilder.AppendLine('<tbody>');
end;

procedure TfrmMain.AppendReferencePageEnd(ABuilder: TStringBuilder);
begin
  ABuilder.AppendLine('</tbody>');
  ABuilder.AppendLine('</table>');
  ABuilder.AppendLine('</div>');
  ABuilder.AppendLine('</div>');
  ABuilder.AppendLine('</div>');
  ABuilder.AppendLine('</body>');
  ABuilder.AppendLine('</html>');
end;

procedure TfrmMain.AppendReferenceTextIntro(ABuilder: TStringBuilder;
  const ATitle, ADescription: string);
begin
  ABuilder.AppendLine(ATitle);
  ABuilder.AppendLine(ADescription);
  ABuilder.AppendLine('');
end;
function TfrmMain.HtmlEncode(const AValue: string): string;
begin
  Result := StringReplace(AValue, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

function TfrmMain.GetMappingBadgeCssClass(const AMappingType: string): string;
begin
  if SameText(AMappingType, 'Direct') then
    Result := 'direct'
  else if SameText(AMappingType, 'Substitute') then
    Result := 'substitute'
  else if SameText(AMappingType, 'Unmapped') then
    Result := 'unmapped'
  else if SameText(AMappingType, 'Researched') then
    Result := 'researched'
  else
    Result := 'other';
end;

function TfrmMain.GetPropertyRuleCssClass(const AKind: string): string;
begin
  if SameText(AKind, 'Direct') then
    Result := 'direct'
  else if SameText(AKind, 'Renamed') then
    Result := 'renamed'
  else if SameText(AKind, 'Transformed') then
    Result := 'transformed'
  else
    Result := 'review';
end;

function TfrmMain.GetEventSignatureCssClass(const AKind: string): string;
begin
  if SameText(AKind, 'Compatible') then
    Result := 'compatible'
  else
    Result := 'warning';
end;

function TfrmMain.GetTabForNavIndex(const AIndex: Integer): TTabItem;
begin
  case AIndex of
    0: Result := tabDashboard;
    1: Result := tabProjectScan;
    2: Result := tabComponentMap;
    3: Result := tabPropertyMap;
    4: Result := tabEventMap;
    5: Result := tabIssues;
    6: Result := tabRules;
  else
    Result := tabDashboard;
  end;
end;

procedure TfrmMain.BuildTabChrome;
begin
  FTabButtons[0] := TabButtonDashboard;
  FTabButtons[1] := TabButtonProjectScan;
  FTabButtons[2] := TabButtonComponentMap;
  FTabButtons[3] := TabButtonPropertyMap;
  FTabButtons[4] := TabButtonEventMap;
  FTabButtons[5] := TabButtonIssues;
  FTabButtons[6] := TabButtonRules;

  FTabLabels[0] := lblTabDashboard;
  FTabLabels[1] := lblTabProjectScan;
  FTabLabels[2] := lblTabComponentMap;
  FTabLabels[3] := lblTabPropertyMap;
  FTabLabels[4] := lblTabEventMap;
  FTabLabels[5] := lblTabIssues;
  FTabLabels[6] := lblTabRules;

  FTabScrollBoxes[0] := DashboardScrollBox;
  FTabScrollBoxes[1] := ProjectScanScrollBox;
  FTabScrollBoxes[2] := ComponentMapScrollBox;
  FTabScrollBoxes[3] := PropertyMapScrollBox;
  FTabScrollBoxes[4] := EventMapScrollBox;
  FTabScrollBoxes[5] := IssuesScrollBox;
  FTabScrollBoxes[6] := RulesScrollBox;

end;

procedure TfrmMain.ApplyTabTheme;
begin
  BuildTabChrome;
  UpdateTabChrome;
end;

procedure TfrmMain.UpdateTabChrome;
const
  ActiveFill = TAlphaColor($FF5A93E8);
  ActiveStroke = TAlphaColor($FFB7D3FF);
  InactiveFill = TAlphaColor($FF3C6CB5);
  InactiveStroke = TAlphaColor($FF6F9BDA);
  ActiveText = TAlphaColor($FFFFFFFF);
  InactiveText = TAlphaColor($FFEAF4FF);
var
  I: Integer;
begin
  if not Assigned(FTabButtons[0]) then
    Exit;

  for I := Low(FTabButtons) to High(FTabButtons) do
  begin
    if not Assigned(FTabButtons[I]) or not Assigned(FTabLabels[I]) then
      Continue;

    if GetTabForNavIndex(I) = TabControlMain.ActiveTab then
    begin
      FTabButtons[I].Fill.Color := ActiveFill;
      FTabButtons[I].Stroke.Color := ActiveStroke;
      FTabLabels[I].TextSettings.FontColor := ActiveText;
    end
    else
    begin
      FTabButtons[I].Fill.Color := InactiveFill;
      FTabButtons[I].Stroke.Color := InactiveStroke;
      FTabLabels[I].TextSettings.FontColor := InactiveText;
    end;
  end;
end;

procedure TfrmMain.TabNavClick(Sender: TObject);
var
  NavIndex: Integer;
begin
  if not (Sender is TRectangle) then
    Exit;

  NavIndex := TRectangle(Sender).Tag;
  TabControlMain.ActiveTab := GetTabForNavIndex(NavIndex);
  UpdateTabChrome;
end;

procedure TfrmMain.ResetArtifacts;
begin
  FLastOutputPath := '';
  FLastTextReportPath := '';
  FLastHTMLReportPath := '';
  ResetRunSummary;

  lblStatusValue.Text := 'Ready to convert';
  lblDashboardStatusValue.Text := 'No run started yet.';
  lblDashboardOutputValue.Text := 'No output folder selected yet.';
  lblDashboardReportValue.Text := 'No report yet.';
  lblDashboardReportValue.Hint := '';
  lblIssuesReportValue.Text := 'No report yet.';
  lblIssuesReportValue.Hint := '';
  lblIssuesOutputValue.Text := 'No output folder selected yet.';

  UpdateConversionOutputSummary(False);
  UpdateReportActions;
end;

procedure TfrmMain.ResetToStartupState;
var
  I: Integer;
begin
  edtSource.Text := '';
  edtTarget.Text := '';
  cmbFileTypes.ItemIndex := 2;

  chkRecursive.IsChecked := True;
  chkCritical.IsChecked := True;
  chkDataAware.IsChecked := True;
  chkThirdParty.IsChecked := True;
  chkWinAPI.IsChecked := True;
  chkDryRunPreview.IsChecked := False;

  FPendingCompletion := Default(TConversionCompletionSnapshot);

  MemoLog.Lines.Text :=
    DATTranslateDynamicText(SDisplayChooseAVclSourceFolderAndAn);

  PopulateReferencePages;
  LoadComponentMapReference;
  LoadPropertyMapReference;
  LoadEventMapReference;

  ResetArtifacts;
  UpdateRuleSummary;
  UpdateUIForConversion(False);

  for I := Low(FTabScrollBoxes) to High(FTabScrollBoxes) do
    if Assigned(FTabScrollBoxes[I]) then
      FTabScrollBoxes[I].ViewportPosition := PointF(0, 0);

  RulesSummaryScrollBox.ViewportPosition := PointF(0, 0);
  TabControlMain.ActiveTab := tabProjectScan;
  UpdateTabChrome;

  if edtSource.CanFocus then
    ActiveControl := edtSource;
end;

procedure TfrmMain.UpdateReportActions;
var
  PreferredReportPath: string;
begin
  PreferredReportPath := GetPreferredReportPath;
  btnOpenReport.Enabled := (PreferredReportPath <> '') and
    (not Assigned(FConversionThread));
  btnPrintReport.Enabled := btnOpenReport.Enabled;
  btnOpenOutput.Enabled := (FLastOutputPath <> '') and
    DirectoryExists(FLastOutputPath) and (not Assigned(FConversionThread));
end;

procedure TfrmMain.ResetRunSummary;
begin
  FHasCompletedRun := False;
  FLastRunStatusText := '';
  FLastFilesProcessed := 0;
  FLastFilesConverted := 0;
  FLastFilesWithErrors := 0;
  FLastFilesSkipped := 0;
  FLastManualReviewCount := 0;
  FLastBlockingCount := 0;
  FLastRunDurationText := '';
  FPendingCompletion := Default(TConversionCompletionSnapshot);
end;

function TfrmMain.FormatReportDisplayText(const ReportPath: string): string;
begin
  if Trim(ReportPath) = '' then
    Exit('No report yet.');

  Result := ExtractFileName(ReportPath);
  if Result = '' then
    Result := ReportPath;
end;

function TfrmMain.FormatDurationText(const AStartTime,
  AEndTime: TDateTime): string;
var
  TotalSeconds: Integer;
  Hours: Integer;
  Minutes: Integer;
  Seconds: Integer;
begin
  if (AStartTime <= 0) or (AEndTime <= 0) or (AEndTime < AStartTime) then
    Exit('00:00:00');

  TotalSeconds := Round((AEndTime - AStartTime) * 24 * 60 * 60);
  if TotalSeconds < 0 then
    TotalSeconds := 0;

  Hours := TotalSeconds div 3600;
  Minutes := (TotalSeconds mod 3600) div 60;
  Seconds := TotalSeconds mod 60;
  Result := Format('%.2d:%.2d:%.2d', [Hours, Minutes, Seconds]);
end;

procedure TfrmMain.UpdateConversionOutputSummary(const ARunning: Boolean);
var
  SummaryText: string;
begin
  if ARunning then
  begin
    SummaryText := 'Conversion is running. The live log below is updating in real time, and run totals will appear here when the pass finishes.';
  end
  else if FHasCompletedRun then
  begin
    SummaryText := Format('Last run: %s | Processed: %d | Converted: %d',
      [FLastRunStatusText, FLastFilesProcessed, FLastFilesConverted]);

    if FLastFilesWithErrors > 0 then
      SummaryText := SummaryText + Format(' | Errors: %d', [FLastFilesWithErrors]);

    if FLastFilesSkipped > 0 then
      SummaryText := SummaryText + Format(' | Skipped: %d', [FLastFilesSkipped]);

    SummaryText := SummaryText +
      Format(' | Manual review: %d | Blocking: %d | Duration: %s',
        [FLastManualReviewCount, FLastBlockingCount, FLastRunDurationText]);

    if FLastBlockingCount > 0 then
      SummaryText := SummaryText + ' | Next: fix blocking items first and review the report.'
    else if FLastManualReviewCount > 0 then
      SummaryText := SummaryText + ' | Next: review grouped manual-review items in the report and IDE.'
    else
      SummaryText := SummaryText + ' | Next: do a final report check before relying on the output.';
  end
  else
  begin
    SummaryText := 'Monitor the live conversion log here, then open or print the generated report after the run finishes.';
  end;

  lblIssuesSummaryHint.Text := SummaryText;
end;

procedure TfrmMain.UpdateRuleSummary;

  function EnabledText(Value: Boolean): string;
  begin
    if Value then
      Result := 'On'
    else
      Result := 'Off';
  end;

begin
  lblDashboardModulesValue.Text :=
    'Critical Areas: ' + EnabledText(chkCritical.IsChecked) + sLineBreak +
    'Data Aware: ' + EnabledText(chkDataAware.IsChecked) + sLineBreak +
    '3rd Party: ' + EnabledText(chkThirdParty.IsChecked) + sLineBreak +
    'WinAPI: ' + EnabledText(chkWinAPI.IsChecked) + sLineBreak +
    'Dry-run preview: ' + EnabledText(chkDryRunPreview.IsChecked);

  lblRulesSummaryValue.Text :=
    'Critical Areas = ' + EnabledText(chkCritical.IsChecked) + sLineBreak +
    'Data Aware = ' + EnabledText(chkDataAware.IsChecked) + sLineBreak +
    '3rd Party = ' + EnabledText(chkThirdParty.IsChecked) + sLineBreak +
    'WinAPI = ' + EnabledText(chkWinAPI.IsChecked) + sLineBreak +
    'Dry-run preview = ' + EnabledText(chkDryRunPreview.IsChecked);
end;

procedure TfrmMain.RuleOptionChanged(Sender: TObject);
begin
  UpdateRuleSummary;
end;

procedure TfrmMain.TabControlMainChange(Sender: TObject);
begin
  UpdateTabChrome;
end;

procedure TfrmMain.UpdateUIForConversion(Starting: Boolean);
begin
  btnConvert.Enabled := not Starting;
  btnReset.Enabled := not Starting;
  btnBrowseSource.Enabled := not Starting;
  btnBrowseTarget.Enabled := not Starting;
  cmbFileTypes.Enabled := not Starting;
  chkRecursive.Enabled := not Starting;
  chkCritical.Enabled := not Starting;
  chkDataAware.Enabled := not Starting;
  chkThirdParty.Enabled := not Starting;
  chkWinAPI.Enabled := not Starting;
  chkDryRunPreview.Enabled := not Starting;

  if Starting then
  begin
    btnConvert.Text := 'Converting...';
    lblStatusValue.Text := 'Running conversion';
    btnOpenReport.Enabled := False;
    btnPrintReport.Enabled := False;
    btnOpenOutput.Enabled := False;
  end
  else
  begin
    btnConvert.Text := 'Convert Project';
    UpdateReportActions;
  end;
end;

procedure TfrmMain.Log(const Msg: string);
var
  LogMessage: string;
begin
  if FClosing then
    Exit;

  if TThread.CurrentThread.ThreadID = MainThreadID then
  begin
    MemoLog.Lines.Add(DATTranslateDynamicText(Msg));
    MemoLog.GoToTextEnd;
  end
  else
  begin
    LogMessage := Msg;
    TThread.Synchronize(nil,
      procedure
      begin
        MemoLog.Lines.Add(DATTranslateDynamicText(LogMessage));
        MemoLog.GoToTextEnd;
      end);
  end;
end;

procedure TfrmMain.ShowError(const Msg: string);
var
  ErrorMessage: string;
begin
  if FClosing then
    Exit;

  if TThread.CurrentThread.ThreadID = MainThreadID then
    TDialogService.ShowMessage('Error: ' + Msg)
  else
  begin
    ErrorMessage := Msg;
    TThread.Synchronize(nil,
      procedure
      begin
        TDialogService.ShowMessage('Error: ' + ErrorMessage);
      end);
  end;
end;

function TfrmMain.GetPreferredReportPath: string;
begin
  if FileExists(FLastHTMLReportPath) then
    Exit(FLastHTMLReportPath);

  if FileExists(FLastTextReportPath) then
    Exit(FLastTextReportPath);

  Result := '';
end;

procedure TfrmMain.UpdateArtifactsAfterConversion(const TargetPath,
  StatusText: string);
var
  PreferredReportPath: string;
begin
  FHasCompletedRun := True;
  FLastRunStatusText := StatusText;
  FLastFilesProcessed := FPendingCompletion.FilesProcessed;
  FLastFilesConverted := FPendingCompletion.FilesConverted;
  FLastFilesWithErrors := FPendingCompletion.FilesWithErrors;
  FLastFilesSkipped := FPendingCompletion.FilesSkipped;
  FLastManualReviewCount := FPendingCompletion.ManualReviewCount;
  FLastBlockingCount := FPendingCompletion.BlockingCount;
  FLastRunDurationText := FPendingCompletion.RunDurationText;
  FLastOutputPath := TargetPath;
  FLastTextReportPath := FPendingCompletion.TextReportPath;
  FLastHTMLReportPath := FPendingCompletion.HtmlReportPath;
  PreferredReportPath := GetPreferredReportPath;

  lblStatusValue.Text := StatusText;
  lblDashboardStatusValue.Text := StatusText;

  if Trim(TargetPath) <> '' then
  begin
    lblDashboardOutputValue.Text := TargetPath;
    lblIssuesOutputValue.Text := TargetPath;
  end
  else
  begin
    lblDashboardOutputValue.Text := 'No output folder selected yet.';
    lblIssuesOutputValue.Text := 'No output folder selected yet.';
  end;

  if PreferredReportPath <> '' then
  begin
    lblDashboardReportValue.Text := FormatReportDisplayText(PreferredReportPath);
    lblDashboardReportValue.Hint := PreferredReportPath;
    lblIssuesReportValue.Text := FormatReportDisplayText(PreferredReportPath);
    lblIssuesReportValue.Hint := PreferredReportPath;
  end
  else
  begin
    lblDashboardReportValue.Text := 'No report file was created for this run.';
    lblDashboardReportValue.Hint := '';
    lblIssuesReportValue.Text := 'No report file was created for this run.';
    lblIssuesReportValue.Hint := '';
  end;

  UpdateConversionOutputSummary(False);
  UpdateReportActions;
end;

procedure TfrmMain.SuggestTargetFromSource(const SourcePath: string);
var
  SourceFolder: string;
  ParentFolder: string;
  SuggestedName: string;
begin
  if Trim(edtTarget.Text) <> '' then
    Exit;

  SourceFolder := ExcludeTrailingPathDelimiter(SourcePath);
  if SourceFolder = '' then
    Exit;

  ParentFolder := ExtractFileDir(SourceFolder);
  SuggestedName := ExtractFileName(SourceFolder);
  if (ParentFolder = '') or (SuggestedName = '') then
    Exit;

  edtTarget.Text := IncludeTrailingPathDelimiter(ParentFolder) +
    SuggestedName + ' - FMX Output';
end;

procedure TfrmMain.CompleteConversionOnUIThread;
begin
  if FClosing then
    Exit;
  FreeAndNil(FConversionThread);
  UpdateUIForConversion(False);
  UpdateArtifactsAfterConversion(FPendingCompletion.TargetPath,
    FPendingCompletion.StatusText);
end;

procedure TfrmMain.btnCloseAppClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnResetClick(Sender: TObject);
begin
  if Assigned(FConversionThread) then
  begin
    TDialogService.ShowMessage(
      'Please wait for the current conversion to finish before resetting.');
    Exit;
  end;

  ResetToStartupState;
end;

procedure TfrmMain.btnHelpClick(Sender: TObject);
var
  HelpTarget: string;
begin
  if not FileExists(FHelpRoot + 'index.html') then
  begin
    TDialogService.ShowMessage(
      'The VCL2FMXConverter help documentation could not be found.');
    Exit;
  end;

  try
    // The designer-owned server listens only on this PC, on an available port.
    // HTTP lets the free website widget work without publishing any Help files.
    HelpServer.Active := True;
    HelpTarget := 'http://127.0.0.1:' + IntToStr(HelpServer.Bindings[0].Port) +
      '/index.html?lang=' + TNetEncoding.URL.Encode(DATActiveLanguageCode);
  except
    // The installed English manual remains available if local hosting fails.
    HelpTarget := FHelpRoot + 'index.html';
  end;
  if not ExecuteShellVerb('open', HelpTarget) then
    TDialogService.ShowMessage(
      'Could not open the VCL2FMXConverter help documentation.');
end;

procedure TfrmMain.HelpServerCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  RelativePath, FileName, Extension: string;
begin
  AResponseInfo.CloseConnection := True;
  AResponseInfo.ContentType := 'text/plain';
  AResponseInfo.CharSet := 'utf-8';
  AResponseInfo.CustomHeaders.Values['Cache-Control'] := 'no-store';
  AResponseInfo.CustomHeaders.Values['X-Content-Type-Options'] := 'nosniff';
  if not SameText(ARequestInfo.Command, 'GET') and
     not SameText(ARequestInfo.Command, 'HEAD') then
  begin
    AResponseInfo.ResponseNo := 405;
    Exit;
  end;
  if not SameText(ARequestInfo.Host, '127.0.0.1:' +
    IntToStr(HelpServer.Bindings[0].Port)) then
  begin
    AResponseInfo.ResponseNo := 403;
    Exit;
  end;
  try
    RelativePath := TNetEncoding.URL.Decode(ARequestInfo.Document);
    if RelativePath = '/' then
      RelativePath := '/index.html';
    if not RelativePath.StartsWith('/') or RelativePath.Contains(':') or
       RelativePath.Contains('\') or RelativePath.Contains(#0) then
    begin
      AResponseInfo.ResponseNo := 403;
      Exit;
    end;
    FileName := ExpandFileName(FHelpRoot +
      StringReplace(Copy(RelativePath, 2, MaxInt), '/', '\', [rfReplaceAll]));
    if not SameText(Copy(FileName, 1, Length(FHelpRoot)), FHelpRoot) then
    begin
      AResponseInfo.ResponseNo := 403;
      Exit;
    end;
    if not FileExists(FileName) then
    begin
      AResponseInfo.ResponseNo := 404;
      Exit;
    end;
    Extension := LowerCase(ExtractFileExt(FileName));
    if Extension = '.html' then AResponseInfo.ContentType := 'text/html'
    else if Extension = '.css' then AResponseInfo.ContentType := 'text/css'
    else if Extension = '.js' then AResponseInfo.ContentType := 'text/javascript'
    else if Extension = '.json' then AResponseInfo.ContentType := 'application/json'
    else if Extension = '.svg' then AResponseInfo.ContentType := 'image/svg+xml'
    else if Extension = '.png' then AResponseInfo.ContentType := 'image/png'
    else if (Extension = '.jpg') or (Extension = '.jpeg') then AResponseInfo.ContentType := 'image/jpeg'
    else if Extension = '.gif' then AResponseInfo.ContentType := 'image/gif'
    else if Extension = '.ico' then AResponseInfo.ContentType := 'image/x-icon'
    else
    begin
      AResponseInfo.ResponseNo := 403;
      Exit;
    end;
    AResponseInfo.ContentStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    AResponseInfo.FreeContentStream := True;
  except
    AResponseInfo.ResponseNo := 500;
    AResponseInfo.ContentText := 'Help content is unavailable.';
  end;
end;
function TfrmMain.ExecuteShellVerb(const AVerb, ATarget: string;
  const HideWindow: Boolean): Boolean;
{$IFDEF MSWINDOWS}
var
  ShowCmd: Integer;
{$ENDIF}
begin
  Result := False;
  if Trim(ATarget) = '' then
    Exit;

  {$IFDEF MSWINDOWS}
  if HideWindow then
    ShowCmd := SW_HIDE
  else
    ShowCmd := SW_SHOWNORMAL;

  Result := NativeInt(ShellExecute(0, PChar(AVerb), PChar(ATarget), nil, nil,
    ShowCmd)) > 32;
  {$ENDIF}
end;

procedure TfrmMain.btnBrowseSourceClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtSource.Text;
  if SelectDirectory('Select Source Folder', '', Dir) then
  begin
    edtSource.Text := Dir;
    SuggestTargetFromSource(Dir);
  end;
end;

procedure TfrmMain.btnBrowseTargetClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtTarget.Text;
  if SelectDirectory('Select Target Folder', '', Dir) then
    edtTarget.Text := Dir;
end;

procedure TfrmMain.btnOpenOutputClick(Sender: TObject);
begin
  if not DirectoryExists(FLastOutputPath) then
  begin
    TDialogService.ShowMessage(
      'There is no converted output folder to open yet.');
    Exit;
  end;

  if not ExecuteShellVerb('open', FLastOutputPath) then
    TDialogService.ShowMessage(
      'Could not open the output folder from the converter.');
end;

procedure TfrmMain.btnOpenReportClick(Sender: TObject);
var
  ReportPath: string;
begin
  ReportPath := GetPreferredReportPath;
  if ReportPath = '' then
  begin
    TDialogService.ShowMessage(
      'There is no generated report to open yet.');
    Exit;
  end;

  if not ExecuteShellVerb('open', ReportPath) then
    TDialogService.ShowMessage(
      'Could not open the report from the converter.');
end;

procedure TfrmMain.btnPrintReportClick(Sender: TObject);
var
  ReportPath: string;
begin
  ReportPath := GetPreferredReportPath;
  if ReportPath = '' then
  begin
    TDialogService.ShowMessage(
      'There is no generated report to print yet.');
    Exit;
  end;

  if not ExecuteShellVerb('print', ReportPath, True) then
  begin
    ExecuteShellVerb('open', ReportPath);
    TDialogService.ShowMessage(
      'Direct printing was not available for the report file type, so the report was opened instead.');
  end;
end;

procedure TfrmMain.btnConvertClick(Sender: TObject);
var
  Src: string;
  Dst: string;
  FileTypeIndex: Integer;
  Recursive: Boolean;
  EnableCritical: Boolean;
  EnableDataAware: Boolean;
  EnableThirdParty: Boolean;
  EnableWinAPI: Boolean;
  DryRunPreview: Boolean;
  ReportLanguage: string;
begin
  if Assigned(FConversionThread) then
  begin
    TDialogService.ShowMessage('A conversion is already running.');
    Exit;
  end;

  Src := edtSource.Text.Trim;
  Dst := edtTarget.Text.Trim;

  if Src = '' then
  begin
    TDialogService.ShowMessage('Please select a source folder.');
    TabControlMain.ActiveTab := tabProjectScan;
    Exit;
  end;

  if Dst = '' then
  begin
    TDialogService.ShowMessage('Please select a target folder.');
    TabControlMain.ActiveTab := tabProjectScan;
    Exit;
  end;

  if not DirectoryExists(Src) then
  begin
    TDialogService.ShowMessage('Source folder does not exist.');
    TabControlMain.ActiveTab := tabProjectScan;
    Exit;
  end;

  if SameText(ExcludeTrailingPathDelimiter(ExpandFileName(Src)),
    ExcludeTrailingPathDelimiter(ExpandFileName(Dst))) then
  begin
    TDialogService.ShowMessage(
      'Please choose a different output folder. The source and target folders should not be the same.');
    TabControlMain.ActiveTab := tabProjectScan;
    Exit;
  end;

  MemoLog.Lines.Clear;
  MemoLog.Lines.Add(DATTranslateDynamicText(SDisplayPreparingConversion));
  TabControlMain.ActiveTab := tabIssues;

  FileTypeIndex := cmbFileTypes.ItemIndex;
  Recursive := chkRecursive.IsChecked;
  EnableCritical := chkCritical.IsChecked;
  EnableDataAware := chkDataAware.IsChecked;
  EnableThirdParty := chkThirdParty.IsChecked;
  EnableWinAPI := chkWinAPI.IsChecked;
  DryRunPreview := chkDryRunPreview.IsChecked;
  ReportLanguage := DATActiveLanguageCode;

  FLastOutputPath := Dst;
  FLastTextReportPath := '';
  FLastHTMLReportPath := '';
  FPendingCompletion := Default(TConversionCompletionSnapshot);
  lblDashboardOutputValue.Text := Dst;
  lblIssuesOutputValue.Text := Dst;
  lblDashboardReportValue.Text := 'Report will appear here after this run.';
  lblIssuesReportValue.Text := 'Report will appear here after this run.';
  UpdateConversionOutputSummary(True);

  UpdateUIForConversion(True);

  FConversionThread := TThread.CreateAnonymousThread(
    procedure
    var
      Completion: TConversionCompletionSnapshot;
      StatusText: string;
    begin
      Completion := Default(TConversionCompletionSnapshot);
      Completion.TargetPath := Dst;
      StatusText := 'Conversion failed';
      try
        StatusText := ConversionThreadProc(Src, Dst, ReportLanguage, FileTypeIndex, Recursive,
          EnableCritical, EnableDataAware, EnableThirdParty, EnableWinAPI,
          DryRunPreview, Completion);
      finally
        Completion.TargetPath := Dst;
        Completion.StatusText := StatusText;
        TThread.Queue(TThread.CurrentThread,
          procedure
          begin
            if FClosing then
              Exit;
            FPendingCompletion := Completion;
            CompleteConversionOnUIThread;
          end);
      end;
    end);
  FConversionThread.FreeOnTerminate := False;
  FConversionThread.Start;
end;

function TfrmMain.ConversionThreadProc(SourcePath, TargetPath, ReportLanguage: string;
  FileTypeIndex: Integer; Recursive, EnableCritical, EnableDataAware,
  EnableThirdParty, EnableWinAPI, DryRunPreview: Boolean;
  var Completion: TConversionCompletionSnapshot): string;
var
  Context: TConversionContext;
  Engine: TConverterEngine;
  ReportRuntime: TTranslationRuntime;
begin
  Result := 'Conversion failed';
  Completion := Default(TConversionCompletionSnapshot);
  Completion.TargetPath := TargetPath;
  Completion.StatusText := Result;

  try
    Context := TConversionContext.Create;
    try
      Context.Options.SourcePath := SourcePath;
      Context.Options.OutputPath := TargetPath;
      Context.Options.ProcessSubdirectories := Recursive;
      Context.Options.CreateReport := True;
      Context.Options.EnableCriticalAreas := EnableCritical;
      Context.Options.EnableDataAware := EnableDataAware;
      Context.Options.EnableThirdParty := EnableThirdParty;
      Context.Options.EnableWinAPI := EnableWinAPI;
      Context.Options.DryRunPreview := DryRunPreview;

      case FileTypeIndex of
        0: Context.Options.FileTypes := ftPas;
        1: Context.Options.FileTypes := ftDfm;
      else
        Context.Options.FileTypes := ftBoth;
      end;

      Log(SDisplayStartingConversionEngine);

      Engine := TConverterEngine.Create(Context);
      ReportRuntime := nil;
      try
        ReportRuntime := TTranslationRuntime.Create('VCL2FMXConverter',
          System.IOUtils.TPath.Combine(ExtractFilePath(ParamStr(0)), 'Localization\Languages'),
          System.IOUtils.TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'VCL2FMXConverter\report-language.ini'),
          'en-US', 'FireMonkey');
        if not ReportRuntime.LoadLanguage(ReportLanguage) then
          raise Exception.Create('The selected report language pack could not be loaded.');
        Engine.ReportLanguageCode := ReportLanguage;
        Engine.ReportTextDirection := 'ltr';
        if Assigned(ReportRuntime.ActivePack) then
          Engine.ReportTextDirection := ReportRuntime.ActivePack.TextDirection;
        Engine.ReportTextTranslator := function(Text: string): string
          begin Result := ReportRuntime.TranslateDynamicText(Text); end;
        Engine.ReportHtmlTranslator := function(Text: string): string
          begin Result := ReportRuntime.TranslateHtmlText(Text); end;
        TMonitor.Enter(FActiveEngineLock);
        try
          FActiveEngine := Engine;
        finally
          TMonitor.Exit(FActiveEngineLock);
        end;

        Engine.LogCallback :=
          procedure(MessageText: string)
          begin
            Log(MessageText);
          end;
        Engine.Convert(Context);
        Completion.TextReportPath := Engine.TextReportPath;
        Completion.HtmlReportPath := Engine.HtmlReportPath;

        Completion.FilesProcessed := Engine.FilesProcessed;
        Completion.FilesConverted := Engine.FilesConverted;
        Completion.FilesWithErrors := Engine.FilesWithErrors;
        Completion.FilesSkipped := Engine.FilesSkipped;
        Completion.ManualReviewCount := Context.CountManualReviewIssues;
        Completion.BlockingCount := Context.CountBlockingIssues;
        Completion.RunDurationText := FormatDurationText(Engine.StartTime,
          Engine.EndTime);

        if (Engine.FilesWithErrors > 0) or Context.HasBlockingIssues then
          Result := 'Blocking issues present'
        else if Context.HasManualReviewIssues then
          Result := 'Manual review required'
        else
          Result := 'Clean conversion';

        Completion.StatusText := Result;
      finally
        TMonitor.Enter(FActiveEngineLock);
        try
          if FActiveEngine = Engine then
            FActiveEngine := nil;
        finally
          TMonitor.Exit(FActiveEngineLock);
        end;
        Engine.Free;
        ReportRuntime.Free;
      end;
    finally
      Context.Free;
    end;
  except
    on E: Exception do
    begin
      ShowError(E.Message);
      Result := 'Conversion failed';
      Completion.StatusText := Result;
    end;
  end;
end;

end.
