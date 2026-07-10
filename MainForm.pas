{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit MainForm;

interface

{$IFNDEF MSWINDOWS}
  {$MESSAGE FATAL 'VCL2FMXConverter v5.0 Vanguard desktop UI is currently supported only on Windows.'}
{$ENDIF}

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
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
  end;

  TfrmMain = class(TForm)
    RootLayout: TLayout;
    HeroCard: TRectangle;
    HeroBackgroundPaintBox: TPaintBox;
    HeroAccentRibbonLarge: TRectangle;
    HeroAccentRibbonMid: TRectangle;
    HeroAccentRibbonSmall: TRectangle;
    HeroVanguardGhost: TLabel;
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
    TabControlMain: TTabControl;
    tabDashboard: TTabItem;
    tabProjectScan: TTabItem;
    tabComponentMap: TTabItem;
    tabPropertyMap: TTabItem;
    tabEventMap: TTabItem;
    tabIssues: TTabItem;
    tabRules: TTabItem;
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
    ProjectActionCard: TRectangle;
    lblProjectActionTitle: TLabel;
    lblProjectActionBody: TLabel;
    btnOpenOutput: TButton;
    ComponentCard: TRectangle;
    lblComponentTitle: TLabel;
    lblComponentHint: TLabel;
    MemoComponentMap: TMemo;
    PropertyCard: TRectangle;
    lblPropertyTitle: TLabel;
    lblPropertyHint: TLabel;
    MemoPropertyMap: TMemo;
    EventCard: TRectangle;
    lblEventTitle: TLabel;
    lblEventHint: TLabel;
    MemoEventMap: TMemo;
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
    procedure btnOpenOutputClick(Sender: TObject);
    procedure btnCloseAppClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure RuleOptionChanged(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure TabControlMainChange(Sender: TObject);
    procedure HeroBackgroundPaint(Sender: TObject; Canvas: TCanvas);
  private
    FConversionThread: TThread;
    FLastOutputPath: string;
    FLastTextReportPath: string;
    FLastHTMLReportPath: string;
    FPendingCompletion: TConversionCompletionSnapshot;
    FTabButtons: array[0..6] of TRectangle;
    FTabLabels: array[0..6] of TLabel;
    FTabScrollBoxes: array[0..6] of TVertScrollBox;
    FFormShown: Boolean;
    FComponentMapBrowser: TWebBrowser;
    FComponentMapHtml: string;
    FComponentMapPlainText: string;
    FPropertyMapBrowser: TWebBrowser;
    FPropertyMapHtml: string;
    FPropertyMapPlainText: string;
    FEventMapBrowser: TWebBrowser;
    FEventMapHtml: string;
    FEventMapPlainText: string;
    FHasCompletedRun: Boolean;
    FLastRunStatusText: string;
    FLastFilesProcessed: Integer;
    FLastFilesConverted: Integer;
    FLastFilesWithErrors: Integer;
    FLastFilesSkipped: Integer;
    FLastManualReviewCount: Integer;
    FLastBlockingCount: Integer;
    FLastRunDurationText: string;
    FDryRunPreviewCheckBox: TCheckBox;
    procedure Log(const Msg: string);
    function ConversionThreadProc(SourcePath, TargetPath: string;
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
    procedure ApplyResponsiveLayout;
    procedure CompleteConversionOnUIThread;
    procedure ResetRunSummary;
    procedure UpdateConversionOutputSummary(const ARunning: Boolean);
    function FormatReportDisplayText(const ReportPath: string): string;
    function FormatDurationText(const AStartTime, AEndTime: TDateTime): string;
    function SourceFolderContainsVCL2FMXReport(const SourcePath: string): Boolean;
    procedure ShowInvalidConvertedSourceFolderDialog;
    procedure WrapTabInVerticalScroll(const ATab: TTabItem;
      var AScrollBox: TVertScrollBox; const AChildNames: array of string);
    procedure ShowError(const Msg: string);
    function GetTextReportPath(const TargetPath: string): string;
    function GetHTMLReportPath(const TargetPath: string): string;
    function GetPreferredReportPath: string;
    function ExecuteShellVerb(const AVerb, ATarget: string;
      const HideWindow: Boolean = False): Boolean;
    procedure BuildTabChrome;
    procedure ApplyTabTheme;
    procedure UpdateTabChrome;
    procedure TabNavClick(Sender: TObject);
    function GetTabForNavIndex(const AIndex: Integer): TTabItem;
    procedure EnsureComponentMapBrowser;
    procedure UpdateComponentMapBrowserBounds;
    procedure LoadComponentMapReference;
    procedure BuildComponentMapContent(out AHtml, APlainText: string);
    procedure EnsurePropertyMapBrowser;
    procedure UpdatePropertyMapBrowserBounds;
    procedure LoadPropertyMapReference;
    procedure BuildPropertyMapContent(out AHtml, APlainText: string);
    procedure EnsureEventMapBrowser;
    procedure UpdateEventMapBrowserBounds;
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

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  OnCloseQuery := FormCloseQuery;
  OnShow := FormShow;
  OnResize := FormResize;
  TabControlMain.OnChange := TabControlMainChange;

  cmbFileTypes.Items.Clear;
  cmbFileTypes.Items.Add('PAS files only');
  cmbFileTypes.Items.Add('DFM files only');
  cmbFileTypes.Items.Add('Both PAS and DFM');
  cmbFileTypes.ItemIndex := 2;

  edtSource.Text := '';
  edtTarget.Text := '';

  chkRecursive.IsChecked := True;
  chkCritical.IsChecked := True;
  chkDataAware.IsChecked := True;
  chkThirdParty.IsChecked := True;
  chkWinAPI.IsChecked := True;
  if Assigned(FDryRunPreviewCheckBox) then
    FDryRunPreviewCheckBox.IsChecked := False;
  if not Assigned(FDryRunPreviewCheckBox) then
  begin
    FDryRunPreviewCheckBox := TCheckBox.Create(Self);
    FDryRunPreviewCheckBox.Parent := ProjectCard;
    FDryRunPreviewCheckBox.Text := 'Dry-run preview';
    FDryRunPreviewCheckBox.StyledSettings := [TStyledSetting.Family, TStyledSetting.Style, TStyledSetting.FontColor];
    FDryRunPreviewCheckBox.TextSettings.Font.Size := 14;
    FDryRunPreviewCheckBox.Position.X := chkRecursive.Position.X + chkRecursive.Width + 28;
    FDryRunPreviewCheckBox.Position.Y := chkRecursive.Position.Y;
    FDryRunPreviewCheckBox.Width := 180;
    FDryRunPreviewCheckBox.Height := chkRecursive.Height;
    FDryRunPreviewCheckBox.IsChecked := False;
    FDryRunPreviewCheckBox.OnChange := RuleOptionChanged;
    FDryRunPreviewCheckBox.Hint := 'Create reports without writing converted source, form, or project files.';
  end;

  MemoLog.Lines.Text :=
    'Choose a VCL source folder and an FMX output folder, then start the conversion.';

  MemoComponentMap.ReadOnly := True;
  MemoPropertyMap.ReadOnly := True;
  MemoEventMap.ReadOnly := True;

  PopulateReferencePages;
  LoadComponentMapReference;
  LoadPropertyMapReference;
  LoadEventMapReference;
  ResetArtifacts;
  UpdateRuleSummary;
  UpdateUIForConversion(False);
  BuildTabChrome;
  TabControlMain.ActiveTab := tabProjectScan;
  UpdateTabChrome;
  ApplyResponsiveLayout;
end;

procedure TfrmMain.HeroBackgroundPaint(Sender: TObject; Canvas: TCanvas);

  procedure DrawWave(const ABaseY, AOffset, AThickness: Single;
    const AColor: TAlphaColor; const AOpacity: Single);
  var
    Path: TPathData;
  begin
    Path := TPathData.Create;
    try
      Path.MoveTo(PointF(-40, ABaseY + AOffset));
      Path.CurveTo(
        PointF(HeroCard.Width * 0.18, ABaseY - (HeroCard.Height * 0.22) + AOffset),
        PointF(HeroCard.Width * 0.38, ABaseY - (HeroCard.Height * 0.15) + AOffset),
        PointF(HeroCard.Width * 0.58, ABaseY + (HeroCard.Height * 0.02) + AOffset));
      Path.CurveTo(
        PointF(HeroCard.Width * 0.76, ABaseY + (HeroCard.Height * 0.18) + AOffset),
        PointF(HeroCard.Width * 0.94, ABaseY + (HeroCard.Height * 0.02) + AOffset),
        PointF(HeroCard.Width + 60, ABaseY - (HeroCard.Height * 0.32) + AOffset));

      Canvas.Stroke.Kind := TBrushKind.Solid;
      Canvas.Stroke.Color := AColor;
      Canvas.Stroke.Thickness := AThickness;
      Canvas.DrawPath(Path, AOpacity);
    finally
      Path.Free;
    end;
  end;

var
  H: Single;
  BaseY: Single;
  GhostRect: TRectF;
begin
  H := HeroCard.Height;

  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := $24FF8800;
  Canvas.Font.Family := 'Segoe UI';
  Canvas.Font.Size := H * 0.66;
  Canvas.Font.Style := [TFontStyle.fsBold];
  GhostRect := RectF(HeroCard.Width * 0.40, -H * 0.08,
    HeroCard.Width * 1.09, H * 0.68);
  Canvas.FillText(GhostRect, 'VANGUARD', False, 1.0, [], TTextAlign.Center,
    TTextAlign.Center);

  if H <= 140 then
    BaseY := H * 0.86
  else
    BaseY := H * 0.80;

  DrawWave(BaseY, -16, 1.1, $58FFFFFF, 0.20);
  DrawWave(BaseY, -7, 1.8, $72FFFFFF, 0.30);
  DrawWave(BaseY, 3, 1.3, $8CEAF4FF, 0.34);
  DrawWave(BaseY, 12, 3.2, $78FFFFFF, 0.28);
  DrawWave(BaseY, 20, 1.1, $44FFFFFF, 0.18);
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  FFormShown := True;
  WindowState := TWindowState.wsMaximized;
  if not Assigned(TabControlMain.ActiveTab) then
    TabControlMain.ActiveTab := tabDashboard;
  ApplyResponsiveLayout;
  ApplyTabTheme;
  if not Assigned(TabControlMain.ActiveTab) then
    TabControlMain.ActiveTab := tabDashboard;
  UpdateTabChrome;
  EnsureComponentMapBrowser;
  EnsurePropertyMapBrowser;
  EnsureEventMapBrowser;
  LoadComponentMapReference;
  LoadPropertyMapReference;
  LoadEventMapReference;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  ApplyResponsiveLayout;
end;

destructor TfrmMain.Destroy;
begin
  if Assigned(FConversionThread) then
  begin
    if FConversionThread.Finished then
      FreeAndNil(FConversionThread)
    else
      FConversionThread.FreeOnTerminate := True;
  end;
  FreeAndNil(FComponentMapBrowser);
  FreeAndNil(FPropertyMapBrowser);
  FreeAndNil(FEventMapBrowser);
  inherited;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Assigned(FConversionThread) and FConversionThread.Finished then
    FreeAndNil(FConversionThread);

  CanClose := not Assigned(FConversionThread);
  if not CanClose then
    TDialogService.ShowMessage(
      'A conversion is still running. Please wait for it to finish before closing the program.');
end;

function TfrmMain.SourceFolderContainsVCL2FMXReport(
  const SourcePath: string): Boolean;
var
  BasePath: string;
begin
  BasePath := IncludeTrailingPathDelimiter(SourcePath);
  Result :=
    FileExists(BasePath + 'VCL_to_FMX_Conversion_Report.html') or
    FileExists(BasePath + 'VCL_to_FMX_Conversion_Report.txt') or
    FileExists(BasePath + 'VCL_to_FMX_Compatibility_Analysis_Report.html') or
    FileExists(BasePath + 'VCL_to_FMX_Compatibility_Analysis_Report.txt');
end;

procedure TfrmMain.ShowInvalidConvertedSourceFolderDialog;
var
  DialogForm: TForm;
  Background: TRectangle;
  AccentBar: TRectangle;
  TitleLabel: TLabel;
  BodyLabel: TLabel;
  OKButton: TButton;
begin
  DialogForm := TForm.CreateNew(Self);
  DialogForm.Caption := 'Invalid Source Folder';
  DialogForm.Width := 760;
  DialogForm.Height := 470;
  DialogForm.Position := TFormPosition.MainFormCenter;

  Background := TRectangle.Create(DialogForm);
  Background.Parent := DialogForm;
  Background.Align := TAlignLayout.Contents;
  Background.Fill.Color := $FFF7FAFE;
  Background.Stroke.Color := $FFD6E4F3;
  Background.XRadius := 0;
  Background.YRadius := 0;

  AccentBar := TRectangle.Create(DialogForm);
  AccentBar.Parent := Background;
  AccentBar.Align := TAlignLayout.Top;
  AccentBar.Height := 92;
  AccentBar.Fill.Color := $FF2F6FCD;
  AccentBar.Stroke.Kind := TBrushKind.None;

  TitleLabel := TLabel.Create(DialogForm);
  TitleLabel.Parent := AccentBar;
  TitleLabel.Align := TAlignLayout.Client;
  TitleLabel.Margins.Left := 28;
  TitleLabel.Margins.Right := 28;
  TitleLabel.Text := 'Invalid Source Folder';
  TitleLabel.StyledSettings := [];
  TitleLabel.TextSettings.Font.Size := 34;
  TitleLabel.TextSettings.Font.Style := [TFontStyle.fsBold];
  TitleLabel.TextSettings.FontColor := TAlphaColorRec.White;
  TitleLabel.TextSettings.VertAlign := TTextAlign.Center;

  BodyLabel := TLabel.Create(DialogForm);
  BodyLabel.Parent := Background;
  BodyLabel.Position.X := 42;
  BodyLabel.Position.Y := 126;
  BodyLabel.Size.Width := 680;
  BodyLabel.Size.Height := 245;
  BodyLabel.WordWrap := True;
  BodyLabel.Text :=
    'The selected folder contains VCL2FMX conversion files and cannot be used.' + sLineBreak + sLineBreak +
    'It appears to contain a previous conversion session and therefore is not a valid VCL source folder.' + sLineBreak + sLineBreak +
    'Please select a valid VCL project folder that contains source .pas, .dfm, .dpr, and .dproj files.';
  BodyLabel.StyledSettings := [];
  BodyLabel.TextSettings.Font.Size := 20;
  BodyLabel.TextSettings.FontColor := $FF13314F;

  OKButton := TButton.Create(DialogForm);
  OKButton.Parent := Background;
  OKButton.Text := 'OK';
  OKButton.Width := 140;
  OKButton.Height := 52;
  OKButton.Position.X := DialogForm.Width - OKButton.Width - 48;
  OKButton.Position.Y := DialogForm.Height - OKButton.Height - 58;
  OKButton.StyledSettings := [];
  OKButton.TextSettings.Font.Size := 18;
  OKButton.ModalResult := mrOk;

  try
    DialogForm.ShowModal;
  finally
    DialogForm.Free;
  end;
end;

procedure TfrmMain.PopulateReferencePages;
begin
  lblComponentHint.Text :=
    'Generated from the built-in mapping database so operators can inspect real conversion coverage.';
  MemoComponentMap.Lines.Text := 'Building component mapping reference...';

  lblPropertyHint.Text :=
    'Generated from the live property-rule database so operators can inspect actual rename and transform behavior.';
  MemoPropertyMap.Lines.Text := 'Building property mapping reference...';

  lblEventHint.Text :=
    'Generated from the live event-rule database so operators can inspect mapped handlers and signature compatibility.';
  MemoEventMap.Lines.Text := 'Building event mapping reference...';
end;

procedure TfrmMain.EnsureComponentMapBrowser;
begin
  if Assigned(FComponentMapBrowser) then
  begin
    UpdateComponentMapBrowserBounds;
    Exit;
  end;

  try
    FComponentMapBrowser := TWebBrowser.Create(Self);
    FComponentMapBrowser.WindowsEngine := TWindowsEngine.EdgeIfAvailable;
    FComponentMapBrowser.Parent := ComponentCard;
    FComponentMapBrowser.Visible := False;
    UpdateComponentMapBrowserBounds;
    FComponentMapBrowser.BringToFront;
  except
    FreeAndNil(FComponentMapBrowser);
  end;
end;

procedure TfrmMain.UpdateComponentMapBrowserBounds;
begin
  if not Assigned(FComponentMapBrowser) then
    Exit;

  FComponentMapBrowser.Position.X := MemoComponentMap.Position.X;
  FComponentMapBrowser.Position.Y := MemoComponentMap.Position.Y;
  FComponentMapBrowser.Width := MemoComponentMap.Width;
  FComponentMapBrowser.Height := MemoComponentMap.Height;
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

  if FFormShown then
    EnsureComponentMapBrowser;

  if Assigned(FComponentMapBrowser) and (FComponentMapHtml <> '') then
    try
      UpdateComponentMapBrowserBounds;
      FComponentMapBrowser.LoadFromStrings(FComponentMapHtml, TEncoding.UTF8,
        'about:blank');
      FComponentMapBrowser.Visible := True;
      FComponentMapBrowser.BringToFront;
      MemoComponentMap.Visible := False;
    except
      FComponentMapBrowser.Visible := False;
      MemoComponentMap.Visible := True;
    end
  else
    MemoComponentMap.Visible := True;
end;

procedure TfrmMain.EnsurePropertyMapBrowser;
begin
  if Assigned(FPropertyMapBrowser) then
  begin
    UpdatePropertyMapBrowserBounds;
    Exit;
  end;

  try
    FPropertyMapBrowser := TWebBrowser.Create(Self);
    FPropertyMapBrowser.WindowsEngine := TWindowsEngine.EdgeIfAvailable;
    FPropertyMapBrowser.Parent := PropertyCard;
    FPropertyMapBrowser.Visible := False;
    UpdatePropertyMapBrowserBounds;
    FPropertyMapBrowser.BringToFront;
  except
    FreeAndNil(FPropertyMapBrowser);
  end;
end;

procedure TfrmMain.UpdatePropertyMapBrowserBounds;
begin
  if not Assigned(FPropertyMapBrowser) then
    Exit;

  FPropertyMapBrowser.Position.X := MemoPropertyMap.Position.X;
  FPropertyMapBrowser.Position.Y := MemoPropertyMap.Position.Y;
  FPropertyMapBrowser.Width := MemoPropertyMap.Width;
  FPropertyMapBrowser.Height := MemoPropertyMap.Height;
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

  if FFormShown then
    EnsurePropertyMapBrowser;

  if Assigned(FPropertyMapBrowser) and (FPropertyMapHtml <> '') then
    try
      UpdatePropertyMapBrowserBounds;
      FPropertyMapBrowser.LoadFromStrings(FPropertyMapHtml, TEncoding.UTF8,
        'about:blank');
      FPropertyMapBrowser.Visible := True;
      FPropertyMapBrowser.BringToFront;
      MemoPropertyMap.Visible := False;
    except
      FPropertyMapBrowser.Visible := False;
      MemoPropertyMap.Visible := True;
    end
  else
    MemoPropertyMap.Visible := True;
end;

procedure TfrmMain.EnsureEventMapBrowser;
begin
  if Assigned(FEventMapBrowser) then
  begin
    UpdateEventMapBrowserBounds;
    Exit;
  end;

  try
    FEventMapBrowser := TWebBrowser.Create(Self);
    FEventMapBrowser.WindowsEngine := TWindowsEngine.EdgeIfAvailable;
    FEventMapBrowser.Parent := EventCard;
    FEventMapBrowser.Visible := False;
    UpdateEventMapBrowserBounds;
    FEventMapBrowser.BringToFront;
  except
    FreeAndNil(FEventMapBrowser);
  end;
end;

procedure TfrmMain.UpdateEventMapBrowserBounds;
begin
  if not Assigned(FEventMapBrowser) then
    Exit;

  FEventMapBrowser.Position.X := MemoEventMap.Position.X;
  FEventMapBrowser.Position.Y := MemoEventMap.Position.Y;
  FEventMapBrowser.Width := MemoEventMap.Width;
  FEventMapBrowser.Height := MemoEventMap.Height;
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

  if FFormShown then
    EnsureEventMapBrowser;

  if Assigned(FEventMapBrowser) and (FEventMapHtml <> '') then
    try
      UpdateEventMapBrowserBounds;
      FEventMapBrowser.LoadFromStrings(FEventMapHtml, TEncoding.UTF8,
        'about:blank');
      FEventMapBrowser.Visible := True;
      FEventMapBrowser.BringToFront;
      MemoEventMap.Visible := False;
    except
      FEventMapBrowser.Visible := False;
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

        AppendReferencePageHead(HtmlBuilder, 'Component Mapping Reference', 940,
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
        AppendReferenceHeroStart(HtmlBuilder, 'Component reference',
          'Component Mapping Reference',
          'Generated from the converter''s component mapping database and RTTI inventories for operator review and migration planning.');
        AppendReferenceMetricCard(HtmlBuilder, TotalMappings,
          'Discoverable components');
        AppendReferenceMetricCard(HtmlBuilder, DirectCount,
          'Direct conversions');
        AppendReferenceMetricCard(HtmlBuilder, SubstituteCount,
          'Substitute mappings');
        AppendReferenceMetricCard(HtmlBuilder, UnmappedCount,
          'Manual review');
        AppendReferenceHeroEnd(HtmlBuilder);
        AppendReferenceSectionStart(HtmlBuilder, 'Reference notes',
          'Each row shows a discoverable VCL component class, the FMX target class the converter currently routes toward, the mapping strategy, the confidence score, and any notes that still require operator attention. Property and event counts reflect the published VCL inventory currently discoverable for each source class.',
          '<thead><tr><th>VCL component</th><th>FMX target</th><th>Mapping</th><th>Confidence</th><th>Published properties</th><th>Published events</th><th>Notes</th></tr></thead>');

        AppendReferenceTextIntro(TextBuilder, 'Component mapping reference',
          'Built from the live mapping database and RTTI inventories.');

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
            FMXDisplay := 'Manual replacement required';

          NotesDisplay := Trim(Mapping.Notes);
          if NotesDisplay = '' then
            if SameText(Mapping.MappingType, 'Researched') then
              NotesDisplay := 'Derived from live RTTI and FMX catalog research.'
            else if SameText(Mapping.MappingType, 'Unmapped') then
              NotesDisplay := 'No suitable FMX component match is currently known.'
            else
              NotesDisplay := 'Standard built-in mapping with no additional notes.';

          MappingClass := GetMappingBadgeCssClass(Mapping.MappingType);

          HtmlBuilder.AppendLine('<tr>');
          HtmlBuilder.AppendFormat('<td><div class="component-name">%s</div></td>',
            [HtmlEncode(VCLClassName)]).AppendLine;
          if Mapping.FMXClassName <> '' then
            HtmlBuilder.AppendFormat('<td><div class="fmx-name">%s</div></td>',
              [HtmlEncode(FMXDisplay)]).AppendLine
          else
            HtmlBuilder.AppendFormat('<td><div class="missing">%s</div></td>',
              [HtmlEncode(FMXDisplay)]).AppendLine;
          HtmlBuilder.AppendFormat('<td><span class="badge %s">%s</span></td>',
            [MappingClass, HtmlEncode(Mapping.MappingType)]).AppendLine;
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
            [Mapping.MappingType, Mapping.Confidence]));
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
                  RuleKind := 'Transformed';
                  if HasExplicitRule then
                    NotesDisplay := 'Uses an explicit transformation rule from the built-in mapper.'
                  else if SameText(TargetDisplay, 'Fill.Color') then
                  begin
                    IsInventoryDerived := True;
                    NotesDisplay := 'Derived from converter heuristic: Color maps to Fill.Color using TransformColor.';
                  end
                  else
                  begin
                    IsInventoryDerived := True;
                    NotesDisplay := 'Derived from converter heuristic: Color requires TransformColor on the FMX target.';
                  end;
                end
                else if SameText(ResolvedPropMap.VCLProp, ResolvedPropMap.FMXProp) then
                begin
                  RuleKind := 'Direct';
                  if HasExplicitRule then
                    NotesDisplay := 'Uses an explicit direct property rule from the built-in mapper.'
                  else
                  begin
                    IsInventoryDerived := True;
                    NotesDisplay := 'Derived from RTTI inventory because the same published property exists on the FMX target.';
                  end;
                end
                else
                begin
                  RuleKind := 'Renamed';
                  if HasExplicitRule then
                    NotesDisplay := 'Uses an explicit renamed property rule from the built-in mapper.'
                  else
                  begin
                    IsInventoryDerived := True;
                    if SameText(PropName, 'Caption') and
                       SameText(TargetDisplay, 'Text') then
                      NotesDisplay := 'Derived from converter heuristic: Caption maps to Text on the FMX target.'
                    else
                      NotesDisplay := 'Derived from RTTI inventory because the property resolves to a different FMX target name.';
                  end;
                end;
              end
              else
              begin
                TargetDisplay := 'Manual review required';
                TransformerDisplay := '';
                RuleKind := 'Manual review';
                if HasExplicitRule then
                  NotesDisplay := 'No FMX target property is defined in the explicit mapper rule.'
                else if HasStoredRule then
                  NotesDisplay := 'The researched component mapping does not currently resolve this property to an FMX target.'
                else if not Assigned(Mapping) or (Trim(Mapping.FMXClassName) = '') then
                  NotesDisplay := 'This component does not currently resolve to an FMX target class.'
                else
                  NotesDisplay := 'No explicit or RTTI-derived FMX target property was identified.';
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
              RowsHtml.AppendFormat('<td><div class="component-name">%s</div></td>',
                [HtmlEncode(VCLClassName)]).AppendLine;
              RowsHtml.AppendFormat('<td><div class="prop-name">%s</div></td>',
                [HtmlEncode(PropName)]).AppendLine;
              if not SameText(TargetDisplay, 'Manual review required') then
                RowsHtml.AppendFormat('<td><div class="target-name">%s</div></td>',
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

              RowsText.AppendLine(Format('%s.%s -> %s',
                [VCLClassName, PropName, TargetDisplay]));
              RowsText.AppendLine('  Rule type: ' + RuleKind);
              RowsText.AppendLine('  Source type: ' + PropTypeName);
              if HasExplicitRule then
                RowsText.AppendLine('  Rule source: explicit mapper rule')
              else if IsInventoryDerived or ResolveSucceeded then
                RowsText.AppendLine('  Rule source: RTTI inventory')
              else
                RowsText.AppendLine('  Rule source: unresolved');
              RowsText.AppendLine('  Transformer: ' + TransformerDisplay);
              RowsText.AppendLine('  Notes: ' + NotesDisplay);
              RowsText.AppendLine('');
            end;
          finally
            PropertyNames.Free;
          end;
        end;

        AppendReferencePageHead(HtmlBuilder, 'Property Mapping Reference', 980,
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
        AppendReferenceHeroStart(HtmlBuilder, 'Property reference',
          'Property Mapping Reference',
          'Generated from the converter''s explicit property rules plus RTTI inventories so operators can review direct carries, renames, transformations, and review items before conversion.');
        AppendReferenceMetricCard(HtmlBuilder, TotalRules, 'Property rules');
        AppendReferenceMetricCard(HtmlBuilder, DirectRules, 'Direct rules');
        AppendReferenceMetricCard(HtmlBuilder, RenamedRules, 'Renamed rules');
        AppendReferenceMetricCard(HtmlBuilder, TransformedRules,
          'Transformed rules');
        AppendReferenceHeroEnd(HtmlBuilder);
        AppendReferenceSectionStart(HtmlBuilder, 'Reference notes',
          Format('This screen currently covers %d mapped component classes with discoverable published properties. Use it to verify when a property carries across unchanged, when the converter renames the target property, when a value transformation routine is required, and when a property still needs review.',
            [ComponentsWithRules]),
          '<thead><tr><th>VCL component</th><th>VCL property</th><th>FMX property</th><th>Rule type</th><th>Transformer</th><th>Notes</th></tr></thead>');

        AppendReferenceTextIntro(TextBuilder, 'Property mapping reference',
          'Built from explicit property rules plus RTTI inventories.');

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
                  RuleKind := 'Direct'
                else
                  RuleKind := 'Renamed';

                if ResolvedEventMap.SignatureMatch then
                  SignatureDisplay := 'Compatible'
                else
                  SignatureDisplay := 'Review required';

                if HasExplicitRule then
                begin
                  if SignatureDisplay = 'Compatible' then
                    NotesDisplay := 'Uses an explicit event rule from the built-in mapper.'
                  else
                    NotesDisplay := 'Uses an explicit event rule, but the stored signature check requires review.';
                end
                else
                begin
                  IsInventoryDerived := True;
                  if SignatureDisplay = 'Compatible' then
                    NotesDisplay := 'Derived from RTTI inventory because the same published event exists on the FMX target.'
                  else
                    NotesDisplay := 'Derived from RTTI inventory, but the event signatures require review.';
                end;
              end
              else
              begin
                TargetDisplay := 'Manual review required';
                RuleKind := 'Manual review';
                SignatureDisplay := 'Review required';
                if HasExplicitRule then
                  NotesDisplay := 'No FMX target event is defined in the explicit mapper rule.'
                else if HasStoredRule then
                  NotesDisplay := 'The researched component mapping does not currently resolve this event to an FMX target.'
                else if not Assigned(Mapping) or (Mapping.FMXClassName = '') then
                  NotesDisplay := 'This component does not currently resolve to an FMX target class.'
                else
                  NotesDisplay := 'No explicit or RTTI-derived FMX event was identified.';
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
              RowsHtml.AppendFormat('<td><div class="component-name">%s</div></td>',
                [HtmlEncode(VCLClassName)]).AppendLine;
              RowsHtml.AppendFormat('<td><div class="event-name">%s</div></td>',
                [HtmlEncode(EventName)]).AppendLine;
              if not SameText(TargetDisplay, 'Manual review required') then
                RowsHtml.AppendFormat('<td><div class="target-name">%s</div></td>',
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

              RowsText.AppendLine(Format('%s.%s -> %s',
                [VCLClassName, EventName, TargetDisplay]));
              RowsText.AppendLine('  Rule type: ' + RuleKind);
              if HasExplicitRule then
                RowsText.AppendLine('  Rule source: explicit mapper rule')
              else if IsInventoryDerived or ResolveSucceeded then
                RowsText.AppendLine('  Rule source: RTTI inventory')
              else
                RowsText.AppendLine('  Rule source: unresolved');
              RowsText.AppendLine('  VCL signature: ' + VCLSignature);
              if FMXSignature <> '' then
                RowsText.AppendLine('  FMX signature: ' + FMXSignature);
              RowsText.AppendLine('  Signature status: ' + SignatureDisplay);
              RowsText.AppendLine('  Notes: ' + NotesDisplay);
              RowsText.AppendLine('');
            end;
          finally
            EventNames.Free;
          end;
        end;

        AppendReferencePageHead(HtmlBuilder, 'Event Mapping Reference', 980,
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
        AppendReferenceHeroStart(HtmlBuilder, 'Event reference',
          'Event Mapping Reference',
          'Generated from the converter''s explicit event rules plus RTTI inventories so operators can review handler carry-forward, renamed targets, and signature compatibility.');
        AppendReferenceMetricCard(HtmlBuilder, TotalRules, 'Event rules');
        AppendReferenceMetricCard(HtmlBuilder, DirectRules, 'Direct events');
        AppendReferenceMetricCard(HtmlBuilder, RenamedRules, 'Renamed events');
        AppendReferenceMetricCard(HtmlBuilder, SignatureWarnings,
          'Signature review');
        AppendReferenceHeroEnd(HtmlBuilder);
        AppendReferenceSectionStart(HtmlBuilder, 'Reference notes',
          Format('This screen currently covers %d mapped component classes with discoverable published events. Use it to verify whether a VCL handler can carry forward directly, whether the target event name changes, and whether the mapped signatures remain compatible. Rows flagged for review need operator attention before relying on automatic migration.',
            [ComponentsWithRules]),
          '<thead><tr><th>VCL component</th><th>VCL event</th><th>FMX event</th><th>Rule type</th><th>Signature</th><th>Notes</th></tr></thead>');

        AppendReferenceTextIntro(TextBuilder, 'Event mapping reference',
          'Built from explicit event rules plus RTTI inventories.');

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
  ABuilder.AppendLine('.page { max-width: 1180px; margin: 0 auto; }');
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
var
  I: Integer;
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

  for I := Low(FTabButtons) to High(FTabButtons) do
    if Assigned(FTabButtons[I]) then
      FTabButtons[I].OnClick := TabNavClick;

  WrapTabInVerticalScroll(tabDashboard, FTabScrollBoxes[0],
    ['DashboardStatusCard', 'DashboardModulesCard', 'DashboardNextCard']);
  WrapTabInVerticalScroll(tabProjectScan, FTabScrollBoxes[1],
    ['ProjectCard', 'ProjectActionCard']);
  WrapTabInVerticalScroll(tabComponentMap, FTabScrollBoxes[2],
    ['ComponentCard']);
  WrapTabInVerticalScroll(tabPropertyMap, FTabScrollBoxes[3],
    ['PropertyCard']);
  WrapTabInVerticalScroll(tabEventMap, FTabScrollBoxes[4],
    ['EventCard']);
  WrapTabInVerticalScroll(tabIssues, FTabScrollBoxes[5],
    ['IssuesSummaryCard', 'IssuesLogCard']);
  WrapTabInVerticalScroll(tabRules, FTabScrollBoxes[6],
    ['RulesCard', 'RulesSummaryCard']);

  TabControlMain.TabPosition := TTabPosition.None;
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
  if Assigned(FDryRunPreviewCheckBox) then
    FDryRunPreviewCheckBox.IsChecked := False;

  FPendingCompletion := Default(TConversionCompletionSnapshot);

  MemoLog.Lines.Text :=
    'Choose a VCL source folder and an FMX output folder, then start the conversion.';

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

  TabControlMain.ActiveTab := tabProjectScan;
  UpdateTabChrome;
  ApplyResponsiveLayout;

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
    'Dry-run preview: ' + EnabledText(Assigned(FDryRunPreviewCheckBox) and
      FDryRunPreviewCheckBox.IsChecked);

  lblRulesSummaryValue.Text :=
    'Critical Areas = ' + EnabledText(chkCritical.IsChecked) + sLineBreak +
    'Data Aware = ' + EnabledText(chkDataAware.IsChecked) + sLineBreak +
    '3rd Party = ' + EnabledText(chkThirdParty.IsChecked) + sLineBreak +
    'WinAPI = ' + EnabledText(chkWinAPI.IsChecked) + sLineBreak +
    'Dry-run preview = ' + EnabledText(Assigned(FDryRunPreviewCheckBox) and
      FDryRunPreviewCheckBox.IsChecked);
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
  if Assigned(FDryRunPreviewCheckBox) then
    FDryRunPreviewCheckBox.Enabled := not Starting;

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
  if TThread.CurrentThread.ThreadID = MainThreadID then
  begin
    MemoLog.Lines.Add(Msg);
    MemoLog.GoToTextEnd;
  end
  else
  begin
    LogMessage := Msg;
    TThread.Synchronize(nil,
      procedure
      begin
        MemoLog.Lines.Add(LogMessage);
        MemoLog.GoToTextEnd;
      end);
  end;
end;

procedure TfrmMain.ShowError(const Msg: string);
var
  ErrorMessage: string;
begin
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

function TfrmMain.GetTextReportPath(const TargetPath: string): string;
begin
  if Trim(TargetPath) = '' then
    Exit('');
  Result := IncludeTrailingPathDelimiter(TargetPath) +
    'VCL_to_FMX_Conversion_Report.txt';
end;

function TfrmMain.GetHTMLReportPath(const TargetPath: string): string;
begin
  if Trim(TargetPath) = '' then
    Exit('');
  Result := IncludeTrailingPathDelimiter(TargetPath) +
    'VCL_to_FMX_Conversion_Report.html';
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
  FLastTextReportPath := GetTextReportPath(TargetPath);
  FLastHTMLReportPath := GetHTMLReportPath(TargetPath);
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

procedure TfrmMain.ApplyResponsiveLayout;
var
  CompactHeight: Boolean;
  I: Integer;
begin
  CompactHeight := ClientHeight <= 820;

  if CompactHeight then
  begin
    RootLayout.Padding.Left := 20;
    RootLayout.Padding.Top := 14;
    RootLayout.Padding.Right := 20;
    RootLayout.Padding.Bottom := 12;

    HeroCard.Height := 138;
    HeroAccentRibbonLarge.Visible := False;
    HeroAccentRibbonMid.Visible := False;
    HeroAccentRibbonSmall.Visible := False;
    HeroVanguardGhost.Position.X := 500;
    HeroVanguardGhost.Position.Y := -10;
    HeroVanguardGhost.Size.Width := 690;
    HeroVanguardGhost.Size.Height := 122;
    HeroVanguardGhost.TextSettings.Font.Size := 92;
    HeroBackgroundPaintBox.Repaint;
    lblHeader.Position.Y := 18;
    lblHeader.Size.Width := 620;
    lblHeader.TextSettings.Font.Size := 27;
    lblSubHeader.Visible := False;
    HeroVersionBadge.Position.X := 34;
    HeroVersionBadge.Position.Y := 58;
    HeroVersionBadge.Size.Width := 210;
    HeroVersionBadge.Size.Height := 28;
    lblVersion.Position.X := 49;
    lblVersion.Position.Y := 63;
    lblVersion.TextSettings.Font.Size := 13;
    lblStatusCaption.Position.Y := 18;
    lblStatusValue.Position.Y := 42;
    lblStatusValue.TextSettings.Font.Size := 22;
    btnConvert.Position.X := 700;
    btnConvert.Position.Y := 84;
    btnConvert.Size.Width := 166;
    btnConvert.Size.Height := 42;
    btnReset.Position.X := 896;
    btnReset.Position.Y := 86;
    btnReset.Size.Width := 112;
    btnOpenReport.Position.X := 1022;
    btnOpenReport.Position.Y := 86;
    btnOpenReport.Size.Width := 112;
    btnPrintReport.Position.X := 1148;
    btnPrintReport.Position.Y := 86;
    btnPrintReport.Size.Width := 112;

    TabNavBar.Margins.Top := 12;
    TabNavBar.Height := 44;
    TabControlMain.Margins.Top := 6;
    btnCloseApp.Height := 44;
    btnCloseApp.XRadius := 12;
    btnCloseApp.YRadius := 12;
    lblCloseApp.TextSettings.Font.Size := 12;

    DashboardStatusCard.Height := 194;
    DashboardModulesCard.Height := 194;
    lblDashboardStatusValue.Position.Y := 50;
    lblDashboardOutputTitle.Position.Y := 88;
    lblDashboardOutputValue.Position.Y := 110;
    lblDashboardOutputValue.Height := 30;
    lblDashboardReportTitle.Position.Y := 146;
    lblDashboardReportValue.Position.Y := 168;
    lblDashboardReportValue.Height := 24;
    DashboardNextCard.Position.Y := 216;
    DashboardNextCard.Height := 146;
    lblDashboardNextBody.Position.Y := 54;
    lblDashboardNextBody.Height := 88;

    ProjectCard.Height := 312;
    ProjectActionCard.Height := 312;

    ComponentCard.Height := 438;
    MemoComponentMap.Height := 330;
    PropertyCard.Height := 438;
    MemoPropertyMap.Height := 330;
    EventCard.Height := 438;
    MemoEventMap.Height := 330;

    IssuesSummaryCard.Height := 154;
    IssuesLogCard.Position.Y := 184;
    IssuesLogCard.Height := 226;
    MemoLog.Height := 144;

    RulesCard.Height := 472;
    RulesSummaryCard.Height := 472;
  end
  else
  begin
    RootLayout.Padding.Left := 28;
    RootLayout.Padding.Top := 24;
    RootLayout.Padding.Right := 28;
    RootLayout.Padding.Bottom := 24;

    HeroCard.Height := 176;
    HeroAccentRibbonLarge.Visible := False;
    HeroAccentRibbonMid.Visible := False;
    HeroAccentRibbonSmall.Visible := False;
    HeroVanguardGhost.Position.X := 520;
    HeroVanguardGhost.Position.Y := -12;
    HeroVanguardGhost.Size.Width := 700;
    HeroVanguardGhost.Size.Height := 150;
    HeroVanguardGhost.TextSettings.Font.Size := 112;
    HeroBackgroundPaintBox.Repaint;
    lblHeader.Position.Y := 26;
    lblHeader.Size.Width := 560;
    lblHeader.TextSettings.Font.Size := 31;
    lblSubHeader.Visible := False;
    HeroVersionBadge.Position.X := 40;
    HeroVersionBadge.Position.Y := 78;
    HeroVersionBadge.Size.Width := 224;
    HeroVersionBadge.Size.Height := 30;
    lblVersion.Position.X := 86;  // was 56 and too far left
    lblVersion.Position.Y := 84;
    lblVersion.TextSettings.Font.Size := 13;
    lblStatusCaption.Position.Y := 28;
    lblStatusValue.Position.Y := 52;
    lblStatusValue.TextSettings.Font.Size := 24;
    btnConvert.Position.X := 700;
    btnConvert.Position.Y := 118;
    btnConvert.Size.Width := 172;
    btnConvert.Size.Height := 38;
    btnReset.Position.X := 896;
    btnReset.Position.Y := 118;
    btnReset.Size.Width := 112;
    btnOpenReport.Position.X := 1022;
    btnOpenReport.Position.Y := 118;
    btnOpenReport.Size.Width := 112;
    btnPrintReport.Position.X := 1148;
    btnPrintReport.Position.Y := 118;
    btnPrintReport.Size.Width := 112;

    TabNavBar.Margins.Top := 18;
    TabNavBar.Height := 48;
    TabControlMain.Margins.Top := 8;
    btnCloseApp.Height := 48;
    btnCloseApp.XRadius := 14;
    btnCloseApp.YRadius := 14;
    lblCloseApp.TextSettings.Font.Size := 13;

    DashboardStatusCard.Height := 210;
    DashboardModulesCard.Height := 210;
    lblDashboardStatusValue.Position.Y := 50;
    lblDashboardOutputTitle.Position.Y := 90;
    lblDashboardOutputValue.Position.Y := 114;
    lblDashboardOutputValue.Height := 32;
    lblDashboardReportTitle.Position.Y := 150;
    lblDashboardReportValue.Position.Y := 172;
    lblDashboardReportValue.Height := 24;
    DashboardNextCard.Position.Y := 242;
    DashboardNextCard.Height := 188;
    lblDashboardNextBody.Position.Y := 56;
    lblDashboardNextBody.Height := 116;

    ProjectCard.Height := 334;
    ProjectActionCard.Height := 334;

    ComponentCard.Height := 500;
    MemoComponentMap.Height := 392;
    PropertyCard.Height := 500;
    MemoPropertyMap.Height := 392;
    EventCard.Height := 500;
    MemoEventMap.Height := 392;

    IssuesSummaryCard.Height := 164;
    IssuesLogCard.Position.Y := 194;
    IssuesLogCard.Height := 300;
    MemoLog.Height := 206;

    RulesCard.Height := 504;
    RulesSummaryCard.Height := 504;
  end;

  UpdateComponentMapBrowserBounds;
  UpdatePropertyMapBrowserBounds;
  UpdateEventMapBrowserBounds;

  for I := Low(FTabButtons) to High(FTabButtons) do
  begin
    if Assigned(FTabButtons[I]) then
    begin
      FTabButtons[I].Height := TabNavBar.Height;
      if CompactHeight then
      begin
        FTabButtons[I].XRadius := 12;
        FTabButtons[I].YRadius := 12;
      end
      else
      begin
        FTabButtons[I].XRadius := 14;
        FTabButtons[I].YRadius := 14;
      end;
    end;

    if Assigned(FTabLabels[I]) then
    begin
      if CompactHeight then
        FTabLabels[I].TextSettings.Font.Size := 12
      else
        FTabLabels[I].TextSettings.Font.Size := 13;
    end;
  end;
end;

procedure TfrmMain.WrapTabInVerticalScroll(const ATab: TTabItem;
  var AScrollBox: TVertScrollBox; const AChildNames: array of string);
var
  ChildIndex: Integer;
  ChildObject: TFmxObject;
begin
  if not Assigned(ATab) or Assigned(AScrollBox) then
    Exit;

  AScrollBox := TVertScrollBox.Create(Self);
  AScrollBox.Parent := ATab;
  AScrollBox.Align := TAlignLayout.Client;
  AScrollBox.ShowScrollBars := True;
  AScrollBox.Padding.Bottom := 18;

  for ChildIndex := Low(AChildNames) to High(AChildNames) do
  begin
    ChildObject := TFmxObject(FindComponent(AChildNames[ChildIndex]));
    if Assigned(ChildObject) and (ChildObject <> AScrollBox) then
      AScrollBox.AddObject(ChildObject);
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
    if SourceFolderContainsVCL2FMXReport(Dir) then
    begin
      ShowInvalidConvertedSourceFolderDialog;
      TabControlMain.ActiveTab := tabProjectScan;
      Exit;
    end;

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

  if SourceFolderContainsVCL2FMXReport(Src) then
  begin
    ShowInvalidConvertedSourceFolderDialog;
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
  MemoLog.Lines.Add('Preparing conversion...');
  TabControlMain.ActiveTab := tabIssues;

  FileTypeIndex := cmbFileTypes.ItemIndex;
  Recursive := chkRecursive.IsChecked;
  EnableCritical := chkCritical.IsChecked;
  EnableDataAware := chkDataAware.IsChecked;
  EnableThirdParty := chkThirdParty.IsChecked;
  EnableWinAPI := chkWinAPI.IsChecked;
  DryRunPreview := Assigned(FDryRunPreviewCheckBox) and
    FDryRunPreviewCheckBox.IsChecked;

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
        StatusText := ConversionThreadProc(Src, Dst, FileTypeIndex, Recursive,
          EnableCritical, EnableDataAware, EnableThirdParty, EnableWinAPI,
          DryRunPreview, Completion);
      finally
        Completion.TargetPath := Dst;
        Completion.StatusText := StatusText;
        TThread.Queue(nil,
          procedure
          begin
            FPendingCompletion := Completion;
            CompleteConversionOnUIThread;
          end);
      end;
    end);
  FConversionThread.FreeOnTerminate := False;
  FConversionThread.Start;
end;

function TfrmMain.ConversionThreadProc(SourcePath, TargetPath: string;
  FileTypeIndex: Integer; Recursive, EnableCritical, EnableDataAware,
  EnableThirdParty, EnableWinAPI, DryRunPreview: Boolean;
  var Completion: TConversionCompletionSnapshot): string;
var
  Context: TConversionContext;
  Engine: TConverterEngine;
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

      Log('Starting conversion engine...');

      Engine := TConverterEngine.Create(Context);
      try
        Engine.ScreenMemo := MemoLog;
        Engine.Convert(Context);

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
        Engine.Free;
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

