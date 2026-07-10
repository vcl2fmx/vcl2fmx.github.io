{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Advanced.DataAware;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  System.RTTI, System.JSON, System.RegularExpressions,
  Converter.Core.Types,
  Converter.Parser.DFM,
  Converter.Parser.Pascal,
  Converter.Mapper.Component;

type
  TDataBindingInfo = class
  private
    FComponentName: string;
    FDataSource: string;
    FDataField: string;
    FDataSourceComponent: string;
    FDataLinkType: string;
    FOriginalProperties: TDictionary<string, string>;
  public
    property ComponentName: string read FComponentName write FComponentName;
    property DataSource: string read FDataSource write FDataSource;
    property DataField: string read FDataField write FDataField;
    property DataSourceComponent: string read FDataSourceComponent write FDataSourceComponent;
    property DataLinkType: string read FDataLinkType write FDataLinkType;
    property OriginalProperties: TDictionary<string, string> read FOriginalProperties;

    constructor Create;
    destructor Destroy; override;

    function ToJSON: TJSONObject;
    class function FromJSON(JSON: TJSONObject): TDataBindingInfo;
  end;

  TLiveBindingConverter = class
  private
    FContext: TConversionContext;
    FComponentMapper: TComponentMapper;
    FDataBindings: TObjectList<TDataBindingInfo>;
    FBindingExpressions: TStringList;
    FNextBindingID: Integer;

    procedure DetectDataAwareControls(Component: TDFMComponent);
    procedure CreateLiveBinding(const BindingInfo: TDataBindingInfo);
    function GenerateBindingExpression(const BindingInfo: TDataBindingInfo;
      const BindingID: Integer): string;
  public
    constructor Create(AContext: TConversionContext; AMapper: TComponentMapper);
    destructor Destroy; override;

    procedure AnalyzeForm(Components: TObjectList<TDFMComponent>);
    function GenerateLiveBindings: string;
    procedure ConvertDataAwareComponents(var PascalCode: TStringList);

    property DataBindings: TObjectList<TDataBindingInfo> read FDataBindings;
  end;

  TDatabaseConverter = class
  private
    FContext: TConversionContext;
    FConnectionInfo: TDictionary<string, TJSONObject>;
    FQueryInfo: TDictionary<string, TJSONObject>;

    procedure DetectDatabaseComponents(Component: TDFMComponent);
    function ConvertConnection(const VCLConnName: string;
      Properties: TDictionary<string, string>): string;
    function ConvertQuery(const VCLQueryName: string;
      Properties: TDictionary<string, string>): string;
    function ConvertADOToFDConnectionString(const ADOStr: string): string;
  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    procedure AnalyzeDatabaseComponents(Components: TObjectList<TDFMComponent>);
    function GenerateDatabaseCode: string;
    function GenerateDatabaseDFM(const Component: TDFMComponent): string;

    property ConnectionInfo: TDictionary<string, TJSONObject> read FConnectionInfo;
    property QueryInfo: TDictionary<string, TJSONObject> read FQueryInfo;
  end;

implementation

function NormalizeComponentClassName(const ClassName: string): string;
var
  Normalized: string;
  DotPos: Integer;
  GenericPos: Integer;
begin
  Normalized := Trim(ClassName);
  if Normalized = '' then
    Exit('');

  DotPos := LastDelimiter('.', Normalized);
  if DotPos > 0 then
    Normalized := Copy(Normalized, DotPos + 1, MaxInt);

  GenericPos := Pos('<', Normalized);
  if GenericPos > 0 then
    Normalized := Copy(Normalized, 1, GenericPos - 1);

  Result := Trim(Normalized);
end;

function ComponentMatchesClass(const ComponentClassName, TargetClassName: string;
  AMapper: TComponentMapper = nil): Boolean;
var
  CurrentClassName: string;
  TargetName: string;
  Inventory: TRttiClassInventory;
  ParentClassName: string;
begin
  Result := False;
  CurrentClassName := NormalizeComponentClassName(ComponentClassName);
  TargetName := NormalizeComponentClassName(TargetClassName);
  if (CurrentClassName = '') or (TargetName = '') then
    Exit;

  if SameText(CurrentClassName, TargetName) then
    Exit(True);

  if not Assigned(AMapper) then
    Exit;

  Inventory := AMapper.GetVCLInventory(CurrentClassName);
  while Assigned(Inventory) do
  begin
    if SameText(NormalizeComponentClassName(Inventory.ClassName), TargetName) then
      Exit(True);

    ParentClassName := NormalizeComponentClassName(Inventory.ParentClass);
    if (ParentClassName = '') or
       SameText(ParentClassName, NormalizeComponentClassName(Inventory.ClassName)) then
      Break;

    Inventory := AMapper.GetVCLInventory(ParentClassName);
  end;
end;

{ TDataBindingInfo }

constructor TDataBindingInfo.Create;
begin
  FOriginalProperties := TDictionary<string, string>.Create;
end;

destructor TDataBindingInfo.Destroy;
begin
  FOriginalProperties.Free;
  inherited;
end;

function TDataBindingInfo.ToJSON: TJSONObject;
var
  PropsObj: TJSONObject;
  PropPair: TPair<string, string>;
begin
  Result := TJSONObject.Create;
  Result.AddPair('component_name', FComponentName);
  Result.AddPair('data_source', FDataSource);
  Result.AddPair('data_field', FDataField);
  Result.AddPair('data_source_component', FDataSourceComponent);
  Result.AddPair('data_link_type', FDataLinkType);

  PropsObj := TJSONObject.Create;
  for PropPair in FOriginalProperties do
    PropsObj.AddPair(PropPair.Key, PropPair.Value);
  Result.AddPair('original_properties', PropsObj);
end;

class function TDataBindingInfo.FromJSON(JSON: TJSONObject): TDataBindingInfo;
var
  PropsObj: TJSONObject;
  PropPair: TJSONPair;
begin
  Result := TDataBindingInfo.Create;
  Result.FComponentName := JSON.GetValue<string>('component_name', '');
  Result.FDataSource := JSON.GetValue<string>('data_source', '');
  Result.FDataField := JSON.GetValue<string>('data_field', '');
  Result.FDataSourceComponent := JSON.GetValue<string>('data_source_component', '');
  Result.FDataLinkType := JSON.GetValue<string>('data_link_type', '');

  if JSON.TryGetValue<TJSONObject>('original_properties', PropsObj) then
  begin
    for PropPair in PropsObj do
      Result.FOriginalProperties.Add(PropPair.JsonString.Value,
        PropPair.JsonValue.Value);
  end;
end;

{ TLiveBindingConverter }

constructor TLiveBindingConverter.Create(AContext: TConversionContext;
  AMapper: TComponentMapper);
begin
  FContext := AContext;
  FComponentMapper := AMapper;
  FDataBindings := TObjectList<TDataBindingInfo>.Create(True);
  FBindingExpressions := TStringList.Create;
  FNextBindingID := 1;
end;

destructor TLiveBindingConverter.Destroy;
begin
  FDataBindings.Free;
  FBindingExpressions.Free;
  inherited;
end;

procedure TLiveBindingConverter.AnalyzeForm(Components: TObjectList<TDFMComponent>);

  procedure TraverseComponents(Comp: TDFMComponent);
  begin
    if Comp = nil then
      Exit;

    DetectDataAwareControls(Comp);

    if Comp.Children = nil then
      Exit;

    for var Child in Comp.Children do
      TraverseComponents(Child);
  end;

begin
  FDataBindings.Clear;
  FBindingExpressions.Clear;
  FNextBindingID := 1;

  if Components = nil then
    Exit;

  for var Comp in Components do
    TraverseComponents(Comp);
end;

procedure TLiveBindingConverter.DetectDataAwareControls(Component: TDFMComponent);
var
  BindingInfo: TDataBindingInfo;
  DataSource: string;
  DataField: string;
  ColumnCollection: TDFMComponent;
  ChildComp: TDFMComponent;
  ColumnItem: TDFMComponent;
  I: Integer;
begin
  if Component = nil then
    Exit;

  // Check for TDBEdit
  if ComponentMatchesClass(Component.ComponentClass, 'TDBEdit', FComponentMapper) then
  begin
    DataSource := '';
    DataField := '';

    if Component.Properties.ContainsKey('DataSource') then
      DataSource := Component.Properties['DataSource'];

    if Component.Properties.ContainsKey('DataField') then
      DataField := Component.Properties['DataField'];

    BindingInfo := TDataBindingInfo.Create;
    BindingInfo.ComponentName := Component.Name;
    BindingInfo.DataSource := DataSource;
    BindingInfo.DataField := DataField;
    BindingInfo.DataLinkType := 'Field';

    // Store all original properties
    for var Prop in Component.Properties do
      BindingInfo.OriginalProperties.Add(Prop.Key, Prop.Value);

    FDataBindings.Add(BindingInfo);

    FContext.AddIssue(csInfo,
      Format('Detected data-aware edit: %s -> %s.%s',
        [Component.Name, DataSource, DataField]));
  end

  // Check for TDBGrid
  else if ComponentMatchesClass(Component.ComponentClass, 'TDBGrid', FComponentMapper) then
  begin
    DataSource := '';

    if Component.Properties.ContainsKey('DataSource') then
    begin
      DataSource := Component.Properties['DataSource'];

      BindingInfo := TDataBindingInfo.Create;
      BindingInfo.ComponentName := Component.Name;
      BindingInfo.DataSource := DataSource;
      BindingInfo.DataLinkType := 'Grid';

      for var Prop in Component.Properties do
        BindingInfo.OriginalProperties.Add(Prop.Key, Prop.Value);

      ColumnCollection := nil;
      if Component.Children <> nil then
        for ChildComp in Component.Children do
          if Assigned(ChildComp) and ChildComp.IsCollection and SameText(ChildComp.Name, 'Columns') then
          begin
            ColumnCollection := ChildComp;
            Break;
          end;

      if Assigned(ColumnCollection) then
      begin
        BindingInfo.OriginalProperties.AddOrSetValue('GridColumnCount',
          IntToStr(ColumnCollection.CollectionItems.Count));

        for I := 0 to ColumnCollection.CollectionItems.Count - 1 do
        begin
          ColumnItem := ColumnCollection.CollectionItems[I];
          if not Assigned(ColumnItem) then
            Continue;

          if ColumnItem.Properties.ContainsKey('FieldName') then
            BindingInfo.OriginalProperties.AddOrSetValue(
              Format('GridColumn%d.FieldName', [I]),
              ColumnItem.Properties['FieldName']);
          if ColumnItem.Properties.ContainsKey('Title.Caption') then
            BindingInfo.OriginalProperties.AddOrSetValue(
              Format('GridColumn%d.Title.Caption', [I]),
              ColumnItem.Properties['Title.Caption']);
          if ColumnItem.Properties.ContainsKey('Width') then
            BindingInfo.OriginalProperties.AddOrSetValue(
              Format('GridColumn%d.Width', [I]),
              ColumnItem.Properties['Width']);
        end;
      end;

      FDataBindings.Add(BindingInfo);

      FContext.AddIssue(csInfo,
        Format('DBGrid detected: %s - requires LiveBindings grid implementation',
          [Component.Name]));
    end;
  end

  // Check for TDBNavigator
  else if ComponentMatchesClass(Component.ComponentClass, 'TDBNavigator', FComponentMapper) then
  begin
    DataSource := '';

    if Component.Properties.ContainsKey('DataSource') then
      DataSource := Component.Properties['DataSource'];

    if DataSource <> '' then
    begin
      BindingInfo := TDataBindingInfo.Create;
      BindingInfo.ComponentName := Component.Name;
      BindingInfo.DataSource := DataSource;
      BindingInfo.DataField := '';
      BindingInfo.DataLinkType := 'Navigator';

      for var Prop in Component.Properties do
        BindingInfo.OriginalProperties.Add(Prop.Key, Prop.Value);

      FDataBindings.Add(BindingInfo);

      FContext.AddIssue(csInfo,
        Format('DBNavigator detected: %s - using FMX TBindNavigator with generated bind source',
          [Component.Name]));
    end;
  end

  // Check for TDBLookupComboBox
  else if ComponentMatchesClass(Component.ComponentClass, 'TDBLookupComboBox', FComponentMapper) then
  begin
    BindingInfo := TDataBindingInfo.Create;
    BindingInfo.ComponentName := Component.Name;
    BindingInfo.DataLinkType := 'Lookup';
    DataField := '';

    if Component.Properties.ContainsKey('ListSource') then
      BindingInfo.DataSource := Component.Properties['ListSource']
    else
      BindingInfo.DataSource := '';

    if Component.Properties.ContainsKey('KeyField') then
      DataField := Component.Properties['KeyField'];

    if Component.Properties.ContainsKey('ListField') then
      BindingInfo.DataField := Component.Properties['ListField']
    else
      BindingInfo.DataField := '';

    // Store all original properties
    for var Prop in Component.Properties do
      BindingInfo.OriginalProperties.Add(Prop.Key, Prop.Value);

    FDataBindings.Add(BindingInfo);

    FContext.AddIssue(csInfo,
      Format('DBLookupComboBox detected: %s - requires custom LiveBindings setup',
        [Component.Name]));
  end

  // Check for TDBText
  else if ComponentMatchesClass(Component.ComponentClass, 'TDBText', FComponentMapper) then
  begin
    DataSource := '';
    DataField := '';

    if Component.Properties.ContainsKey('DataSource') then
      DataSource := Component.Properties['DataSource'];

    if Component.Properties.ContainsKey('DataField') then
      DataField := Component.Properties['DataField'];

    if (DataSource <> '') and (DataField <> '') then
    begin
      BindingInfo := TDataBindingInfo.Create;
      BindingInfo.ComponentName := Component.Name;
      BindingInfo.DataSource := DataSource;
      BindingInfo.DataField := DataField;
      BindingInfo.DataLinkType := 'Text';

      FDataBindings.Add(BindingInfo);
    end;
  end

  // Check for TDBComboBox
  else if ComponentMatchesClass(Component.ComponentClass, 'TDBComboBox', FComponentMapper) then
  begin
    DataSource := '';
    DataField := '';

    if Component.Properties.ContainsKey('DataSource') then
      DataSource := Component.Properties['DataSource'];

    if Component.Properties.ContainsKey('DataField') then
      DataField := Component.Properties['DataField'];

    if (DataSource <> '') and (DataField <> '') then
    begin
      BindingInfo := TDataBindingInfo.Create;
      BindingInfo.ComponentName := Component.Name;
      BindingInfo.DataSource := DataSource;
      BindingInfo.DataField := DataField;
      BindingInfo.DataLinkType := 'ComboText';

      for var Prop in Component.Properties do
        BindingInfo.OriginalProperties.Add(Prop.Key, Prop.Value);

      FDataBindings.Add(BindingInfo);

      FContext.AddIssue(csInfo,
        Format('DBComboBox detected: %s - using generated FMX combo/data bridge',
          [Component.Name]));
    end;
  end

  // Check for TDBImage
  else if ComponentMatchesClass(Component.ComponentClass, 'TDBImage', FComponentMapper) then
  begin
    DataSource := '';
    DataField := '';

    if Component.Properties.ContainsKey('DataSource') then
      DataSource := Component.Properties['DataSource'];

    if Component.Properties.ContainsKey('DataField') then
      DataField := Component.Properties['DataField'];

    if (DataSource <> '') and (DataField <> '') then
    begin
      BindingInfo := TDataBindingInfo.Create;
      BindingInfo.ComponentName := Component.Name;
      BindingInfo.DataSource := DataSource;
      BindingInfo.DataField := DataField;
      BindingInfo.DataLinkType := 'Blob';

      // Store original properties
      for var Prop in Component.Properties do
        BindingInfo.OriginalProperties.Add(Prop.Key, Prop.Value);

      FDataBindings.Add(BindingInfo);

      FContext.AddIssue(csInfo,
        Format('DBImage detected: %s - requires blob image binding',
          [Component.Name]));
    end;
  end

  // Check for TDBMemo
  else if ComponentMatchesClass(Component.ComponentClass, 'TDBMemo', FComponentMapper) then
  begin
    DataSource := '';
    DataField := '';

    if Component.Properties.ContainsKey('DataSource') then
      DataSource := Component.Properties['DataSource'];

    if Component.Properties.ContainsKey('DataField') then
      DataField := Component.Properties['DataField'];

    if (DataSource <> '') and (DataField <> '') then
    begin
      BindingInfo := TDataBindingInfo.Create;
      BindingInfo.ComponentName := Component.Name;
      BindingInfo.DataSource := DataSource;
      BindingInfo.DataField := DataField;
      BindingInfo.DataLinkType := 'Memo';

      FDataBindings.Add(BindingInfo);
    end;
  end

  // Check for TDBCheckBox
  else if ComponentMatchesClass(Component.ComponentClass, 'TDBCheckBox', FComponentMapper) then
  begin
    DataSource := '';
    DataField := '';

    if Component.Properties.ContainsKey('DataSource') then
      DataSource := Component.Properties['DataSource'];

    if Component.Properties.ContainsKey('DataField') then
      DataField := Component.Properties['DataField'];

    if (DataSource <> '') and (DataField <> '') then
    begin
      BindingInfo := TDataBindingInfo.Create;
      BindingInfo.ComponentName := Component.Name;
      BindingInfo.DataSource := DataSource;
      BindingInfo.DataField := DataField;
      BindingInfo.DataLinkType := 'Boolean';

      for var Prop in Component.Properties do
        BindingInfo.OriginalProperties.Add(Prop.Key, Prop.Value);

      FDataBindings.Add(BindingInfo);
    end;
  end

  // Check for TDBRadioGroup
  else if ComponentMatchesClass(Component.ComponentClass, 'TDBRadioGroup', FComponentMapper) then
  begin
    DataSource := '';
    DataField := '';

    if Component.Properties.ContainsKey('DataSource') then
      DataSource := Component.Properties['DataSource'];

    if Component.Properties.ContainsKey('DataField') then
      DataField := Component.Properties['DataField'];

    if (DataSource <> '') and (DataField <> '') then
    begin
      BindingInfo := TDataBindingInfo.Create;
      BindingInfo.ComponentName := Component.Name;
      BindingInfo.DataSource := DataSource;
      BindingInfo.DataField := DataField;
      BindingInfo.DataLinkType := 'Enum';

      for var Prop in Component.Properties do
        BindingInfo.OriginalProperties.Add(Prop.Key, Prop.Value);

      FDataBindings.Add(BindingInfo);

      FContext.AddIssue(csInfo,
        Format('DBRadioGroup detected: %s - requires custom binding',
          [Component.Name]));
    end;
  end;
end;

procedure TLiveBindingConverter.CreateLiveBinding(const BindingInfo: TDataBindingInfo);
var
  BindingExpr: string;
begin
  BindingExpr := GenerateBindingExpression(BindingInfo, FNextBindingID);
  FBindingExpressions.Add(BindingExpr);
  Inc(FNextBindingID);
end;

function TLiveBindingConverter.GenerateBindingExpression(
  const BindingInfo: TDataBindingInfo; const BindingID: Integer): string;
begin
  if BindingInfo.DataLinkType = 'Field' then
  begin
    Result :=
      '  LiveBinding' + IntToStr(BindingID) + ': TBindSourceDB;' + #13#10 +
      '  BindingsList' + IntToStr(BindingID) + ': TBindingsList;' + #13#10 +
      '  LinkControlToField' + IntToStr(BindingID) + ': TLinkControlToField;' + #13#10 +
      '' + #13#10 +
      '  // Setup for ' + BindingInfo.ComponentName + #13#10 +
      '  BindingsList' + IntToStr(BindingID) + ' := TBindingsList.Create(Self);' + #13#10 +
      '  LinkControlToField' + IntToStr(BindingID) + ' := TLinkControlToField.Create(BindingsList' + IntToStr(BindingID) + ');' + #13#10 +
      '  LinkControlToField' + IntToStr(BindingID) + '.DataSource := ' + BindingInfo.DataSource + ';' + #13#10 +
      '  LinkControlToField' + IntToStr(BindingID) + '.FieldName := ''' + BindingInfo.DataField + ''';' + #13#10 +
      '  LinkControlToField' + IntToStr(BindingID) + '.Control := ' + BindingInfo.ComponentName + ';';
  end

  else if BindingInfo.DataLinkType = 'Grid' then
  begin
    Result :=
      '  // DB-aware FMX grid binding for ' + BindingInfo.ComponentName + #13#10 +
      '  GridDataSource' + IntToStr(BindingID) + ': TBindSourceDB;' + #13#10 +
      '  BindDBGridLink' + IntToStr(BindingID) + ': TLinkGridToDataSource;' + #13#10 +
      '' + #13#10 +
      '  GridDataSource' + IntToStr(BindingID) + ' := TBindSourceDB.Create(Self);' + #13#10 +
      '  GridDataSource' + IntToStr(BindingID) + '.DataSource := ' + BindingInfo.DataSource + ';' + #13#10 +
      '' + #13#10 +
      '  BindDBGridLink' + IntToStr(BindingID) + ' := TLinkGridToDataSource.Create(Self);' + #13#10 +
      '  BindDBGridLink' + IntToStr(BindingID) + '.DataSource := GridDataSource' + IntToStr(BindingID) + ';' + #13#10 +
      '  BindDBGridLink' + IntToStr(BindingID) + '.GridControl := ' + BindingInfo.ComponentName + ';' + #13#10 +
      '  BindDBGridLink' + IntToStr(BindingID) + '.Active := True;' + #13#10 +
      '  BindDBGridLink' + IntToStr(BindingID) + '.UpdateColumns;';
  end

  else if BindingInfo.DataLinkType = 'Lookup' then
  begin
    Result :=
      '  // Lookup field binding for ' + BindingInfo.ComponentName + #13#10 +
      '  // Consider using TLinkFillControlToField' + #13#10 +
      '  LinkFillControlToField' + IntToStr(BindingID) + ': TLinkFillControlToField;' + #13#10 +
      '' + #13#10 +
      '  LinkFillControlToField' + IntToStr(BindingID) + ' := TLinkFillControlToField.Create(Self);' + #13#10 +
      '  LinkFillControlToField' + IntToStr(BindingID) + '.Control := ' + BindingInfo.ComponentName + ';' + #13#10 +
      '  LinkFillControlToField' + IntToStr(BindingID) + '.AutoActivate := True;' + #13#10 +
      '  LinkFillControlToField' + IntToStr(BindingID) + '.FillDataSource := ' + BindingInfo.DataSource + ';' + #13#10 +
      '  LinkFillControlToField' + IntToStr(BindingID) + '.FieldName := ''' + BindingInfo.DataField + ''';';
  end

  else if BindingInfo.DataLinkType = 'Blob' then
  begin
    Result :=
      '  // Blob image binding for ' + BindingInfo.ComponentName + #13#10 +
      '  // May require TLinkPropertyToField with custom formatting' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + ': TLinkPropertyToField;' + #13#10 +
      '' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + ' := TLinkPropertyToField.Create(Self);' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.DataSource := ' + BindingInfo.DataSource + ';' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.FieldName := ''' + BindingInfo.DataField + ''';' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.Component := ' + BindingInfo.ComponentName + ';' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.ComponentProperty := ''Bitmap'';';
  end

  else if BindingInfo.DataLinkType = 'Memo' then
  begin
    Result :=
      '  // Memo field binding for ' + BindingInfo.ComponentName + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + ': TLinkPropertyToField;' + #13#10 +
      '' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + ' := TLinkPropertyToField.Create(Self);' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.DataSource := ' + BindingInfo.DataSource + ';' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.FieldName := ''' + BindingInfo.DataField + ''';' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.Component := ' + BindingInfo.ComponentName + ';' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.ComponentProperty := ''Text'';';
  end

  else if BindingInfo.DataLinkType = 'Boolean' then
  begin
    Result :=
      '  // Boolean field binding for ' + BindingInfo.ComponentName + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + ': TLinkPropertyToField;' + #13#10 +
      '' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + ' := TLinkPropertyToField.Create(Self);' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.DataSource := ' + BindingInfo.DataSource + ';' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.FieldName := ''' + BindingInfo.DataField + ''';' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.Component := ' + BindingInfo.ComponentName + ';' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + '.ComponentProperty := ''IsChecked'';';
  end

  else if BindingInfo.DataLinkType = 'Enum' then
  begin
    Result :=
      '  // RadioGroup/Enum field binding for ' + BindingInfo.ComponentName + #13#10 +
      '  // May require custom formatting expressions' + #13#10 +
      '  LinkPropertyToField' + IntToStr(BindingID) + ': TLinkPropertyToField;' + #13#10 +
      '  // Add formatting expression for item index to field value mapping';
  end

  else
  begin
    Result := '// Unhandled binding type for ' + BindingInfo.ComponentName;
  end;
end;

function TLiveBindingConverter.GenerateLiveBindings: string;
var
  SB: TStringBuilder;
  I: Integer;
begin
  if FDataBindings.Count = 0 then
    Exit('');

  SB := TStringBuilder.Create;
  try
    FBindingExpressions.Clear;
    FNextBindingID := 1;

    SB.AppendLine('  // LiveBindings generated from VCL data-aware controls');
    SB.AppendLine('  // Manual review recommended for complex bindings');
    SB.AppendLine('');

    for I := 0 to FDataBindings.Count - 1 do
    begin
      CreateLiveBinding(FDataBindings[I]);
      SB.AppendLine(FBindingExpressions[I]);
      SB.AppendLine('');
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TLiveBindingConverter.ConvertDataAwareComponents(
  var PascalCode: TStringList);
var
  I: Integer;
  Line: string;
begin
  // Replace VCL data-aware component classes with FMX equivalents
  for I := 0 to PascalCode.Count - 1 do
  begin
    Line := PascalCode[I];

    // Replace class names
    Line := TRegEx.Replace(Line, '\bTDBEdit\b', 'TEdit', [roIgnoreCase]);
    Line := TRegEx.Replace(Line, '\bTDBText\b', 'TLabel', [roIgnoreCase]);
    Line := TRegEx.Replace(Line, '\bTDBMemo\b', 'TMemo', [roIgnoreCase]);
    Line := TRegEx.Replace(Line, '\bTDBCheckBox\b', 'TCheckBox', [roIgnoreCase]);
    Line := TRegEx.Replace(Line, '\bTDBImage\b', 'TImage', [roIgnoreCase]);
    Line := TRegEx.Replace(Line, '\bTDBGrid\b', 'TGrid', [roIgnoreCase]);
    Line := TRegEx.Replace(Line, '\bTDBLookupComboBox\b', 'TComboBox', [roIgnoreCase]);

    // Comment out DataSource and DataField assignments
    if (Line.Trim().StartsWith('DataSource') or
        Line.Trim().StartsWith('DataField')) and
       not Line.Trim().StartsWith('//') then
      Line := '  // ' + Line.Trim() + ' // Converted to LiveBinding';

    PascalCode[I] := Line;
  end;
end;

{ TDatabaseConverter }

constructor TDatabaseConverter.Create(AContext: TConversionContext);
begin
  FContext := AContext;
  FConnectionInfo := TDictionary<string, TJSONObject>.Create;
  FQueryInfo := TDictionary<string, TJSONObject>.Create;
end;

destructor TDatabaseConverter.Destroy;
var
  JsonValue: TJSONObject;
begin
  for JsonValue in FConnectionInfo.Values do
    JsonValue.Free;
  for JsonValue in FQueryInfo.Values do
    JsonValue.Free;
  FConnectionInfo.Free;
  FQueryInfo.Free;
  inherited;
end;

procedure TDatabaseConverter.AnalyzeDatabaseComponents(
  Components: TObjectList<TDFMComponent>);

  procedure TraverseComponents(Comp: TDFMComponent);
  begin
    if Comp = nil then
      Exit;

    DetectDatabaseComponents(Comp);

    if Comp.Children = nil then
      Exit;

    for var Child in Comp.Children do
      TraverseComponents(Child);
  end;

begin
  if Components = nil then
    Exit;

  for var Comp in Components do
    TraverseComponents(Comp);
end;

procedure TDatabaseConverter.DetectDatabaseComponents(Component: TDFMComponent);
var
  ConnInfo: TJSONObject;
  QueryInfo: TJSONObject;
  Prop: TPair<string, string>;
begin
  if Component = nil then
    Exit;

  // Detect TADOConnection
  if ComponentMatchesClass(Component.ComponentClass, 'TADOConnection', nil) then
  begin
    ConnInfo := TJSONObject.Create;
    for Prop in Component.Properties do
      ConnInfo.AddPair(Prop.Key, Prop.Value);

    FConnectionInfo.Add(Component.Name, ConnInfo);

    FContext.AddIssue(csInfo,
      Format('ADO Connection detected: %s - converting to FireDAC',
        [Component.Name]));
  end

  // Detect TSQLConnection (dbExpress)
  else if ComponentMatchesClass(Component.ComponentClass, 'TSQLConnection', nil) then
  begin
    ConnInfo := TJSONObject.Create;
    for Prop in Component.Properties do
      ConnInfo.AddPair(Prop.Key, Prop.Value);

    FConnectionInfo.Add(Component.Name, ConnInfo);

    FContext.AddIssue(csInfo,
      Format('dbExpress Connection detected: %s - converting to FireDAC',
        [Component.Name]));
  end

  // Detect TADOQuery
  else if ComponentMatchesClass(Component.ComponentClass, 'TADOQuery', nil) then
  begin
    QueryInfo := TJSONObject.Create;
    for Prop in Component.Properties do
      QueryInfo.AddPair(Prop.Key, Prop.Value);

    FQueryInfo.Add(Component.Name, QueryInfo);
  end

  // Detect TSQLQuery (dbExpress)
  else if ComponentMatchesClass(Component.ComponentClass, 'TSQLQuery', nil) then
  begin
    QueryInfo := TJSONObject.Create;
    for Prop in Component.Properties do
      QueryInfo.AddPair(Prop.Key, Prop.Value);

    FQueryInfo.Add(Component.Name, QueryInfo);
  end

  // Detect TTable (BDE)
  else if ComponentMatchesClass(Component.ComponentClass, 'TTable', nil) then
  begin
    QueryInfo := TJSONObject.Create;

    if Component.Properties.ContainsKey('TableName') then
      QueryInfo.AddPair('table_name', Component.Properties['TableName']);

    if Component.Properties.ContainsKey('DatabaseName') then
      QueryInfo.AddPair('database_name', Component.Properties['DatabaseName']);

    FQueryInfo.Add(Component.Name, QueryInfo);

    FContext.AddIssue(csInfo,
      Format('BDE Table detected: %s - requires conversion to FireDAC query',
        [Component.Name]));
  end

  // Detect TDataSource
  else if ComponentMatchesClass(Component.ComponentClass, 'TDataSource', nil) then
  begin
    FContext.AddIssue(csInfo,
      Format('DataSource detected: %s - will be kept as TDataSource',
        [Component.Name]));
  end;
end;

function TDatabaseConverter.ConvertADOToFDConnectionString(const ADOStr: string): string;
begin
  Result := ADOStr;

  // Common ADO to FireDAC conversions
  Result := Result.Replace('Provider=SQLOLEDB', 'DriverID=MSSQL');
  Result := Result.Replace('Provider=MSDAORA', 'DriverID=Ora');
  Result := Result.Replace('Provider=Microsoft.Jet.OLEDB.4.0', 'DriverID=MSAcc');
  Result := Result.Replace('Provider=SQLNCLI11', 'DriverID=MSSQL');

  // Parse out ODBC parts
  if Result.Contains('ODBC') then
    Result := 'DriverID=ODBC;' + Result;

  FContext.AddIssue(csInfo, 'ADO connection string converted - verify parameters');
end;

function TDatabaseConverter.ConvertConnection(const VCLConnName: string;
  Properties: TDictionary<string, string>): string;
var
  SB: TStringBuilder;
  ConnParams: string;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('  // Converted from ' + VCLConnName);
    SB.AppendLine('  ' + VCLConnName + ': TFDConnection;');
    SB.AppendLine('');
    SB.AppendLine('  // Setup ' + VCLConnName);
    SB.AppendLine('  ' + VCLConnName + ' := TFDConnection.Create(Self);');

    ConnParams := '';
    if Properties.ContainsKey('ConnectionString') then
    begin
      ConnParams := Properties['ConnectionString'];
      ConnParams := ConvertADOToFDConnectionString(ConnParams);
      SB.AppendLine('  ' + VCLConnName + '.ConnectionString := ''' +
        ConnParams.Replace('''', '''''') + ''';');
    end
    else if Properties.ContainsKey('Params') then
    begin
      ConnParams := Properties['Params'];
      SB.AppendLine('  ' + VCLConnName + '.Params.Text := ''' +
        ConnParams.Replace('''', '''''') + ''';');
    end;

    if Properties.ContainsKey('LoginPrompt') then
      SB.AppendLine('  ' + VCLConnName + '.LoginPrompt := ' +
        Properties['LoginPrompt'] + ';');

    if Properties.ContainsKey('Connected') and
       (Properties['Connected'] = 'True') then
      SB.AppendLine('  ' + VCLConnName + '.Connected := True;');

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TDatabaseConverter.ConvertQuery(const VCLQueryName: string;
  Properties: TDictionary<string, string>): string;
var
  SB: TStringBuilder;
  SQL: string;
  Connection: string;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('  // Converted from ' + VCLQueryName);
    SB.AppendLine('  ' + VCLQueryName + ': TFDQuery;');
    SB.AppendLine('');
    SB.AppendLine('  ' + VCLQueryName + ' := TFDQuery.Create(Self);');

    if Properties.ContainsKey('Connection') then
    begin
      Connection := Properties['Connection'];
      SB.AppendLine('  ' + VCLQueryName + '.Connection := ' + Connection + ';');
    end;

    if Properties.ContainsKey('SQL') then
    begin
      SQL := Properties['SQL'];
      SB.AppendLine('  ' + VCLQueryName + '.SQL.Text := ''' +
        SQL.Replace('''', '''''') + ''';');
    end;

    if Properties.ContainsKey('Active') and (Properties['Active'] = 'True') then
      SB.AppendLine('  ' + VCLQueryName + '.Active := True;');

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TDatabaseConverter.GenerateDatabaseDFM(const Component: TDFMComponent): string;
var
  SB: TStringBuilder;
  Prop: TPair<string, string>;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('  object ' + Component.Name + ': ' + Component.ComponentClass);

    for Prop in Component.Properties do
    begin
      if Prop.Key = 'Connection' then
        SB.AppendLine('    Connection = ' + Prop.Value)
      else if Prop.Key = 'SQL' then
        SB.AppendLine('    SQL.Strings = (' + Prop.Value + ')')
      else if Prop.Key = 'Params' then
        SB.AppendLine('    Params.Strings = (' + Prop.Value + ')')
      else if (Prop.Key <> 'Left') and (Prop.Key <> 'Top') then
        SB.AppendLine('    ' + Prop.Key + ' = ' + Prop.Value);
    end;

    SB.AppendLine('  end');
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TDatabaseConverter.GenerateDatabaseCode: string;
var
  SB: TStringBuilder;
  Pair: TPair<string, TJSONObject>;
  Props: TDictionary<string, string>;
  JSONPair: TJSONPair;
begin
  if (FConnectionInfo.Count = 0) and (FQueryInfo.Count = 0) then
    Exit('');

  SB := TStringBuilder.Create;
  try
    SB.AppendLine('  // FireDAC components converted from VCL database components');
    SB.AppendLine('');

    // Generate connections
    for Pair in FConnectionInfo do
    begin
      Props := TDictionary<string, string>.Create;
      try
        for JSONPair in Pair.Value do
          Props.Add(JSONPair.JsonString.Value, JSONPair.JsonValue.Value);

        SB.AppendLine(ConvertConnection(Pair.Key, Props));
        SB.AppendLine('');
      finally
        Props.Free;
      end;
    end;

    // Generate queries
    for Pair in FQueryInfo do
    begin
      Props := TDictionary<string, string>.Create;
      try
        for JSONPair in Pair.Value do
          Props.Add(JSONPair.JsonString.Value, JSONPair.JsonValue.Value);

        SB.AppendLine(ConvertQuery(Pair.Key, Props));
        SB.AppendLine('');
      finally
        Props.Free;
      end;
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

end.

