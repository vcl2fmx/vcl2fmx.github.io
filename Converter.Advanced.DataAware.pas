{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v7.0 Atlas
 Written and built in the USA}

unit Converter.Advanced.DataAware;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  System.Generics.Defaults,
  System.RTTI, System.JSON,
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

    procedure DetectDataAwareControls(Component: TDFMComponent);
  public
    constructor Create(AContext: TConversionContext; AMapper: TComponentMapper);
    destructor Destroy; override;

    procedure AnalyzeForm(Components: TObjectList<TDFMComponent>);
    property DataBindings: TObjectList<TDataBindingInfo> read FDataBindings;
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
  inherited Create;
  FOriginalProperties := TDictionary<string, string>.Create(TIStringComparer.Ordinal);
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
  inherited Create;
  FContext := AContext;
  FComponentMapper := AMapper;
  FDataBindings := TObjectList<TDataBindingInfo>.Create(True);
end;

destructor TLiveBindingConverter.Destroy;
begin
  FDataBindings.Free;
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

end.

