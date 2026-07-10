{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Advanced.ThirdParty;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  System.JSON, System.IOUtils, System.StrUtils,
  Converter.Core.Types;

type
  TThirdPartyInfo = class
  private
    FComponentName: string;
    FVendor: string;
    FIsCommercial: Boolean;
    FHasFMXVersion: Boolean;
    FFMXComponentName: string;
    FNotes: string;
    FReplacementSuggestion: string;
    FIsStandardVCL: Boolean;
    FIsSubComponent: Boolean;
    FStandardFMXEquivalent: string;
  public
    property ComponentName: string read FComponentName write FComponentName;
    property Vendor: string read FVendor write FVendor;
    property IsCommercial: Boolean read FIsCommercial write FIsCommercial;
    property HasFMXVersion: Boolean read FHasFMXVersion write FHasFMXVersion;
    property FMXComponentName: string read FFMXComponentName write FFMXComponentName;
    property Notes: string read FNotes write FNotes;
    property ReplacementSuggestion: string read FReplacementSuggestion
      write FReplacementSuggestion;
    property IsStandardVCL: Boolean read FIsStandardVCL write FIsStandardVCL;
    property IsSubComponent: Boolean read FIsSubComponent write FIsSubComponent;
    property StandardFMXEquivalent: string read FStandardFMXEquivalent write FStandardFMXEquivalent;

    constructor Create;
    function ToJSON: TJSONObject;
    class function FromJSON(JSON: TJSONObject): TThirdPartyInfo;
  end;

  TThirdPartyHandler = class
  private
    FContext: TConversionContext;
    FThirdPartyDB: TObjectList<TThirdPartyInfo>;
    FDetectedComponents: TDictionary<string, TThirdPartyInfo>;

    procedure LoadThirdPartyDatabase;
    procedure LoadRaizeComponents;
    procedure LoadDevExpressComponents;
    procedure LoadTMSComponents;
    procedure LoadJVCLComponents;
    procedure LoadGnosticeComponents;
    procedure LoadFastReports;
    procedure LoadEhLibComponents;
    procedure LoadBibliotecaGDComponents;
    procedure LoadStandardVCLComponents;
    procedure LoadSubComponentTypes;

    function DetectVendor(const ClassName: string): string;
    function IsStandardVCLComponent(const ClassName: string): Boolean;
    function IsSubComponentType(const ClassName: string): Boolean;
    function GetStandardFMXEquivalent(const ClassName: string): string;
    function StripTFromClassName(const ClassName: string): string;
    function NormalizeClassName(const ClassName: string): string;
  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    procedure AnalyzeComponent(const ClassName, ComponentName: string);
    function GetReplacementCode(const ClassName: string): string;
    procedure GenerateVendorNotes(var Report: TStringList);

    property DetectedComponents: TDictionary<string, TThirdPartyInfo>
      read FDetectedComponents;
  end;

implementation

{ TThirdPartyInfo }

constructor TThirdPartyInfo.Create;
begin
  FIsCommercial := False;
  FHasFMXVersion := False;
  FIsStandardVCL := False;
  FIsSubComponent := False;
end;

function TThirdPartyInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('component_name', FComponentName);
  Result.AddPair('vendor', FVendor);
  Result.AddPair('is_commercial', TJSONBool.Create(FIsCommercial));
  Result.AddPair('has_fmx_version', TJSONBool.Create(FHasFMXVersion));
  Result.AddPair('fmx_component_name', FFMXComponentName);
  Result.AddPair('notes', FNotes);
  Result.AddPair('replacement', FReplacementSuggestion);
  Result.AddPair('is_standard_vcl', TJSONBool.Create(FIsStandardVCL));
  Result.AddPair('is_subcomponent', TJSONBool.Create(FIsSubComponent));
  Result.AddPair('standard_fmx', FStandardFMXEquivalent);
end;

class function TThirdPartyInfo.FromJSON(JSON: TJSONObject): TThirdPartyInfo;
begin
  Result := TThirdPartyInfo.Create;
  Result.FComponentName := JSON.GetValue<string>('component_name', '');
  Result.FVendor := JSON.GetValue<string>('vendor', '');
  Result.FIsCommercial := JSON.GetValue<Boolean>('is_commercial', False);
  Result.FHasFMXVersion := JSON.GetValue<Boolean>('has_fmx_version', False);
  Result.FFMXComponentName := JSON.GetValue<string>('fmx_component_name', '');
  Result.FNotes := JSON.GetValue<string>('notes', '');
  Result.FReplacementSuggestion := JSON.GetValue<string>('replacement', '');
  Result.FIsStandardVCL := JSON.GetValue<Boolean>('is_standard_vcl', False);
  Result.FIsSubComponent := JSON.GetValue<Boolean>('is_subcomponent', False);
  Result.FStandardFMXEquivalent := JSON.GetValue<string>('standard_fmx', '');
end;

{ TThirdPartyHandler }

constructor TThirdPartyHandler.Create(AContext: TConversionContext);
begin
  FContext := AContext;
  FThirdPartyDB := TObjectList<TThirdPartyInfo>.Create(True);
  FDetectedComponents := TDictionary<string, TThirdPartyInfo>.Create;

  LoadThirdPartyDatabase;
end;

destructor TThirdPartyHandler.Destroy;
begin
  FThirdPartyDB.Free;
  FDetectedComponents.Free;
  inherited;
end;

function TThirdPartyHandler.StripTFromClassName(const ClassName: string): string;
begin
  Result := ClassName;
  if Result.StartsWith('T') then
    Result := Copy(Result, 2, Length(Result) - 1);
end;

function TThirdPartyHandler.NormalizeClassName(const ClassName: string): string;
begin
  Result := ClassName;
  if (Result <> '') and not Result.StartsWith('T') then
  begin
    if (Result = 'Form') or (Result = 'Timer') or (Result = 'Button') or
       (Result = 'Edit') or (Result = 'Label') or (Result = 'Panel') or
       (Result = 'DataSource') or (Result = 'FDConnection') or
       (Result = 'FDQuery') or (Result = 'Image') or
       (Result = 'WideMemoField') or (Result = 'DateField') or
       (Result = 'TimeField') or (Result = 'IntegerField') or
       (Result = 'DateTimePicker') or (Result = 'FileOpenDialog') or
       (Result = 'IdSSLIOHandlerSocketOpenSSL') then
    begin
      Result := 'T' + Result;
    end;
  end;
end;

procedure TThirdPartyHandler.LoadThirdPartyDatabase;
begin
  LoadStandardVCLComponents;
  LoadSubComponentTypes;
  LoadRaizeComponents;
  LoadDevExpressComponents;
  LoadTMSComponents;
  LoadJVCLComponents;
  LoadGnosticeComponents;
  LoadFastReports;
  LoadEhLibComponents;
  LoadBibliotecaGDComponents;
end;

procedure TThirdPartyHandler.LoadStandardVCLComponents;
var
  Info: TThirdPartyInfo;

  procedure AddStandardComponent(const CompName, FMXEquiv: string; const Notes: string = '');
  begin
    Info := TThirdPartyInfo.Create;
    Info.ComponentName := CompName;
    Info.Vendor := 'Embarcadero (VCL)';
    Info.IsCommercial := False;
    Info.HasFMXVersion := True;
    Info.FMXComponentName := FMXEquiv;
    Info.IsStandardVCL := True;
    Info.StandardFMXEquivalent := FMXEquiv;
    Info.Notes := Notes;
    Info.ReplacementSuggestion := 'Use standard ' + FMXEquiv;
    FThirdPartyDB.Add(Info);
  end;

begin
  // Forms and base classes
  AddStandardComponent('TForm', 'TForm');
  AddStandardComponent('TFrame', 'TFrame');
  AddStandardComponent('TApplication', 'TApplication');
  AddStandardComponent('TScreen', 'TScreen');

  // Standard controls
  AddStandardComponent('TButton', 'TButton');
  AddStandardComponent('TEdit', 'TEdit');
  AddStandardComponent('TLabel', 'TLabel');
  AddStandardComponent('TMemo', 'TMemo');
  AddStandardComponent('TListBox', 'TListBox');
  AddStandardComponent('TComboBox', 'TComboBox');
  AddStandardComponent('TCheckBox', 'TCheckBox');
  AddStandardComponent('TRadioButton', 'TRadioButton');
  AddStandardComponent('TGroupBox', 'TLayout', 'Use TLayout with TLabel for caption');
  AddStandardComponent('TPanel', 'TLayout', 'Use TLayout with TRectangle for border');
  AddStandardComponent('TImage', 'TImage');
  AddStandardComponent('TShape', 'TShape');
  AddStandardComponent('TBevel', 'TRectangle');
  AddStandardComponent('TScrollBox', 'TScrollBox');
  AddStandardComponent('TSplitter', 'TSplitter');
  AddStandardComponent('TMediaPlayer', 'TMediaPlayer');

  // Dialogs
  AddStandardComponent('TOpenDialog', 'TOpenDialog');
  AddStandardComponent('TSaveDialog', 'TSaveDialog');
  AddStandardComponent('TColorDialog', 'TColorDialog');
  AddStandardComponent('TFontDialog', '', 'No direct FMX equivalent - needs custom dialog');
  AddStandardComponent('TPrintDialog', '', 'Use FMX printing components');

  // System components
  AddStandardComponent('TTimer', 'TTimer');
  AddStandardComponent('TWebBrowser', 'TWebBrowser');
  AddStandardComponent('TImageList', 'TImageList');
  AddStandardComponent('TActionList', 'TActionList');
  AddStandardComponent('TAction', 'TAction');

  // Menus
  AddStandardComponent('TMainMenu', 'TMenuBar');
  AddStandardComponent('TPopupMenu', 'TPopupMenu');
  AddStandardComponent('TMenuItem', 'TMenuItem');

  // Toolbars and status bars
  AddStandardComponent('TToolBar', 'TToolBar');
  AddStandardComponent('TStatusBar', 'TStatusBar');
  AddStandardComponent('TProgressBar', 'TProgressBar');
  AddStandardComponent('TTrackBar', 'TTrackBar');
  AddStandardComponent('TScrollBar', 'TScrollBar');

  // Page controls
  AddStandardComponent('TPageControl', 'TTabControl');
  AddStandardComponent('TTabSheet', 'TTabItem');

  // Database components
  AddStandardComponent('TDataSource', 'TDataSource');
  AddStandardComponent('TADOConnection', 'TFDConnection', 'Convert to FireDAC');
  AddStandardComponent('TADOQuery', 'TFDQuery', 'Convert to FireDAC');
  AddStandardComponent('TADOTable', 'TFDTable', 'Convert to FireDAC');
  AddStandardComponent('TFDConnection', 'TFDConnection');
  AddStandardComponent('TFDQuery', 'TFDQuery');
  AddStandardComponent('TFDTable', 'TFDTable');
  AddStandardComponent('TFDTransaction', 'TFDTransaction');
  AddStandardComponent('TFDPhysSQLiteDriverLink', 'TFDPhysSQLiteDriverLink');
  AddStandardComponent('TDBGrid', 'TGrid', 'Use LiveBindings with TGrid');
  AddStandardComponent('TDBEdit', 'TEdit', 'Use LiveBindings');
  AddStandardComponent('TDBText', 'TLabel', 'Use LiveBindings');
  AddStandardComponent('TDBMemo', 'TMemo', 'Use LiveBindings');
  AddStandardComponent('TDBImage', 'TImage', 'Use LiveBindings with blob field');
  AddStandardComponent('TDBCheckBox', 'TCheckBox', 'Use LiveBindings');
  AddStandardComponent('TDBRadioGroup', 'TRadioGroup', 'Use LiveBindings');
  AddStandardComponent('TDBNavigator', 'TBindNavigator', 'Use LiveBindings');
  AddStandardComponent('TDBComboBox', 'TComboEdit', 'Use LiveBindings');

  // Additional components from your project
  AddStandardComponent('TMediaPlayer', 'TMediaPlayer');
  AddStandardComponent('TImage', 'TImage');
  AddStandardComponent('TMainMenu', 'TMenuBar');
  AddStandardComponent('TMenuItem', 'TMenuItem');
  AddStandardComponent('TFDConnection', 'TFDConnection');
  AddStandardComponent('TFDQuery', 'TFDQuery');
  AddStandardComponent('TDataSource', 'TDataSource');
  AddStandardComponent('TTimer', 'TTimer');
  AddStandardComponent('TOpenDialog', 'TOpenDialog');
  AddStandardComponent('TSaveDialog', 'TSaveDialog');
end;

procedure TThirdPartyHandler.LoadSubComponentTypes;
var
  Info: TThirdPartyInfo;

  procedure AddSubComponentType(const TypeName, ParentType: string; const Notes: string = '');
  begin
    Info := TThirdPartyInfo.Create;
    Info.ComponentName := TypeName;
    Info.Vendor := 'Embarcadero (Sub-component)';
    Info.IsCommercial := False;
    Info.HasFMXVersion := True;
    Info.IsSubComponent := True;
    Info.Notes := 'Sub-component of ' + ParentType + '. ' + Notes;
    Info.ReplacementSuggestion := 'Handled automatically during DFM conversion';
    FThirdPartyDB.Add(Info);
  end;

begin
  AddSubComponentType('TColumn', 'TDBGrid', 'Grid column definition');
  AddSubComponentType('TColumns', 'TDBGrid', 'Grid columns collection');
  AddSubComponentType('TListColumn', 'TListView', 'List view column');
  AddSubComponentType('TTreeNodes', 'TTreeView', 'Tree nodes collection');
  AddSubComponentType('TTreeNode', 'TTreeView', 'Tree node');
  AddSubComponentType('TListItem', 'TListView', 'List item');
  AddSubComponentType('TListItems', 'TListView', 'List items collection');
  AddSubComponentType('TCollectionItem', 'TCollection', 'Base collection item');
  AddSubComponentType('TCollection', 'TComponent', 'Collection container');
  AddSubComponentType('TStatusPanel', 'TStatusBar', 'Status bar panel');
  AddSubComponentType('TStatusPanels', 'TStatusBar', 'Status bar panels collection');
  AddSubComponentType('TMenuItem', 'TMainMenu', 'Menu item');

  // Generic item types
  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'item';
  Info.Vendor := 'Embarcadero (Generic)';
  Info.IsCommercial := False;
  Info.HasFMXVersion := True;
  Info.IsSubComponent := True;
  Info.Notes := 'Generic collection item';
  Info.ReplacementSuggestion := 'Handled automatically during DFM conversion';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'items';
  Info.Vendor := 'Embarcadero (Generic)';
  Info.IsCommercial := False;
  Info.HasFMXVersion := True;
  Info.IsSubComponent := True;
  Info.Notes := 'Generic items collection';
  Info.ReplacementSuggestion := 'Handled automatically during DFM conversion';
  FThirdPartyDB.Add(Info);
end;

procedure TThirdPartyHandler.LoadRaizeComponents;
var
  Info: TThirdPartyInfo;
begin
  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzButton';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.Notes := 'Raize Components not available for FMX';
  Info.ReplacementSuggestion := 'Use standard TButton or TBitBtn with custom styling';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzPanel';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TPanel with custom Fill and Stroke';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzEdit';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use standard TEdit';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzCheckBox';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use standard TCheckBox';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzRadioButton';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use standard TRadioButton';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzListBox';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TListBox';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzComboBox';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TComboBox';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzToolbar';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TToolBar';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzStatusBar';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TStatusBar';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzSplitter';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TSplitter';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzPageControl';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TTabControl';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TRzTabSheet';
  Info.Vendor := 'Raize';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TTabItem';
  FThirdPartyDB.Add(Info);
end;

procedure TThirdPartyHandler.LoadDevExpressComponents;
var
  Info: TThirdPartyInfo;
begin
  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TcxButton';
  Info.Vendor := 'DevExpress';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TcxButton';
  Info.Notes := 'DevExpress has FMX versions - check license';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TcxGrid';
  Info.Vendor := 'DevExpress';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TcxGrid';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TcxDBEdit';
  Info.Vendor := 'DevExpress';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TcxDBEdit';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TcxLookupComboBox';
  Info.Vendor := 'DevExpress';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TcxLookupComboBox';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TcxPageControl';
  Info.Vendor := 'DevExpress';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TcxPageControl';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TcxTabSheet';
  Info.Vendor := 'DevExpress';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TcxTabSheet';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TcxTreeList';
  Info.Vendor := 'DevExpress';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TcxTreeList';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TcxVerticalGrid';
  Info.Vendor := 'DevExpress';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TcxVerticalGrid';
  FThirdPartyDB.Add(Info);
end;

procedure TThirdPartyHandler.LoadTMSComponents;
var
  Info: TThirdPartyInfo;
begin
  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TAdvEdit';
  Info.Vendor := 'TMS';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TAdvEdit';
  Info.Notes := 'TMS has FMX versions - check TMS FMX Pack';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TAdvMemo';
  Info.Vendor := 'TMS';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TAdvMemo';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TAdvStringGrid';
  Info.Vendor := 'TMS';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TAdvStringGrid';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TAdvListView';
  Info.Vendor := 'TMS';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TAdvListView';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TAdvTreeView';
  Info.Vendor := 'TMS';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TAdvTreeView';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TAdvPageControl';
  Info.Vendor := 'TMS';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TAdvPageControl';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TAdvOfficePager';
  Info.Vendor := 'TMS';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TAdvOfficePager';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TAdvPanel';
  Info.Vendor := 'TMS';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TAdvPanel';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TAdvToolBar';
  Info.Vendor := 'TMS';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TAdvToolBar';
  FThirdPartyDB.Add(Info);
end;

procedure TThirdPartyHandler.LoadJVCLComponents;
var
  Info: TThirdPartyInfo;
begin
  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvButton';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.Notes := 'JVCL not available for FMX';
  Info.ReplacementSuggestion := 'Use standard TButton';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvEdit';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use standard TEdit';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvComboBox';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TComboBox';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvListBox';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TListBox';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvCheckBox';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TCheckBox';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvRadioButton';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TRadioButton';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvPanel';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TPanel';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvPageControl';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TTabControl';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvTabSheet';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TTabItem';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvProgressBar';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TProgressBar';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvTrackBar';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TTrackBar';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvStatusBar';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TStatusBar';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TJvToolBar';
  Info.Vendor := 'JVCL';
  Info.IsCommercial := False;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TToolBar';
  FThirdPartyDB.Add(Info);
end;

procedure TThirdPartyHandler.LoadGnosticeComponents;
var
  Info: TThirdPartyInfo;
begin
  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TgtPDFEngine';
  Info.Vendor := 'Gnostice';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TgtPDFEngine';
  Info.Notes := 'Gnostice supports FMX - check version';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TgtDocSerializer';
  Info.Vendor := 'Gnostice';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TgtDocSerializer';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TgtExcelEngine';
  Info.Vendor := 'Gnostice';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TgtExcelEngine';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TgtImageViewer';
  Info.Vendor := 'Gnostice';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TgtImageViewer';
  FThirdPartyDB.Add(Info);
end;

procedure TThirdPartyHandler.LoadFastReports;
var
  Info: TThirdPartyInfo;
begin
  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TfrxReport';
  Info.Vendor := 'FastReports';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TfrxReport';
  Info.Notes := 'FastReports has FMX version - FastReport FMX';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TfrxDBDataSet';
  Info.Vendor := 'FastReports';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TfrxDBDataSet';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TfrxPDFExport';
  Info.Vendor := 'FastReports';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TfrxPDFExport';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TfrxXLSExport';
  Info.Vendor := 'FastReports';
  Info.IsCommercial := True;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TfrxXLSExport';
  FThirdPartyDB.Add(Info);
end;

procedure TThirdPartyHandler.LoadEhLibComponents;
var
  Info: TThirdPartyInfo;
begin
  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TDBGridEh';
  Info.Vendor := 'EhLib';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.Notes := 'EhLib primarily VCL - FMX support limited';
  Info.ReplacementSuggestion := 'Use TGrid with LiveBindings or TMS FMX Grid';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TEditEh';
  Info.Vendor := 'EhLib';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use standard TEdit';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TComboBoxEh';
  Info.Vendor := 'EhLib';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TComboBox';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TDBDateTimeEditEh';
  Info.Vendor := 'EhLib';
  Info.IsCommercial := True;
  Info.HasFMXVersion := False;
  Info.ReplacementSuggestion := 'Use TDateEdit or TTimeEdit';
  FThirdPartyDB.Add(Info);
end;

procedure TThirdPartyHandler.LoadBibliotecaGDComponents;
var
  Info: TThirdPartyInfo;
begin
  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TGDEdit';
  Info.Vendor := 'BibliotecaGD';
  Info.IsCommercial := False;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TGDEdit';
  Info.Notes := 'BibliotecaGD has FMX versions - FMX edition available';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TGDButton';
  Info.Vendor := 'BibliotecaGD';
  Info.IsCommercial := False;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TGDButton';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TGDLabel';
  Info.Vendor := 'BibliotecaGD';
  Info.IsCommercial := False;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TGDLabel';
  FThirdPartyDB.Add(Info);

  Info := TThirdPartyInfo.Create;
  Info.ComponentName := 'TGDDBEdit';
  Info.Vendor := 'BibliotecaGD';
  Info.IsCommercial := False;
  Info.HasFMXVersion := True;
  Info.FMXComponentName := 'TGDDBEdit';
  Info.Notes := 'Specifically designed for VCL to FMX migration';
  FThirdPartyDB.Add(Info);
end;

function TThirdPartyHandler.IsStandardVCLComponent(const ClassName: string): Boolean;
var
  Info: TThirdPartyInfo;
  Normalized: string;
begin
  Result := False;
  Normalized := NormalizeClassName(ClassName);

  for Info in FThirdPartyDB do
  begin
    if Info.IsStandardVCL and
       (SameText(Info.ComponentName, ClassName) or
        SameText(Info.ComponentName, Normalized) or
        SameText(StripTFromClassName(Info.ComponentName), ClassName)) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TThirdPartyHandler.IsSubComponentType(const ClassName: string): Boolean;
var
  Info: TThirdPartyInfo;
begin
  for Info in FThirdPartyDB do
  begin
    if Info.IsSubComponent and SameText(Info.ComponentName, ClassName) then
    begin
      Result := True;
      Exit;
    end;
  end;

  Result := (ClassName = '') or
            (ClassName = 'item') or
            (ClassName = 'items') or
            (ClassName = 'column');
end;

function TThirdPartyHandler.GetStandardFMXEquivalent(const ClassName: string): string;
var
  Info: TThirdPartyInfo;
  Normalized: string;
begin
  Result := '';
  Normalized := NormalizeClassName(ClassName);

  for Info in FThirdPartyDB do
  begin
    if Info.IsStandardVCL and
       (SameText(Info.ComponentName, ClassName) or
        SameText(Info.ComponentName, Normalized) or
        SameText(StripTFromClassName(Info.ComponentName), ClassName)) then
    begin
      Result := Info.StandardFMXEquivalent;
      Exit;
    end;
  end;
end;

function TThirdPartyHandler.DetectVendor(const ClassName: string): string;
var
  Normalized: string;
begin
  if ClassName = '' then
    Exit('Sub-component');

  Normalized := NormalizeClassName(ClassName);

  if ClassName.StartsWith('TRz') then
    Result := 'Raize'
  else if ClassName.StartsWith('Tcx') then
    Result := 'DevExpress'
  else if ClassName.StartsWith('TAdv') then
    Result := 'TMS'
  else if ClassName.StartsWith('TJv') then
    Result := 'JVCL'
  else if ClassName.StartsWith('Tgt') then
    Result := 'Gnostice'
  else if ClassName.StartsWith('Tfrx') then
    Result := 'FastReports'
  else if ClassName.StartsWith('TGD') then
    Result := 'BibliotecaGD'
  else if ClassName.Contains('EhLib') or ClassName.Contains('DBGridEh') then
    Result := 'EhLib'
  else if ClassName.StartsWith('TMS') then
    Result := 'TMS'
  else if ClassName.StartsWith('Tww') then
    Result := 'InfoPower'
  else if ClassName.StartsWith('TQR') then
    Result := 'QuickReport'
  else if ClassName.StartsWith('TRave') then
    Result := 'Rave Reports'
  else if IsStandardVCLComponent(ClassName) or IsStandardVCLComponent(Normalized) then
    Result := 'Embarcadero (VCL)'
  else if IsSubComponentType(ClassName) then
    Result := 'Sub-component'
  else
    Result := 'Unknown';
end;

procedure TThirdPartyHandler.AnalyzeComponent(const ClassName, ComponentName: string);
var
  Info: TThirdPartyInfo;
  Vendor: string;
  Found: Boolean;
  FMXEquiv: string;
  Normalized: string;
  MappingPackHint: string;

  function FindMappingPackHint(const AVCLClassName: string): string;
  var
    Mapping: TComponentMapping;
  begin
    Result := '';
    if not Assigned(FContext) or not FContext.Options.EnableMappingPacks then
      Exit;

    for Mapping in FContext.MappingDatabase do
      if SameText(Mapping.VCLClassName, AVCLClassName) and
         SameText(Mapping.MappingSource, 'pack') then
      begin
        Result := Format(' Mapping pack rule available: %s (%s, %d%%).',
          [Mapping.PackName, Mapping.Action, Mapping.Confidence]);
        Exit;
      end;
  end;

begin
  Found := False;

  if ClassName = '' then
  begin
    FContext.AddIssue(csInfo,
      Format('Sub-component detected: %s', [ComponentName]));
    Exit;
  end;

  Normalized := NormalizeClassName(ClassName);
  MappingPackHint := FindMappingPackHint(ClassName);
  if MappingPackHint = '' then
    MappingPackHint := FindMappingPackHint(Normalized);

  if IsStandardVCLComponent(ClassName) or IsStandardVCLComponent(Normalized) then
  begin
    FMXEquiv := GetStandardFMXEquivalent(ClassName);
    if FMXEquiv = '' then
      FMXEquiv := GetStandardFMXEquivalent(Normalized);

    if FMXEquiv <> '' then
      FContext.AddIssue(csInfo,
        Format('Standard VCL component %s (%s) -> maps to FMX %s',
          [ComponentName, ClassName, FMXEquiv]))
    else
      FContext.AddIssue(csInfo,
        Format('Standard VCL component: %s (%s)', [ComponentName, ClassName]));
    Exit;
  end;

  if IsSubComponentType(ClassName) then
  begin
    FContext.AddIssue(csInfo,
      Format('Sub-component type %s for %s - handled automatically',
        [ClassName, ComponentName]));
    Exit;
  end;

  for Info in FThirdPartyDB do
  begin
    if SameText(Info.ComponentName, ClassName) then
    begin
      FDetectedComponents.AddOrSetValue(ComponentName, Info);
      Found := True;

      if Info.HasFMXVersion then
        FContext.AddIssue(csInfo,
          Format('Component %s (%s) has FMX version: %s.%s',
            [ComponentName, Info.Vendor, Info.FMXComponentName, MappingPackHint]))
      else
        FContext.AddIssue(csInfo,
          Format('Component %s (%s) - %s.%s',
            [ComponentName, Info.Vendor, Info.ReplacementSuggestion, MappingPackHint]));
      Break;
    end;
  end;

  if not Found then
  begin
    Vendor := DetectVendor(ClassName);

    if Vendor = 'Embarcadero (VCL)' then
      FContext.AddIssue(csInfo,
        Format('VCL component: %s (%s)', [ComponentName, ClassName]))
    else if Vendor = 'Sub-component' then
      FContext.AddIssue(csInfo,
        Format('Sub-component: %s (%s) - auto-handled', [ComponentName, ClassName]))
    else
      FContext.AddIssue(csInfo,
        Format('Component: %s (%s) from %s.%s', [ComponentName, ClassName, Vendor, MappingPackHint]));
  end;
end;
function TThirdPartyHandler.GetReplacementCode(const ClassName: string): string;
var
  Info: TThirdPartyInfo;
  FMXEquiv: string;
  Normalized: string;
begin
  Result := '';
  Normalized := NormalizeClassName(ClassName);

  if IsSubComponentType(ClassName) then
  begin
    Result := '  // Sub-component - handled automatically during DFM conversion';
    Exit;
  end;

  if IsStandardVCLComponent(ClassName) or IsStandardVCLComponent(Normalized) then
  begin
    FMXEquiv := GetStandardFMXEquivalent(ClassName);
    if FMXEquiv = '' then
      FMXEquiv := GetStandardFMXEquivalent(Normalized);

    if FMXEquiv <> '' then
      Result := Format('  // Standard VCL component - maps to FMX %s', [FMXEquiv])
    else
      Result := Format('  // Standard VCL component: %s', [ClassName]);
    Exit;
  end;

  for Info in FThirdPartyDB do
  begin
    if SameText(Info.ComponentName, ClassName) or
       SameText(Info.ComponentName, Normalized) then
    begin
      if Info.HasFMXVersion then
        Result := Format('  // Use %s from %s (FMX version available)'#13#10 +
                         '  // Add %s to uses clause',
                         [Info.FMXComponentName, Info.Vendor, Info.FMXComponentName])
      else
        Result := Format('  // %s from %s - %s',
                         [ClassName, Info.Vendor, Info.ReplacementSuggestion]);
      Break;
    end;
  end;

  if Result = '' then
  begin
    if IsSubComponentType(ClassName) then
      Result := '  // Sub-component - handled automatically'
    else
      Result := Format('  // Component: %s - review manually', [ClassName]);
  end;
end;

procedure TThirdPartyHandler.GenerateVendorNotes(var Report: TStringList);
var
  VendorGroups: TDictionary<string, TList<string>>;
  Pair: TPair<string, TThirdPartyInfo>;
  Vendor: string;
  CompList: TList<string>;
  Comp: string;
  HasThirdParty: Boolean;
begin
  VendorGroups := TDictionary<string, TList<string>>.Create;
  HasThirdParty := False;

  try
    for Pair in FDetectedComponents do
    begin
      if not Pair.Value.IsStandardVCL and not Pair.Value.IsSubComponent then
      begin
        Vendor := Pair.Value.Vendor;
        if not VendorGroups.TryGetValue(Vendor, CompList) then
        begin
          CompList := TList<string>.Create;
          VendorGroups.Add(Vendor, CompList);
        end;
        CompList.Add(Pair.Key + ' (' + Pair.Value.ComponentName + ')');
        HasThirdParty := True;
      end;
    end;

    if HasThirdParty then
    begin
      Report.Add('');
      Report.Add('Third-Party Components Detected');
      Report.Add('===============================');
      Report.Add('');

      for Vendor in VendorGroups.Keys do
      begin
        CompList := VendorGroups[Vendor];
        Report.Add(Format('Vendor: %s (%d components)', [Vendor, CompList.Count]));

        for Comp in CompList do
          Report.Add('  - ' + Comp);

        if Vendor = 'Raize' then
        begin
          Report.Add('  NOTE: Raize Components not available for FMX. Consider:');
          Report.Add('    * Replace with standard FMX controls');
          Report.Add('    * Consider TMS FMX Pack for similar functionality');
          Report.Add('');
        end
        else if Vendor = 'DevExpress' then
        begin
          Report.Add('  NOTE: DevExpress has FMX versions - check license upgrade');
          Report.Add('');
        end
        else if Vendor = 'TMS' then
        begin
          Report.Add('  NOTE: TMS FMX Pack provides FMX versions - ensure proper units');
          Report.Add('');
        end
        else if Vendor = 'JVCL' then
        begin
          Report.Add('  NOTE: JVCL not available for FMX - replace with standard FMX');
          Report.Add('');
        end
        else if Vendor = 'FastReports' then
        begin
          Report.Add('  NOTE: FastReport FMX version available - update references');
          Report.Add('');
        end
        else if Vendor = 'EhLib' then
        begin
          Report.Add('  NOTE: EhLib FMX support limited - consider alternatives');
          Report.Add('');
        end
        else if Vendor = 'BibliotecaGD' then
        begin
          Report.Add('  NOTE: BibliotecaGD has FMX version - use FMX units');
          Report.Add('');
        end;
      end;
    end;

  finally
    for CompList in VendorGroups.Values do
      CompList.Free;
    VendorGroups.Free;
  end;
end;

end.
