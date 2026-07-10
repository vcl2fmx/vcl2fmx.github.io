{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Mapper.Component;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  System.RTTI, System.TypInfo, System.JSON, System.IOUtils, System.Types,
  FMX.ComboEdit,
  Converter.Core.Types;

type
  TComponentResearch = class
  private
    FVCLClassName: string;
    FParentClass: string;
    FProperties: TList<string>;
    FMethods: TList<string>;
    FEvents: TList<string>;
    FScore: Integer;
  public
    property VCLClassName: string read FVCLClassName write FVCLClassName;
    property ParentClass: string read FParentClass write FParentClass;
    property Properties: TList<string> read FProperties;
    property Methods: TList<string> read FMethods;
    property Events: TList<string> read FEvents;
    property Score: Integer read FScore write FScore;

    constructor Create;
    destructor Destroy; override;
  end;

  TFMXComponentInfo = class
  private
    FClassName: string;
    FParentClass: string;
    FProperties: TList<string>;
    FMethods: TList<string>;
    FEvents: TList<string>;
    FCategory: string;
  public
    property FMXClassName: string read FClassName write FClassName;
    property ParentClass: string read FParentClass write FParentClass;
    property Properties: TList<string> read FProperties;
    property Methods: TList<string> read FMethods;
    property Events: TList<string> read FEvents;
    property Category: string read FCategory write FCategory;

    constructor Create;
    destructor Destroy; override;
  end;

  TRttiClassInventory = class
  private
    FClassName: string;
    FQualifiedName: string;
    FParentClass: string;
    FProperties: TDictionary<string, string>;
    FEvents: TDictionary<string, string>;
  public
    property RttiClassName: string read FClassName write FClassName;
    property QualifiedName: string read FQualifiedName write FQualifiedName;
    property ParentClass: string read FParentClass write FParentClass;
    property Properties: TDictionary<string, string> read FProperties;
    property Events: TDictionary<string, string> read FEvents;

    constructor Create;
    destructor Destroy; override;
  end;

  TComponentMapper = class
  private
    FContext: TConversionContext;
    FMappingDatabase: TObjectList<TComponentMapping>;
    FFMXComponents: TObjectList<TFMXComponentInfo>;
    FVCLInventories: TObjectDictionary<string, TRttiClassInventory>;
    FFMXInventories: TObjectDictionary<string, TRttiClassInventory>;
    FRTTIContext: TRttiContext;
    FMappingIndex: TDictionary<string, TComponentMapping>;
    FDerivedMappingCache: TObjectDictionary<string, TComponentMapping>;

    procedure LoadBuiltInMappings;
    procedure LoadMappingPacks;
    procedure LoadMappingPackFile(const FileName: string);
    procedure AddOrReplaceMapping(Mapping: TComponentMapping);
    function IsValidMappingPackAction(const Action: string): Boolean;
    procedure LoadFMXComponentCatalog;
    function ResolveVclRttiType(const TypeName: string): TRttiType;
    function ResolveFmxRttiType(const TypeName: string): TRttiType;
    procedure AddUniqueString(AStrings: TStrings; const Value: string);
    procedure BuildRTTIInventories;
    procedure RegisterInventoryType(
      Inventory: TObjectDictionary<string, TRttiClassInventory>; RttiType: TRttiType);
    function BuildEventSignature(const RttiType: TRttiType): string;
    function FindInventory(const ClassName: string;
      Inventory: TObjectDictionary<string, TRttiClassInventory>): TRttiClassInventory;
    procedure EnrichFMXCatalogFromInventory;
    procedure NormalizeFMXCatalogAgainstInventory;
    procedure ResearchEventMappings(const VCLComp, FMXComp: string;
      var Mapping: TComponentMapping);

    function ResearchVCLComponent(const VCLClassName: string;
      const ReportIssues: Boolean = True): TComponentResearch;
    function FindFMXMatch(const Research: TComponentResearch;
      const ReportIssues: Boolean = True): TComponentMapping;
    function CalculateMatchScore(const VCLResearch: TComponentResearch;
      const FMXComp: TFMXComponentInfo): Integer;
    function AnalyzeProperties(const VCLComp: TComponentResearch;
      const FMXComp: TFMXComponentInfo): Integer;
    function AnalyzeMethods(const VCLComp: TComponentResearch;
      const FMXComp: TFMXComponentInfo): Integer;
    function AnalyzeEvents(const VCLComp: TComponentResearch;
      const FMXComp: TFMXComponentInfo): Integer;
    function AnalyzeInheritance(const VCLComp: TComponentResearch;
      const FMXComp: TFMXComponentInfo): Integer;
    function IsPreservedCrossPlatformComponent(const VCLClassName: string): Boolean;
    function BuildPreservedComponentMapping(
      const VCLClassName: string): TComponentMapping;
    function NormalizeClassName(const ClassName: string): string;
    function BuildClassLookupKey(const ClassName: string): string;
    procedure ClearDerivedMappingCache;
    procedure RebuildMappingIndex;
    procedure RegisterResolvedMapping(const LookupKey: string;
      Mapping: TComponentMapping);
    function BuildBestMatch(const VCLClassName: string;
      const ReportIssues: Boolean): TComponentMapping;

    procedure ResearchPropertyMapping(const VCLComp, FMXComp: string;
      var Mapping: TComponentMapping; const ReportIssues: Boolean = True);
    function TryFindExplicitPropertyMapping(const Mapping: TComponentMapping;
      const PropName: string; out PropMap: TPropertyMapping): Boolean;
    function TryFindExplicitEventMapping(const Mapping: TComponentMapping;
      const EventName: string; out EventMap: TEventMapping): Boolean;
    function GetDefaultArtifactDirectory: string;
    function GetParserPolicy(const Mapping: TComponentMapping): string;
    function GetRuntimePolicyNotes(const Mapping: TComponentMapping): string;
    function ClassifyPropertyRule(const VCLClassName, PropName: string;
      const Mapping: TComponentMapping; out PropMap: TPropertyMapping;
      out Classification, RuleSource, Notes: string): Boolean;
    function ClassifyEventRule(const VCLClassName, EventName: string;
      const Mapping: TComponentMapping; out EventMap: TEventMapping;
      out Classification, RuleSource, VCLSignature, FMXSignature,
      Notes: string): Boolean;
    procedure ExportInventoryArtifacts(
      const Inventory: TObjectDictionary<string, TRttiClassInventory>;
      const FileName: string);
    procedure ExportClassMappingMatrix(const ArtifactDir: string);
    procedure ExportPropertyMappingMatrix(const ArtifactDir: string);
    procedure ExportEventMappingMatrix(const ArtifactDir: string);

  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    procedure LoadMappings(const MappingsFile: string = '');
    procedure SaveMappings(const MappingsFile: string);
    function FindMapping(const VCLClassName: string): TComponentMapping;
    function FindBestMatch(const VCLClassName: string): TComponentMapping;
    function EnsureBestMatch(const VCLClassName: string): TComponentMapping;
    function KnowsFMXClass(const FMXClassName: string): Boolean;
    function KnowsVCLClass(const VCLClassName: string): Boolean;
    function SupportsFMXProperty(const FMXClassName, PropName: string): Boolean;
    function SupportsFMXEvent(const FMXClassName, EventName: string): Boolean;
    function AreEventSignaturesCompatible(const VCLClassName, VCLEvent,
      FMXClassName, FMXEvent: string): Boolean;
    function GetVCLInventory(const VCLClassName: string): TRttiClassInventory;
    function GetFMXInventory(const FMXClassName: string): TRttiClassInventory;
    procedure PopulateDiscoverableVCLComponentClasses(AClasses: TStrings);
    procedure PopulateDiscoverablePropertyNames(const VCLClassName: string;
      APropertyNames: TStrings);
    procedure PopulateDiscoverableEventNames(const VCLClassName: string;
      AEventNames: TStrings);
    function ResolvePropertyMapping(const VCLClassName, PropName: string;
      out PropMap: TPropertyMapping): Boolean;
    function ResolveEventMapping(const VCLClassName, EventName: string;
      out EventMap: TEventMapping): Boolean;
    procedure ExportReferenceArtifacts(const ArtifactDir: string = '');
    procedure AddUserMapping(const Mapping: TComponentMapping);

    property MappingDatabase: TObjectList<TComponentMapping>
      read FMappingDatabase;
  end;

implementation

uses
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Dialogs, Vcl.Buttons, Vcl.Mask, Vcl.Grids, Vcl.Menus,
  Vcl.DBCtrls, Vcl.DBGrids, Vcl.CheckLst, Vcl.Samples.Spin,
  FMX.Forms, FMX.Controls, FMX.StdCtrls, FMX.Edit, FMX.ListBox,
  FMX.Memo, FMX.Layouts, FMX.Objects, FMX.ExtCtrls, FMX.ScrollBox,
  FMX.TabControl, FMX.Grid, FMX.Menus, FMX.Dialogs, FMX.ActnList,
  FMX.TreeView, FMX.DateTimeCtrls, FMX.Colors, FMX.SpinBox,
  FMX.NumberBox, FMX.Calendar, FMX.Media;

{$IFDEF DEBUG}
var
  GReferenceArtifactsExported: Boolean;
{$ENDIF}

{ TComponentResearch }

constructor TComponentResearch.Create;
begin
  FProperties := TList<string>.Create;
  FMethods := TList<string>.Create;
  FEvents := TList<string>.Create;
  FScore := 0;
end;

destructor TComponentResearch.Destroy;
begin
  FProperties.Free;
  FMethods.Free;
  FEvents.Free;
  inherited;
end;

{ TFMXComponentInfo }

constructor TFMXComponentInfo.Create;
begin
  FProperties := TList<string>.Create;
  FMethods := TList<string>.Create;
  FEvents := TList<string>.Create;
end;

destructor TFMXComponentInfo.Destroy;
begin
  FProperties.Free;
  FMethods.Free;
  FEvents.Free;
  inherited;
end;

{ TRttiClassInventory }

constructor TRttiClassInventory.Create;
begin
  FProperties := TDictionary<string, string>.Create;
  FEvents := TDictionary<string, string>.Create;
end;

destructor TRttiClassInventory.Destroy;
begin
  FProperties.Free;
  FEvents.Free;
  inherited;
end;

{ TComponentMapper }

constructor TComponentMapper.Create(AContext: TConversionContext);
begin
  FContext := AContext;
  FMappingDatabase := TObjectList<TComponentMapping>.Create(True);
  FFMXComponents := TObjectList<TFMXComponentInfo>.Create(True);
  FVCLInventories := TObjectDictionary<string, TRttiClassInventory>.Create([doOwnsValues]);
  FFMXInventories := TObjectDictionary<string, TRttiClassInventory>.Create([doOwnsValues]);
  FRTTIContext := TRttiContext.Create;
  FMappingIndex := TDictionary<string, TComponentMapping>.Create;
  FDerivedMappingCache := TObjectDictionary<string, TComponentMapping>.Create([doOwnsValues]);

  LoadBuiltInMappings;
  LoadFMXComponentCatalog;
  if Assigned(FContext) and Assigned(FContext.Options) and
     (FContext.Options.UserMappingsFile <> '') and
     FileExists(FContext.Options.UserMappingsFile) then
    LoadMappings(FContext.Options.UserMappingsFile);
  LoadMappingPacks;
  BuildRTTIInventories;
  EnrichFMXCatalogFromInventory;
  NormalizeFMXCatalogAgainstInventory;
  RebuildMappingIndex;

{$IFDEF DEBUG}
  if not GReferenceArtifactsExported then
    try
      ExportReferenceArtifacts;
      GReferenceArtifactsExported := True;
    except
      // Keep converter startup quiet if reference exports fail.
    end;
{$ENDIF}
end;

procedure TComponentMapper.AddOrReplaceMapping(Mapping: TComponentMapping);
var
  I: Integer;
begin
  if not Assigned(Mapping) then
    Exit;

  for I := FMappingDatabase.Count - 1 downto 0 do
  begin
    if SameText(BuildClassLookupKey(FMappingDatabase[I].VCLClassName),
                BuildClassLookupKey(Mapping.VCLClassName)) then
    begin
      FMappingDatabase.Delete(I);
      Break;
    end;
  end;

  FMappingDatabase.Add(Mapping);
end;

function TComponentMapper.IsValidMappingPackAction(
  const Action: string): Boolean;
begin
  Result := SameText(Action, 'convert') or
            SameText(Action, 'partial') or
            SameText(Action, 'manual_review') or
            SameText(Action, 'detect_only') or
            SameText(Action, 'preserve');
end;

procedure TComponentMapper.LoadMappingPacks;
var
  PackFolder: string;
  Files: TStringDynArray;
  SortedFiles: TStringList;
  FileName: string;
begin
  if (FContext = nil) or (FContext.Options = nil) or
     not FContext.Options.EnableMappingPacks then
    Exit;

  PackFolder := Trim(FContext.Options.MappingPackFolder);
  if PackFolder = '' then
    PackFolder := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
      'mapping_packs';

  if not DirectoryExists(PackFolder) and DirectoryExists(ExpandFileName('mapping_packs')) then
    PackFolder := ExpandFileName('mapping_packs');

  if not DirectoryExists(PackFolder) and
     DirectoryExists(ExpandFileName('..\..\mapping_packs')) then
    PackFolder := ExpandFileName('..\..\mapping_packs');

  if not DirectoryExists(PackFolder) then
  begin
    FContext.AddIssue(csInfo,
      'Mapping packs enabled, but no mapping pack folder was found: ' + PackFolder);
    Exit;
  end;

  Files := TDirectory.GetFiles(PackFolder, '*.json', TSearchOption.soTopDirectoryOnly);
  SortedFiles := TStringList.Create;
  try
    for FileName in Files do
      SortedFiles.Add(FileName);
    SortedFiles.Sort;

    for FileName in SortedFiles do
      LoadMappingPackFile(FileName);
  finally
    SortedFiles.Free;
  end;
end;

procedure TComponentMapper.LoadMappingPackFile(const FileName: string);
var
  JSONStr: string;
  JSONValue: TJSONValue;
  PackObj: TJSONObject;
  Rules: TJSONArray;
  RuleObj: TJSONObject;
  Mapping: TComponentMapping;
  PropArray: TJSONArray;
  PropObj: TJSONObject;
  PropMap: TPropertyMapping;
  EventArray: TJSONArray;
  EventObj: TJSONObject;
  EventMap: TEventMapping;
  ParsedMappings: TObjectList<TComponentMapping>;
  PackName: string;
  PackDisplayName: string;
  PackId: string;
  PackVendor: string;
  PackVersion: string;
  HasPropArray: Boolean;
  HasEventArray: Boolean;
  I, J: Integer;
begin
  JSONValue := nil;
  ParsedMappings := TObjectList<TComponentMapping>.Create(True);
  try
    JSONStr := TFile.ReadAllText(FileName, TEncoding.UTF8);
    JSONValue := TJSONObject.ParseJSONValue(JSONStr);
    if not (JSONValue is TJSONObject) then
      raise Exception.Create('Pack root must be a JSON object.');

    PackObj := TJSONObject(JSONValue);
    PackDisplayName := ChangeFileExt(ExtractFileName(FileName), '');
    PackName := PackObj.GetValue<string>('pack_name', PackDisplayName);
    PackId := PackObj.GetValue<string>('pack_id', ChangeFileExt(ExtractFileName(FileName), ''));
    PackVendor := PackObj.GetValue<string>('vendor', '');
    PackVersion := PackObj.GetValue<string>('version', '');

    if not PackObj.TryGetValue<TJSONArray>('rules', Rules) then
      raise Exception.Create('Pack does not contain a rules array.');

    for I := 0 to Rules.Count - 1 do
    begin
      if not (Rules.Items[I] is TJSONObject) then
        Continue;

      RuleObj := TJSONObject(Rules.Items[I]);
      Mapping := TComponentMapping.Create;
      try
        Mapping.VCLClassName := RuleObj.GetValue<string>('vcl_class', '');
        Mapping.FMXClassName := RuleObj.GetValue<string>('fmx_class', '');
        Mapping.Action := LowerCase(RuleObj.GetValue<string>('action', 'manual_review'));
        if not IsValidMappingPackAction(Mapping.Action) then
          raise Exception.CreateFmt('Rule for %s uses unsupported action "%s".',
            [Mapping.VCLClassName, Mapping.Action]);
        Mapping.MappingType := RuleObj.GetValue<string>('mapping_type', 'Pack');
        Mapping.Confidence := RuleObj.GetValue<Integer>('confidence',
          RuleObj.GetValue<Integer>('probability', 50));
        Mapping.Notes := RuleObj.GetValue<string>('notes', '');
        Mapping.ManualReviewReason := RuleObj.GetValue<string>('manual_review_reason', '');
        Mapping.Vendor := RuleObj.GetValue<string>('vendor', PackVendor);
        Mapping.PackName := RuleObj.GetValue<string>('pack_name', PackDisplayName);
        Mapping.PackVersion := RuleObj.GetValue<string>('pack_version', PackVersion);
        Mapping.MappingSource := 'pack';
        Mapping.IsThirdParty := True;

        if Trim(Mapping.VCLClassName) = '' then
          raise Exception.Create('Rule without vcl_class.');

        HasPropArray := RuleObj.TryGetValue<TJSONArray>('properties', PropArray);
        if not HasPropArray then
          HasPropArray := RuleObj.TryGetValue<TJSONArray>('property_maps', PropArray);
        if HasPropArray then
        begin
          for J := 0 to PropArray.Count - 1 do
          begin
            if not (PropArray.Items[J] is TJSONObject) then
              Continue;

            PropObj := TJSONObject(PropArray.Items[J]);
            PropMap.VCLProp := PropObj.GetValue<string>('vcl',
              PropObj.GetValue<string>('vcl_prop', ''));
            PropMap.FMXProp := PropObj.GetValue<string>('fmx',
              PropObj.GetValue<string>('fmx_prop', ''));
            PropMap.NeedsTransformation := PropObj.GetValue<Boolean>('needs_transform',
              PropObj.GetValue<Boolean>('needs_transformation', False));
            PropMap.TransformerFunc := PropObj.GetValue<string>('transformer',
              PropObj.GetValue<string>('transformer_func', ''));
            if (Trim(PropMap.VCLProp) <> '') and (Trim(PropMap.FMXProp) <> '') then
              Mapping.PropertyMaps.Add(PropMap);
          end;
        end;

        HasEventArray := RuleObj.TryGetValue<TJSONArray>('events', EventArray);
        if not HasEventArray then
          HasEventArray := RuleObj.TryGetValue<TJSONArray>('event_maps', EventArray);
        if HasEventArray then
        begin
          for J := 0 to EventArray.Count - 1 do
          begin
            if not (EventArray.Items[J] is TJSONObject) then
              Continue;

            EventObj := TJSONObject(EventArray.Items[J]);
            EventMap.VCLEvent := EventObj.GetValue<string>('vcl',
              EventObj.GetValue<string>('vcl_event', ''));
            EventMap.FMXEvent := EventObj.GetValue<string>('fmx',
              EventObj.GetValue<string>('fmx_event', ''));
            EventMap.SignatureMatch := EventObj.GetValue<Boolean>('signature_match', True);
            if (Trim(EventMap.VCLEvent) <> '') and (Trim(EventMap.FMXEvent) <> '') then
              Mapping.EventMaps.Add(EventMap);
          end;
        end;

        ParsedMappings.Add(Mapping);
        Mapping := nil;
      finally
        Mapping.Free;
      end;
    end;

    ParsedMappings.OwnsObjects := False;
    try
      for Mapping in ParsedMappings do
        AddOrReplaceMapping(Mapping);
    finally
      ParsedMappings.Clear;
      ParsedMappings.OwnsObjects := True;
    end;

    FContext.LoadedMappingPacks.Add(Format('%s (%s) - %d rules - %s',
      [PackDisplayName, PackId, Rules.Count, FileName]));
    FContext.AddIssue(csInfo, Format('Loaded mapping pack: %s (%d rules)',
      [PackDisplayName, Rules.Count]));
  except
    on E: Exception do
      if Assigned(FContext) then
        FContext.AddIssue(csWarning,
          Format('Mapping pack skipped: %s - %s', [ExtractFileName(FileName), E.Message]));
  end;
  ParsedMappings.Free;
  JSONValue.Free;
end;

destructor TComponentMapper.Destroy;
begin
  FDerivedMappingCache.Free;
  FMappingIndex.Free;
  FMappingDatabase.Free;
  FFMXComponents.Free;
  FVCLInventories.Free;
  FFMXInventories.Free;
  FRTTIContext.Free;
  inherited;
end;

function TComponentMapper.NormalizeClassName(const ClassName: string): string;
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

function TComponentMapper.BuildClassLookupKey(const ClassName: string): string;
begin
  Result := UpperCase(NormalizeClassName(ClassName));
end;

procedure TComponentMapper.ClearDerivedMappingCache;
begin
  if Assigned(FDerivedMappingCache) then
    FDerivedMappingCache.Clear;
end;

procedure TComponentMapper.RebuildMappingIndex;
var
  Mapping: TComponentMapping;
  LookupKey: string;
begin
  FMappingIndex.Clear;
  ClearDerivedMappingCache;

  for Mapping in FMappingDatabase do
  begin
    LookupKey := BuildClassLookupKey(Mapping.VCLClassName);
    if LookupKey <> '' then
      FMappingIndex.AddOrSetValue(LookupKey, Mapping);
  end;
end;

procedure TComponentMapper.RegisterResolvedMapping(const LookupKey: string;
  Mapping: TComponentMapping);
begin
  if not Assigned(Mapping) then
    Exit;

  FMappingDatabase.Add(Mapping);
  if LookupKey <> '' then
    FMappingIndex.AddOrSetValue(LookupKey, Mapping);

  // Pure lookup results are cached from the current mapping database.
  // Any material database change can invalidate those derived results.
  ClearDerivedMappingCache;
end;

procedure TComponentMapper.AddUniqueString(AStrings: TStrings;
  const Value: string);
begin
  if (AStrings = nil) or (Trim(Value) = '') then
    Exit;

  if AStrings.IndexOf(Value) < 0 then
    AStrings.Add(Value);
end;

function TComponentMapper.GetDefaultArtifactDirectory: string;
begin
  Result := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  if Result = '' then
    Result := ExpandFileName('.');
end;

function TComponentMapper.GetParserPolicy(
  const Mapping: TComponentMapping): string;
begin
  if not Assigned(Mapping) or (Trim(Mapping.FMXClassName) = '') then
    Exit('manual_review_only');

  if SameText(Mapping.MappingType, 'Direct') then
    Exit('stream_direct_target');
  if SameText(Mapping.MappingType, 'Preserved') then
    Exit('preserve_component_as_is');
  if SameText(Mapping.MappingType, 'Substitute') then
    Exit('substitute_target_class');
  if SameText(Mapping.MappingType, 'Researched') then
    Exit('inventory_guided_substitute');

  Result := 'manual_review_only';
end;

function TComponentMapper.GetRuntimePolicyNotes(
  const Mapping: TComponentMapping): string;
begin
  if not Assigned(Mapping) then
    Exit('');

  if Trim(Mapping.Notes) <> '' then
    Exit(Mapping.Notes);

  if Trim(Mapping.FMXClassName) = '' then
    Exit('Manual runtime handling is required because no FMX target class is defined.');

  if SameText(Mapping.MappingType, 'Preserved') then
    Exit('Preserve this runtime component as-is and verify its supporting units on the target platform.');

  if SameText(Mapping.MappingType, 'Substitute') then
    Exit('Review runtime behavior after conversion because the FMX target class is only a substitute.');

  Result := 'Standard FMX runtime semantics are expected.';
end;

function TComponentMapper.ClassifyPropertyRule(const VCLClassName,
  PropName: string; const Mapping: TComponentMapping; out PropMap: TPropertyMapping;
  out Classification, RuleSource, Notes: string): Boolean;
  function IsKnownOmittedProperty: Boolean;
  begin
    Result := SameText(PropName, 'Ctl3D') or
              SameText(PropName, 'ParentCtl3D') or
              SameText(PropName, 'ParentColor') or
              SameText(PropName, 'ParentBackground') or
              SameText(PropName, 'ParentDoubleBuffered') or
              SameText(PropName, 'DoubleBuffered') or
              SameText(PropName, 'DockSite') or
              SameText(PropName, 'UseDockManager') or
              SameText(PropName, 'BevelInner') or
              SameText(PropName, 'BevelOuter') or
              SameText(PropName, 'BevelKind') or
              SameText(PropName, 'BevelEdges') or
              SameText(PropName, 'StyleElements') or
              SameText(PropName, 'ParentShowHint') or
              SameText(PropName, 'ShowHint');

    if Assigned(Mapping) and
       (SameText(Mapping.VCLClassName, 'TComboBox') or
        SameText(Mapping.VCLClassName, 'TDBComboBox')) and
       SameText(PropName, 'Style') then
      Result := True;
  end;
begin
  Result := True;
  PropMap.VCLProp := PropName;
  PropMap.FMXProp := '';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Classification := 'manual_review';
  RuleSource := 'unresolved';
  Notes := 'No explicit or inventory-derived FMX property target was identified.';

  if not Assigned(Mapping) then
  begin
    RuleSource := 'unmapped_class';
    Notes := 'No component mapping row is available for this VCL class.';
    Exit;
  end;

  if TryFindExplicitPropertyMapping(Mapping, PropName, PropMap) then
  begin
    RuleSource := 'explicit';
    if Trim(PropMap.FMXProp) = '' then
    begin
      if IsKnownOmittedProperty then
      begin
        Classification := 'omit';
        Notes := 'Explicit mapper row omits this VCL-only or designer-only property from FMX output.';
      end
      else
      begin
        Classification := 'manual_review';
        Notes := 'Explicit mapper row leaves this property for manual review.';
      end;
      Exit;
    end;

    if PropMap.NeedsTransformation then
    begin
      Classification := 'transform';
      Notes := 'Explicit mapper row applies ' + PropMap.TransformerFunc + '.';
    end
    else if SameText(PropMap.VCLProp, PropMap.FMXProp) then
    begin
      Classification := 'direct';
      Notes := 'Explicit direct property rule.';
    end
    else
    begin
      Classification := 'rename';
      Notes := 'Explicit renamed property rule.';
    end;
    Exit;
  end;

  if Trim(Mapping.FMXClassName) = '' then
  begin
    RuleSource := 'unmapped_class';
    Notes := 'No FMX target class is defined for this component.';
    Exit;
  end;

  if SupportsFMXProperty(Mapping.FMXClassName, PropName) then
  begin
    PropMap.FMXProp := PropName;
    Classification := 'direct';
    RuleSource := 'inventory';
    Notes := 'Derived from matching published property names in the RTTI inventory.';
    Exit;
  end;

  if SameText(PropName, 'Caption') and
     SupportsFMXProperty(Mapping.FMXClassName, 'Text') then
  begin
    PropMap.FMXProp := 'Text';
    Classification := 'rename';
    RuleSource := 'heuristic';
    Notes := 'Caption maps to Text on the FMX target.';
    Exit;
  end;

  if SameText(PropName, 'Color') and
     SupportsFMXProperty(Mapping.FMXClassName, 'Color') then
  begin
    PropMap.FMXProp := 'Color';
    PropMap.NeedsTransformation := True;
    PropMap.TransformerFunc := 'TransformColor';
    Classification := 'transform';
    RuleSource := 'heuristic';
    Notes := 'Color maps directly to an FMX Color property with TransformColor.';
    Exit;
  end;

  if SameText(PropName, 'Color') and
     SupportsFMXProperty(Mapping.FMXClassName, 'Fill.Color') then
  begin
    PropMap.FMXProp := 'Fill.Color';
    PropMap.NeedsTransformation := True;
    PropMap.TransformerFunc := 'TransformColor';
    Classification := 'transform';
    RuleSource := 'heuristic';
    Notes := 'Color maps to Fill.Color on the FMX target with TransformColor.';
    Exit;
  end;

  if IsKnownOmittedProperty then
  begin
    Classification := 'omit';
    RuleSource := 'known_vcl_only';
    Notes := 'Known VCL-only or designer-only property omitted from FMX output.';
  end;
end;

function TComponentMapper.ClassifyEventRule(const VCLClassName,
  EventName: string; const Mapping: TComponentMapping; out EventMap: TEventMapping;
  out Classification, RuleSource, VCLSignature, FMXSignature,
  Notes: string): Boolean;
var
  VCLInfo: TRttiClassInventory;
  FMXInfo: TRttiClassInventory;
  KnownTarget: string;
  KnownRenameNote: string;

  function TryKnownRename(out TargetEvent, RenameNote: string): Boolean;
  begin
    Result := False;
    TargetEvent := '';
    RenameNote := '';

    if not Assigned(Mapping) or (Trim(Mapping.FMXClassName) = '') then
      Exit;

    if (SameText(Mapping.FMXClassName, 'TComboBox') or
        SameText(Mapping.FMXClassName, 'TComboEdit')) and
       SameText(EventName, 'OnDropDown') and
       SupportsFMXEvent(Mapping.FMXClassName, 'OnPopup') then
    begin
      TargetEvent := 'OnPopup';
      RenameNote := 'Dropdown notifications are routed through OnPopup in FMX.';
      Exit(True);
    end;

    if (SameText(Mapping.FMXClassName, 'TComboBox') or
        SameText(Mapping.FMXClassName, 'TComboEdit')) and
       SameText(EventName, 'OnCloseUp') and
       SupportsFMXEvent(Mapping.FMXClassName, 'OnClosePopup') then
    begin
      TargetEvent := 'OnClosePopup';
      RenameNote := 'Close-up notifications are routed through OnClosePopup in FMX.';
      Exit(True);
    end;

    if SameText(Mapping.FMXClassName, 'TDateEdit') and
       SameText(EventName, 'OnDropDown') and
       SupportsFMXEvent(Mapping.FMXClassName, 'OnOpenPicker') then
    begin
      TargetEvent := 'OnOpenPicker';
      RenameNote := 'Date picker opening is exposed as OnOpenPicker in FMX.';
      Exit(True);
    end;

    if SameText(Mapping.FMXClassName, 'TDateEdit') and
       SameText(EventName, 'OnCloseUp') and
       SupportsFMXEvent(Mapping.FMXClassName, 'OnClosePicker') then
    begin
      TargetEvent := 'OnClosePicker';
      RenameNote := 'Date picker closing is exposed as OnClosePicker in FMX.';
      Exit(True);
    end;

    if (SameText(Mapping.FMXClassName, 'TComboBox') or
        SameText(Mapping.FMXClassName, 'TListBox')) and
       SameText(EventName, 'OnSelect') and
       SupportsFMXEvent(Mapping.FMXClassName, 'OnChange') then
    begin
      TargetEvent := 'OnChange';
      RenameNote := 'Selection notifications are normalized to OnChange in FMX.';
      Exit(True);
    end;
  end;
begin
  Result := True;
  EventMap.VCLEvent := EventName;
  EventMap.FMXEvent := '';
  EventMap.SignatureMatch := False;
  Classification := 'manual_review';
  RuleSource := 'unresolved';
  Notes := 'No explicit or RTTI-derived FMX event target was identified.';
  VCLSignature := '';
  FMXSignature := '';

  VCLInfo := GetVCLInventory(VCLClassName);
  if Assigned(VCLInfo) then
    VCLInfo.Events.TryGetValue(EventName, VCLSignature);

  if not Assigned(Mapping) then
  begin
    RuleSource := 'unmapped_class';
    Notes := 'No component mapping row is available for this VCL class.';
    Exit;
  end;

  if TryFindExplicitEventMapping(Mapping, EventName, EventMap) then
  begin
    RuleSource := 'explicit';
    if Trim(EventMap.FMXEvent) = '' then
    begin
      Classification := 'manual_review';
      Notes := 'Explicit mapper row leaves this event for manual review.';
      Exit;
    end;

    FMXInfo := GetFMXInventory(Mapping.FMXClassName);
    if Assigned(FMXInfo) then
      FMXInfo.Events.TryGetValue(EventMap.FMXEvent, FMXSignature);

    if EventMap.SignatureMatch then
    begin
      if SameText(EventMap.VCLEvent, EventMap.FMXEvent) then
        Classification := 'direct'
      else
        Classification := 'rename';
      Notes := 'Explicit event rule from the built-in mapper.';
    end
    else
    begin
      Classification := 'incompatible_signature';
      Notes := 'Explicit event rule exists, but the event signatures still require manual review.';
    end;
    Exit;
  end;

  if Trim(Mapping.FMXClassName) = '' then
  begin
    Classification := 'unsupported';
    RuleSource := 'unmapped_class';
    Notes := 'No FMX target class is defined for this component.';
    Exit;
  end;

  if SupportsFMXEvent(Mapping.FMXClassName, EventName) then
  begin
    EventMap.FMXEvent := EventName;
    EventMap.SignatureMatch := AreEventSignaturesCompatible(
      VCLClassName, EventName, Mapping.FMXClassName, EventName);
    FMXInfo := GetFMXInventory(Mapping.FMXClassName);
    if Assigned(FMXInfo) then
      FMXInfo.Events.TryGetValue(EventName, FMXSignature);

    RuleSource := 'inventory';
    if EventMap.SignatureMatch then
    begin
      Classification := 'direct';
      Notes := 'Derived from matching published event names in the RTTI inventory.';
    end
    else
    begin
      Classification := 'incompatible_signature';
      Notes := 'The same event name exists on the FMX target, but the signatures differ.';
    end;
    Exit;
  end;

  if TryKnownRename(KnownTarget, KnownRenameNote) then
  begin
    EventMap.FMXEvent := KnownTarget;
    EventMap.SignatureMatch := AreEventSignaturesCompatible(
      VCLClassName, EventName, Mapping.FMXClassName, KnownTarget);
    FMXInfo := GetFMXInventory(Mapping.FMXClassName);
    if Assigned(FMXInfo) then
      FMXInfo.Events.TryGetValue(KnownTarget, FMXSignature);

    RuleSource := 'heuristic';
    if EventMap.SignatureMatch then
      Classification := 'rename'
    else
      Classification := 'incompatible_signature';
    Notes := KnownRenameNote;
    Exit;
  end;

  if SameText(EventName, 'OnKeyPress') and
     SupportsFMXEvent(Mapping.FMXClassName, 'OnTyping') then
  begin
    EventMap.FMXEvent := 'OnTyping';
    RuleSource := 'known_signature_difference';
    Classification := 'incompatible_signature';
    FMXInfo := GetFMXInventory(Mapping.FMXClassName);
    if Assigned(FMXInfo) then
      FMXInfo.Events.TryGetValue('OnTyping', FMXSignature);
    Notes := 'FMX routes text-input notifications through OnTyping/OnKeyDown instead of VCL OnKeyPress.';
  end;
end;

procedure TComponentMapper.ExportInventoryArtifacts(
  const Inventory: TObjectDictionary<string, TRttiClassInventory>;
  const FileName: string);
var
  RootArray: TJSONArray;
  ClassObject: TJSONObject;
  PropertyArray: TJSONArray;
  PropertyObject: TJSONObject;
  EventArray: TJSONArray;
  EventObject: TJSONObject;
  ClassNames: TStringList;
  PropertyNames: TStringList;
  EventNames: TStringList;
  ClassName: string;
  PropertyName: string;
  EventName: string;
  PropertyTypeName: string;
  EventSignature: string;
  ClassInfo: TRttiClassInventory;
begin
  RootArray := TJSONArray.Create;
  ClassNames := TStringList.Create;
  try
    for ClassName in Inventory.Keys do
      ClassNames.Add(ClassName);
    ClassNames.Sort;

    for ClassName in ClassNames do
    begin
      ClassInfo := FindInventory(ClassName, Inventory);
      if not Assigned(ClassInfo) then
        Continue;

      ClassObject := TJSONObject.Create;
      ClassObject.AddPair('class_name', ClassInfo.RttiClassName);
      ClassObject.AddPair('qualified_name', ClassInfo.QualifiedName);
      ClassObject.AddPair('parent_class', ClassInfo.ParentClass);

      PropertyArray := TJSONArray.Create;
      PropertyNames := TStringList.Create;
      try
        for PropertyName in ClassInfo.Properties.Keys do
          PropertyNames.Add(PropertyName);
        PropertyNames.Sort;

        for PropertyName in PropertyNames do
        begin
          if not ClassInfo.Properties.TryGetValue(PropertyName, PropertyTypeName) then
            PropertyTypeName := '';

          PropertyObject := TJSONObject.Create;
          PropertyObject.AddPair('name', PropertyName);
          PropertyObject.AddPair('type', PropertyTypeName);
          PropertyArray.Add(PropertyObject);
        end;
      finally
        PropertyNames.Free;
      end;
      ClassObject.AddPair('published_properties', PropertyArray);

      EventArray := TJSONArray.Create;
      EventNames := TStringList.Create;
      try
        for EventName in ClassInfo.Events.Keys do
          EventNames.Add(EventName);
        EventNames.Sort;

        for EventName in EventNames do
        begin
          if not ClassInfo.Events.TryGetValue(EventName, EventSignature) then
            EventSignature := '';

          EventObject := TJSONObject.Create;
          EventObject.AddPair('name', EventName);
          EventObject.AddPair('signature', EventSignature);
          EventArray.Add(EventObject);
        end;
      finally
        EventNames.Free;
      end;
      ClassObject.AddPair('published_events', EventArray);

      RootArray.Add(ClassObject);
    end;

    TFile.WriteAllText(FileName, RootArray.Format(2), TEncoding.UTF8);
  finally
    ClassNames.Free;
    RootArray.Free;
  end;
end;

procedure TComponentMapper.ExportClassMappingMatrix(const ArtifactDir: string);
var
  RootArray: TJSONArray;
  RowObject: TJSONObject;
  SortedMappings: TStringList;
  Mapping: TComponentMapping;
  VCLInfo: TRttiClassInventory;
  FMXInfo: TRttiClassInventory;
  I: Integer;
begin
  RootArray := TJSONArray.Create;
  SortedMappings := TStringList.Create;
  try
    for Mapping in FMappingDatabase do
      if (Trim(Mapping.VCLClassName) <> '') and
         (SortedMappings.IndexOf(Mapping.VCLClassName) < 0) then
        SortedMappings.AddObject(Mapping.VCLClassName, Mapping);
    SortedMappings.Sort;

    for I := 0 to SortedMappings.Count - 1 do
    begin
      Mapping := TComponentMapping(SortedMappings.Objects[I]);
      VCLInfo := GetVCLInventory(Mapping.VCLClassName);
      if Trim(Mapping.FMXClassName) <> '' then
        FMXInfo := GetFMXInventory(Mapping.FMXClassName)
      else
        FMXInfo := nil;

      RowObject := TJSONObject.Create;
      RowObject.AddPair('vcl_class', Mapping.VCLClassName);
      RowObject.AddPair('fmx_class', Mapping.FMXClassName);
      RowObject.AddPair('mapping_type', LowerCase(Mapping.MappingType));
      RowObject.AddPair('confidence', TJSONNumber.Create(Mapping.Confidence));
      RowObject.AddPair('notes', Mapping.Notes);
      RowObject.AddPair('parser_policy', GetParserPolicy(Mapping));
      RowObject.AddPair('runtime_policy_notes', GetRuntimePolicyNotes(Mapping));
      RowObject.AddPair('vcl_inventory_found', TJSONBool.Create(Assigned(VCLInfo)));
      RowObject.AddPair('fmx_inventory_found', TJSONBool.Create(Assigned(FMXInfo)));
      RootArray.Add(RowObject);
    end;

    TFile.WriteAllText(IncludeTrailingPathDelimiter(ArtifactDir) + 'class_mapping_matrix.json',
      RootArray.Format(2), TEncoding.UTF8);
  finally
    SortedMappings.Free;
    RootArray.Free;
  end;
end;

procedure TComponentMapper.ExportPropertyMappingMatrix(const ArtifactDir: string);
var
  RootArray: TJSONArray;
  RowObject: TJSONObject;
  SortedMappings: TStringList;
  PropertyNames: TStringList;
  Mapping: TComponentMapping;
  VCLInfo: TRttiClassInventory;
  PropName: string;
  PropTypeName: string;
  PropMap: TPropertyMapping;
  Classification: string;
  RuleSource: string;
  Notes: string;
  I: Integer;
begin
  RootArray := TJSONArray.Create;
  SortedMappings := TStringList.Create;
  try
    for Mapping in FMappingDatabase do
      if (Trim(Mapping.VCLClassName) <> '') and
         (SortedMappings.IndexOf(Mapping.VCLClassName) < 0) then
        SortedMappings.AddObject(Mapping.VCLClassName, Mapping);
    SortedMappings.Sort;

    for I := 0 to SortedMappings.Count - 1 do
    begin
      Mapping := TComponentMapping(SortedMappings.Objects[I]);
      PropertyNames := TStringList.Create;
      try
        VCLInfo := GetVCLInventory(Mapping.VCLClassName);
        if Assigned(VCLInfo) then
          for PropName in VCLInfo.Properties.Keys do
            AddUniqueString(PropertyNames, PropName);

        for PropMap in Mapping.PropertyMaps do
          AddUniqueString(PropertyNames, PropMap.VCLProp);
        PropertyNames.Sort;

        for PropName in PropertyNames do
        begin
          if Assigned(VCLInfo) and VCLInfo.Properties.TryGetValue(PropName, PropTypeName) then
          begin
            if Trim(PropTypeName) = '' then
              PropTypeName := 'published property';
          end
          else
            PropTypeName := 'published property';

          ClassifyPropertyRule(Mapping.VCLClassName, PropName, Mapping, PropMap,
            Classification, RuleSource, Notes);

          RowObject := TJSONObject.Create;
          RowObject.AddPair('vcl_class', Mapping.VCLClassName);
          RowObject.AddPair('vcl_property', PropName);
          RowObject.AddPair('source_type', PropTypeName);
          RowObject.AddPair('fmx_class', Mapping.FMXClassName);
          RowObject.AddPair('fmx_property', PropMap.FMXProp);
          RowObject.AddPair('classification', Classification);
          RowObject.AddPair('rule_source', RuleSource);
          RowObject.AddPair('needs_transformation',
            TJSONBool.Create(PropMap.NeedsTransformation));
          RowObject.AddPair('transformer', PropMap.TransformerFunc);
          RowObject.AddPair('notes', Notes);
          RootArray.Add(RowObject);
        end;
      finally
        PropertyNames.Free;
      end;
    end;

    TFile.WriteAllText(IncludeTrailingPathDelimiter(ArtifactDir) + 'property_mapping_matrix.json',
      RootArray.Format(2), TEncoding.UTF8);
  finally
    SortedMappings.Free;
    RootArray.Free;
  end;
end;

procedure TComponentMapper.ExportEventMappingMatrix(const ArtifactDir: string);
var
  RootArray: TJSONArray;
  RowObject: TJSONObject;
  SortedMappings: TStringList;
  EventNames: TStringList;
  Mapping: TComponentMapping;
  VCLInfo: TRttiClassInventory;
  EventName: string;
  EventMap: TEventMapping;
  Classification: string;
  RuleSource: string;
  Notes: string;
  VCLSignature: string;
  FMXSignature: string;
  I: Integer;
begin
  RootArray := TJSONArray.Create;
  SortedMappings := TStringList.Create;
  try
    for Mapping in FMappingDatabase do
      if (Trim(Mapping.VCLClassName) <> '') and
         (SortedMappings.IndexOf(Mapping.VCLClassName) < 0) then
        SortedMappings.AddObject(Mapping.VCLClassName, Mapping);
    SortedMappings.Sort;

    for I := 0 to SortedMappings.Count - 1 do
    begin
      Mapping := TComponentMapping(SortedMappings.Objects[I]);
      EventNames := TStringList.Create;
      try
        VCLInfo := GetVCLInventory(Mapping.VCLClassName);
        if Assigned(VCLInfo) then
          for EventName in VCLInfo.Events.Keys do
            AddUniqueString(EventNames, EventName);

        for EventMap in Mapping.EventMaps do
          AddUniqueString(EventNames, EventMap.VCLEvent);
        EventNames.Sort;

        for EventName in EventNames do
        begin
          ClassifyEventRule(Mapping.VCLClassName, EventName, Mapping, EventMap,
            Classification, RuleSource, VCLSignature, FMXSignature, Notes);

          RowObject := TJSONObject.Create;
          RowObject.AddPair('vcl_class', Mapping.VCLClassName);
          RowObject.AddPair('vcl_event', EventName);
          RowObject.AddPair('vcl_signature', VCLSignature);
          RowObject.AddPair('fmx_class', Mapping.FMXClassName);
          RowObject.AddPair('fmx_event', EventMap.FMXEvent);
          RowObject.AddPair('fmx_signature', FMXSignature);
          RowObject.AddPair('classification', Classification);
          RowObject.AddPair('rule_source', RuleSource);
          RowObject.AddPair('signature_compatible',
            TJSONBool.Create(EventMap.SignatureMatch));
          RowObject.AddPair('notes', Notes);
          RootArray.Add(RowObject);
        end;
      finally
        EventNames.Free;
      end;
    end;

    TFile.WriteAllText(IncludeTrailingPathDelimiter(ArtifactDir) + 'event_mapping_matrix.json',
      RootArray.Format(2), TEncoding.UTF8);
  finally
    SortedMappings.Free;
    RootArray.Free;
  end;
end;

procedure TComponentMapper.ExportReferenceArtifacts(const ArtifactDir: string);
var
  OutputDir: string;
begin
  if Trim(ArtifactDir) <> '' then
    OutputDir := ArtifactDir
  else
    OutputDir := GetDefaultArtifactDirectory;

  if Trim(OutputDir) = '' then
    Exit;

  TDirectory.CreateDirectory(OutputDir);
  ExportInventoryArtifacts(FVCLInventories,
    IncludeTrailingPathDelimiter(OutputDir) + 'vcl_class_inventory.json');
  ExportInventoryArtifacts(FFMXInventories,
    IncludeTrailingPathDelimiter(OutputDir) + 'fmx_class_inventory.json');
  ExportClassMappingMatrix(OutputDir);
  ExportPropertyMappingMatrix(OutputDir);
  ExportEventMappingMatrix(OutputDir);
end;

procedure TComponentMapper.LoadBuiltInMappings;
var
  Mapping: TComponentMapping;
  PropMap: TPropertyMapping;
  EventMap: TEventMapping;
begin
  // Direct mappings
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TForm';
  Mapping.FMXClassName := 'TForm';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;
  Mapping.Notes := 'Root forms are converted through dedicated parser rules; this row keeps form properties and events explicit in the mapping matrix.';

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Caption';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ClientWidth';
  PropMap.FMXProp := 'ClientWidth';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ClientHeight';
  PropMap.FMXProp := 'ClientHeight';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnCreate';
  EventMap.FMXEvent := 'OnCreate';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnShow';
  EventMap.FMXEvent := 'OnShow';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnMouseMove';
  EventMap.FMXEvent := 'OnMouseMove';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  FMappingDatabase.Add(Mapping);

  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TFrame';
  Mapping.FMXClassName := 'TFrame';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  Mapping.Notes := 'FMX frames are available and should be treated as first-class matrix entries.';
  FMappingDatabase.Add(Mapping);

  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TButton';
  Mapping.FMXClassName := 'TButton';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Enabled';
  PropMap.FMXProp := 'Enabled';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnClick';
  EventMap.FMXEvent := 'OnClick';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  FMappingDatabase.Add(Mapping);

  // TEdit mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TEdit';
  Mapping.FMXClassName := 'TEdit';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  PropMap.VCLProp := 'Text';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ReadOnly';
  PropMap.FMXProp := 'ReadOnly';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'MaxLength';
  PropMap.FMXProp := 'MaxLength';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnEnter';
  EventMap.FMXEvent := 'OnEnter';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnExit';
  EventMap.FMXEvent := 'OnExit';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyDown';
  EventMap.FMXEvent := 'OnKeyDown';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyUp';
  EventMap.FMXEvent := 'OnKeyUp';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  FMappingDatabase.Add(Mapping);

  // TMaskEdit -> TEdit
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMaskEdit';
  Mapping.FMXClassName := 'TEdit';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 80;
  Mapping.Notes := 'Use FMX TEdit and review EditMask behavior manually.';

  PropMap.VCLProp := 'Text';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ReadOnly';
  PropMap.FMXProp := 'ReadOnly';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'MaxLength';
  PropMap.FMXProp := 'MaxLength';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'EditMask';
  PropMap.FMXProp := '';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  FMappingDatabase.Add(Mapping);

  // TLabel mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TLabel';
  Mapping.FMXClassName := 'TLabel';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Layout';
  PropMap.FMXProp := 'TextSettings.VertAlign';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TStaticText -> TLabel
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TStaticText';
  Mapping.FMXClassName := 'TLabel';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 90;
  Mapping.Notes := 'Static text converts cleanly to an FMX label.';

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TPanel -> TPanel
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TPanel';
  Mapping.FMXClassName := 'TPanel';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  Mapping.Notes := 'Preserve visual FMX panel semantics for container controls';
  FMappingDatabase.Add(Mapping);

  // TGroupBox -> TGroupBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TGroupBox';
  Mapping.FMXClassName := 'TGroupBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  Mapping.Notes := 'Preserve visual FMX group box semantics and caption handling';

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TFlowPanel -> TFlowLayout
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TFlowPanel';
  Mapping.FMXClassName := 'TFlowLayout';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  Mapping.Notes := 'Use FMX TFlowLayout as the closest standard flow container.';
  FMappingDatabase.Add(Mapping);

  // TGridPanel -> TGridPanelLayout
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TGridPanel';
  Mapping.FMXClassName := 'TGridPanelLayout';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  Mapping.Notes := 'Use FMX TGridPanelLayout as the closest standard grid layout container.';
  FMappingDatabase.Add(Mapping);

  // TCheckBox mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TCheckBox';
  Mapping.FMXClassName := 'TCheckBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Checked';
  PropMap.FMXProp := 'IsChecked';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnClick';
  EventMap.FMXEvent := 'OnClick';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  FMappingDatabase.Add(Mapping);

  // TRadioButton mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TRadioButton';
  Mapping.FMXClassName := 'TRadioButton';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Checked';
  PropMap.FMXProp := 'IsChecked';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnClick';
  EventMap.FMXEvent := 'OnClick';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  FMappingDatabase.Add(Mapping);

  // TListBox mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TListBox';
  Mapping.FMXClassName := 'TListBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;
  Mapping.Notes := 'Item objects need conversion';

  PropMap.VCLProp := 'Items';
  PropMap.FMXProp := 'Items';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ItemIndex';
  PropMap.FMXProp := 'ItemIndex';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnClick';
  EventMap.FMXEvent := 'OnClick';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  FMappingDatabase.Add(Mapping);

  // TCheckListBox -> TListBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TCheckListBox';
  Mapping.FMXClassName := 'TListBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 70;
  Mapping.Notes := 'Use FMX TListBox and review checked-item behavior manually.';

  PropMap.VCLProp := 'Items';
  PropMap.FMXProp := 'Items';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ItemIndex';
  PropMap.FMXProp := 'ItemIndex';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TDBListBox -> TListBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBListBox';
  Mapping.FMXClassName := 'TListBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 60;
  Mapping.Notes := 'Use LiveBindings with FMX TListBox and review lookup/list-source behavior manually.';
  FMappingDatabase.Add(Mapping);

  // TComboBox mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TComboBox';
  Mapping.FMXClassName := 'TComboBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;

  PropMap.VCLProp := 'Text';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Items';
  PropMap.FMXProp := 'Items';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ItemIndex';
  PropMap.FMXProp := 'ItemIndex';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Style';
  PropMap.FMXProp := '';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnDropDown';
  EventMap.FMXEvent := 'OnPopup';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnCloseUp';
  EventMap.FMXEvent := 'OnClosePopup';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnSelect';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyDown';
  EventMap.FMXEvent := 'OnKeyDown';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyUp';
  EventMap.FMXEvent := 'OnKeyUp';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  FMappingDatabase.Add(Mapping);

  // TNumberBox mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TNumberBox';
  Mapping.FMXClassName := 'TNumberBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  Mapping.Notes := 'FMX TNumberBox is available in FMX.NumberBox';

  PropMap.VCLProp := 'MinValue';
  PropMap.FMXProp := 'Min';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'MaxValue';
  PropMap.FMXProp := 'Max';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Decimal';
  PropMap.FMXProp := 'DecimalDigits';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TSpinEdit -> TSpinBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TSpinEdit';
  Mapping.FMXClassName := 'TSpinBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 90;
  Mapping.Notes := 'FMX TSpinBox is available in FMX.SpinBox';

  PropMap.VCLProp := 'MinValue';
  PropMap.FMXProp := 'Min';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'MaxValue';
  PropMap.FMXProp := 'Max';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Increment';
  PropMap.FMXProp := 'Increment';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TColorBox -> TColorComboBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TColorBox';
  Mapping.FMXClassName := 'TColorComboBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  Mapping.Notes := 'FMX color-selection equivalent is TColorComboBox in FMX.Colors';
  FMappingDatabase.Add(Mapping);

  // TMemo mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMemo';
  Mapping.FMXClassName := 'TMemo';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;

  PropMap.VCLProp := 'Lines';
  PropMap.FMXProp := 'Lines';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ReadOnly';
  PropMap.FMXProp := 'ReadOnly';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'WordWrap';
  PropMap.FMXProp := 'WordWrap';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyDown';
  EventMap.FMXEvent := 'OnKeyDown';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnKeyUp';
  EventMap.FMXEvent := 'OnKeyUp';
  EventMap.SignatureMatch := False;
  Mapping.EventMaps.Add(EventMap);

  FMappingDatabase.Add(Mapping);

  // TRichEdit -> TMemo
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TRichEdit';
  Mapping.FMXClassName := 'TMemo';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 75;
  Mapping.Notes := 'Use FMX TMemo and review rich-text formatting behavior manually.';

  PropMap.VCLProp := 'Lines';
  PropMap.FMXProp := 'Lines';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ReadOnly';
  PropMap.FMXProp := 'ReadOnly';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'WordWrap';
  PropMap.FMXProp := 'WordWrap';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TPaintBox mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TPaintBox';
  Mapping.FMXClassName := 'TPaintBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;
  Mapping.Notes := 'FMX TPaintBox is available in FMX.Objects';
  FMappingDatabase.Add(Mapping);

  // TImage mapping
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TImage';
  Mapping.FMXClassName := 'TImage';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;

  PropMap.VCLProp := 'Picture';
  PropMap.FMXProp := 'Bitmap';
  PropMap.NeedsTransformation := True;
  PropMap.TransformerFunc := 'TransformPicture';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TPageControl -> TTabControl
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TPageControl';
  Mapping.FMXClassName := 'TTabControl';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  FMappingDatabase.Add(Mapping);

  // TTabSheet -> TTabItem
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTabSheet';
  Mapping.FMXClassName := 'TTabItem';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 90;
  FMappingDatabase.Add(Mapping);

  // TScrollBox -> TScrollBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TScrollBox';
  Mapping.FMXClassName := 'TScrollBox';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;
  FMappingDatabase.Add(Mapping);

  // TStringGrid -> TStringGrid
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TStringGrid';
  Mapping.FMXClassName := 'TStringGrid';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 70;
  Mapping.Notes := 'Data model completely different - requires LiveBindings';
  FMappingDatabase.Add(Mapping);

  // TDBEdit -> TEdit (with LiveBindings)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBEdit';
  Mapping.FMXClassName := 'TEdit';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 60;
  Mapping.Notes := 'Use LiveBindings to connect to data source';
  FMappingDatabase.Add(Mapping);

  // TDBCheckBox -> TCheckBox (with LiveBindings)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBCheckBox';
  Mapping.FMXClassName := 'TCheckBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 55;
  Mapping.Notes := 'Use LiveBindings to connect to data source';
  FMappingDatabase.Add(Mapping);

  // TDBComboBox -> TComboEdit (with LiveBindings)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBComboBox';
  Mapping.FMXClassName := 'TComboEdit';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 50;
  Mapping.Notes := 'Use LiveBindings to connect to data source';
  FMappingDatabase.Add(Mapping);

  // TDBGrid -> TStringGrid
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBGrid';
  Mapping.FMXClassName := 'TStringGrid';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 50;
  Mapping.Notes := 'Major architectural difference - requires LiveBindings completely';
  FMappingDatabase.Add(Mapping);

  // TDrawGrid -> TStringGrid
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDrawGrid';
  Mapping.FMXClassName := 'TStringGrid';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 55;
  Mapping.Notes := 'Use FMX TStringGrid and review custom drawing/cell rendering manually.';
  FMappingDatabase.Add(Mapping);

  // TDBCtrlGrid -> TStringGrid
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBCtrlGrid';
  Mapping.FMXClassName := 'TStringGrid';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 45;
  Mapping.Notes := 'Major structural difference - requires LiveBindings and manual layout review.';
  FMappingDatabase.Add(Mapping);

  // TDBNavigator -> TBindNavigator
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDBNavigator';
  Mapping.FMXClassName := 'TBindNavigator';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  Mapping.Notes := 'Use FMX LiveBindings navigator with generated TBindSourceDB hookup';
  FMappingDatabase.Add(Mapping);

  // TMainMenu -> TMenuBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMainMenu';
  Mapping.FMXClassName := 'TMenuBar';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 85;
  FMappingDatabase.Add(Mapping);

  // TMenuItem -> TMenuItem
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMenuItem';
  Mapping.FMXClassName := 'TMenuItem';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  FMappingDatabase.Add(Mapping);

  // TPopupMenu -> TPopupMenu
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TPopupMenu';
  Mapping.FMXClassName := 'TPopupMenu';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;
  FMappingDatabase.Add(Mapping);

  // TTimer -> TTimer
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTimer';
  Mapping.FMXClassName := 'TTimer';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 100;

  EventMap.VCLEvent := 'OnTimer';
  EventMap.FMXEvent := 'OnTimer';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  FMappingDatabase.Add(Mapping);

  // TOpenDialog -> TOpenDialog
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TOpenDialog';
  Mapping.FMXClassName := 'TOpenDialog';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;

  PropMap.VCLProp := 'FileName';
  PropMap.FMXProp := 'FileName';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Filter';
  PropMap.FMXProp := 'Filter';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'DefaultExt';
  PropMap.FMXProp := 'DefaultExt';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'InitialDir';
  PropMap.FMXProp := 'InitialDir';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Title';
  PropMap.FMXProp := 'Title';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TFileOpenDialog -> TOpenDialog
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TFileOpenDialog';
  Mapping.FMXClassName := 'TOpenDialog';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 60;
  Mapping.Notes := 'Use FMX TOpenDialog as the closest standard substitute';
  FMappingDatabase.Add(Mapping);

  // TSaveDialog -> TSaveDialog
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TSaveDialog';
  Mapping.FMXClassName := 'TSaveDialog';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;

  PropMap.VCLProp := 'FileName';
  PropMap.FMXProp := 'FileName';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Filter';
  PropMap.FMXProp := 'Filter';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'DefaultExt';
  PropMap.FMXProp := 'DefaultExt';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'InitialDir';
  PropMap.FMXProp := 'InitialDir';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Title';
  PropMap.FMXProp := 'Title';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TFileSaveDialog -> TSaveDialog
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TFileSaveDialog';
  Mapping.FMXClassName := 'TSaveDialog';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 65;
  Mapping.Notes := 'Use FMX TSaveDialog as the closest standard substitute.';

  PropMap.VCLProp := 'FileName';
  PropMap.FMXProp := 'FileName';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'DefaultExtension';
  PropMap.FMXProp := 'DefaultExt';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'DefaultFolder';
  PropMap.FMXProp := 'InitialDir';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Title';
  PropMap.FMXProp := 'Title';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TFontDialog -> generated compatibility class
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TFontDialog';
  Mapping.FMXClassName := 'TFontDialog';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 70;
  Mapping.Notes := 'Generated compatibility dialog with a streamed Font property and Execute support';
  FMappingDatabase.Add(Mapping);

  // TRadioGroup -> generated compatibility class
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TRadioGroup';
  Mapping.FMXClassName := 'TRadioGroup';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 75;
  Mapping.Notes := 'Generated compatibility group that rebuilds internal FMX radio buttons from Items';

  PropMap.VCLProp := 'Items';
  PropMap.FMXProp := 'Items';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ItemIndex';
  PropMap.FMXProp := 'ItemIndex';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TLinkLabel -> TLabel
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TLinkLabel';
  Mapping.FMXClassName := 'TLabel';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 65;
  Mapping.Notes := 'Hyperlink behavior requires manual review, but the visual text target is an FMX label.';

  PropMap.VCLProp := 'Caption';
  PropMap.FMXProp := 'Text';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TTrayIcon -> no generic FMX equivalent
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTrayIcon';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'No standard FMX tray icon component - requires platform-specific code';
  FMappingDatabase.Add(Mapping);

  // TApdComPort -> third-party serial component with no generic FMX equivalent
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TApdComPort';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'Third-party serial communications component - requires a custom FMX/WinAPI replacement';
  FMappingDatabase.Add(Mapping);

  // TColorDialog -> generated compatibility class
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TColorDialog';
  Mapping.FMXClassName := 'TColorDialog';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 70;
  Mapping.Notes := 'Generated compatibility dialog with a Color property and Execute support';
  FMappingDatabase.Add(Mapping);

  // TActionList -> TActionList
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TActionList';
  Mapping.FMXClassName := 'TActionList';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  FMappingDatabase.Add(Mapping);

  // TAction -> TAction
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TAction';
  Mapping.FMXClassName := 'TAction';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;
  FMappingDatabase.Add(Mapping);

  // TImageList -> TImageList
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TImageList';
  Mapping.FMXClassName := 'TImageList';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;
  FMappingDatabase.Add(Mapping);

  // TSplitter -> TSplitter
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TSplitter';
  Mapping.FMXClassName := 'TSplitter';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 90;
  FMappingDatabase.Add(Mapping);

  // TStatusBar -> TStatusBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TStatusBar';
  Mapping.FMXClassName := 'TStatusBar';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;
  FMappingDatabase.Add(Mapping);

  // TToolBar -> TToolBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TToolBar';
  Mapping.FMXClassName := 'TToolBar';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 85;
  FMappingDatabase.Add(Mapping);

  // TProgressBar -> TProgressBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TProgressBar';
  Mapping.FMXClassName := 'TProgressBar';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;

  PropMap.VCLProp := 'Position';
  PropMap.FMXProp := 'Value';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TTrackBar -> TTrackBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTrackBar';
  Mapping.FMXClassName := 'TTrackBar';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 95;

  PropMap.VCLProp := 'Position';
  PropMap.FMXProp := 'Value';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TUpDown -> TSpinBox
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TUpDown';
  Mapping.FMXClassName := 'TSpinBox';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 70;

  PropMap.VCLProp := 'Position';
  PropMap.FMXProp := 'Value';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Min';
  PropMap.FMXProp := 'Min';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Max';
  PropMap.FMXProp := 'Max';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TDateTimePicker -> TDateEdit
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TDateTimePicker';
  Mapping.FMXClassName := 'TDateEdit';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 75;

  PropMap.VCLProp := 'Date';
  PropMap.FMXProp := 'Date';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Time';
  PropMap.FMXProp := 'Time';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Checked';
  PropMap.FMXProp := 'IsChecked';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'ShowCheckBox';
  PropMap.FMXProp := 'ShowCheckBox';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Format';
  PropMap.FMXProp := 'Format';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  EventMap.VCLEvent := 'OnChange';
  EventMap.FMXEvent := 'OnChange';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnDropDown';
  EventMap.FMXEvent := 'OnOpenPicker';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  EventMap.VCLEvent := 'OnCloseUp';
  EventMap.FMXEvent := 'OnClosePicker';
  EventMap.SignatureMatch := True;
  Mapping.EventMaps.Add(EventMap);

  FMappingDatabase.Add(Mapping);

  // TMonthCalendar -> TCalendar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMonthCalendar';
  Mapping.FMXClassName := 'TCalendar';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 80;

  PropMap.VCLProp := 'Date';
  PropMap.FMXProp := 'Date';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TTreeView -> TTreeView
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTreeView';
  Mapping.FMXClassName := 'TTreeView';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 85;
  FMappingDatabase.Add(Mapping);

  // TListView -> TListView
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TListView';
  Mapping.FMXClassName := 'TListView';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;
  FMappingDatabase.Add(Mapping);

  // TWebBrowser -> TWebBrowser
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TWebBrowser';
  Mapping.FMXClassName := 'TWebBrowser';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;
  FMappingDatabase.Add(Mapping);

  // TShape -> TShape (but different properties)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TShape';
  Mapping.FMXClassName := 'TShape';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 70;

  PropMap.VCLProp := 'Brush';
  PropMap.FMXProp := 'Fill';
  PropMap.NeedsTransformation := True;
  PropMap.TransformerFunc := 'TransformBrush';
  Mapping.PropertyMaps.Add(PropMap);

  PropMap.VCLProp := 'Pen';
  PropMap.FMXProp := 'Stroke';
  PropMap.NeedsTransformation := True;
  PropMap.TransformerFunc := 'TransformPen';
  Mapping.PropertyMaps.Add(PropMap);

  FMappingDatabase.Add(Mapping);

  // TBevel -> TRectangle (approximation)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TBevel';
  Mapping.FMXClassName := 'TRectangle';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 60;
  Mapping.Notes := 'Use TRectangle with appropriate Fill and Stroke';
  FMappingDatabase.Add(Mapping);

  // TScrollBar -> TScrollBar
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TScrollBar';
  Mapping.FMXClassName := 'TScrollBar';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 85;
  FMappingDatabase.Add(Mapping);

  // TSpeedButton -> TSpeedButton
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TSpeedButton';
  Mapping.FMXClassName := 'TSpeedButton';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 85;
  FMappingDatabase.Add(Mapping);

  // TBitBtn -> TButton (with Image)
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TBitBtn';
  Mapping.FMXClassName := 'TButton';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 75;
  Mapping.Notes := 'Use TButton with Images property';
  FMappingDatabase.Add(Mapping);

  // TLabeledEdit -> TLayout + TEdit
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TLabeledEdit';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 65;
  Mapping.Notes := 'Create TLayout with TLabel and TEdit';
  FMappingDatabase.Add(Mapping);

  // TValueListEditor -> TGrid
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TValueListEditor';
  Mapping.FMXClassName := 'TGrid';
  Mapping.MappingType := 'Substitute';
  Mapping.Confidence := 50;
  Mapping.Notes := 'Complex - requires custom grid implementation';
  FMappingDatabase.Add(Mapping);

  // TChart -> Not available in standard FMX
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TChart';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'Requires TMS FMX Chart or similar third-party component';
  FMappingDatabase.Add(Mapping);

  // TTaskDialog -> no standard FMX equivalent
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TTaskDialog';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'No standard FMX task dialog component - requires a custom dialog implementation.';
  FMappingDatabase.Add(Mapping);

  // Explicit dataset rows for matrix completeness
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TClientDataSet';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'Dataset component requires manual review; preserve only if the target platform and supporting units are appropriate.';
  FMappingDatabase.Add(Mapping);

  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TQuery';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'Legacy query component requires manual review or replacement.';
  FMappingDatabase.Add(Mapping);

  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TADODataSet';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'Windows-specific ADO dataset requires manual review for FMX targets.';
  FMappingDatabase.Add(Mapping);

  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TSQLDataSet';
  Mapping.FMXClassName := '';
  Mapping.MappingType := 'Unmapped';
  Mapping.Confidence := 0;
  Mapping.Notes := 'dbExpress dataset requires manual review for FMX targets.';
  FMappingDatabase.Add(Mapping);

  // TMediaPlayer -> TMediaPlayer
  Mapping := TComponentMapping.Create;
  Mapping.VCLClassName := 'TMediaPlayer';
  Mapping.FMXClassName := 'TMediaPlayer';
  Mapping.MappingType := 'Direct';
  Mapping.Confidence := 80;
  FMappingDatabase.Add(Mapping);
end;

procedure TComponentMapper.LoadFMXComponentCatalog;
var
  FMXComp: TFMXComponentInfo;
begin
  // Standard FMX components catalog
  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TControl';
  FMXComp.ParentClass := '';
  FMXComp.Category := 'Base';
  FMXComp.Properties.Add('Align');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Properties.Add('Visible');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('Size');
  FMXComp.Properties.Add('Width');
  FMXComp.Properties.Add('Height');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('ShowHint');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('TabStop');
  FMXComp.Properties.Add('Opacity');
  FMXComp.Properties.Add('Margins');
  FMXComp.Properties.Add('Padding');
  FMXComp.Properties.Add('HitTest');
  FMXComp.Events.Add('OnClick');
  FMXComp.Events.Add('OnDblClick');
  FMXComp.Events.Add('OnEnter');
  FMXComp.Events.Add('OnExit');
  FMXComp.Events.Add('OnMouseDown');
  FMXComp.Events.Add('OnMouseMove');
  FMXComp.Events.Add('OnMouseUp');
  FMXComp.Events.Add('OnMouseWheel');
  FMXComp.Events.Add('OnKeyDown');
  FMXComp.Events.Add('OnKeyUp');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TForm';
  FMXComp.ParentClass := 'TCommonCustomForm';
  FMXComp.Category := 'Forms';
  FMXComp.Properties.Add('Caption');
  FMXComp.Properties.Add('ClientWidth');
  FMXComp.Properties.Add('ClientHeight');
  FMXComp.Properties.Add('Width');
  FMXComp.Properties.Add('Height');
  FMXComp.Properties.Add('Left');
  FMXComp.Properties.Add('Top');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('FormStyle');
  FMXComp.Properties.Add('BorderStyle');
  FMXComp.Properties.Add('Transparency');
  FMXComp.Events.Add('OnClick');
  FMXComp.Events.Add('OnCreate');
  FMXComp.Events.Add('OnShow');
  FMXComp.Events.Add('OnClose');
  FMXComp.Events.Add('OnMouseDown');
  FMXComp.Events.Add('OnMouseMove');
  FMXComp.Events.Add('OnMouseUp');
  FMXComp.Events.Add('OnMouseWheel');
  FMXComp.Events.Add('OnResize');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TButton';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Properties.Add('Visible');
  FMXComp.Properties.Add('Width');
  FMXComp.Properties.Add('Height');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('TabStop');
  FMXComp.Properties.Add('StyledSettings');
  FMXComp.Properties.Add('Font');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Events.Add('OnClick');
  FMXComp.Events.Add('OnDblClick');
  FMXComp.Events.Add('OnMouseDown');
  FMXComp.Events.Add('OnMouseUp');
  FMXComp.Events.Add('OnMouseMove');
  FMXComp.Events.Add('OnKeyDown');
  FMXComp.Events.Add('OnKeyUp');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TEdit';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Properties.Add('ReadOnly');
  FMXComp.Properties.Add('Password');
  FMXComp.Properties.Add('MaxLength');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnDblClick');
  FMXComp.Events.Add('OnEnter');
  FMXComp.Events.Add('OnExit');
  FMXComp.Events.Add('OnKeyDown');
  FMXComp.Events.Add('OnKeyUp');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TLabel';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('AutoSize');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Properties.Add('Trimming');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Properties.Add('Font');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Events.Add('OnClick');
  FMXComp.Events.Add('OnDblClick');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TCheckBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('IsChecked');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Properties.Add('StyledSettings');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnDblClick');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TRadioButton';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('IsChecked');
  FMXComp.Properties.Add('GroupName');
  FMXComp.Properties.Add('StyledSettings');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnDblClick');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TListBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Properties.Add('ItemHeight');
  FMXComp.Properties.Add('MultiSelect');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnItemClick');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TComboBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Properties.Add('ItemHeight');
  FMXComp.Properties.Add('DropDownCount');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnClosePopup');
  FMXComp.Events.Add('OnPopup');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TComboEdit';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Properties.Add('ItemHeight');
  FMXComp.Properties.Add('DropDownCount');
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('ShowHint');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('Size');
  FMXComp.Properties.Add('Width');
  FMXComp.Properties.Add('Height');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnClosePopup');
  FMXComp.Events.Add('OnPopup');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TMemo';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Lines');
  FMXComp.Properties.Add('ReadOnly');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Properties.Add('MaxLength');
  FMXComp.Events.Add('OnChange');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TImage';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Additional';
  FMXComp.Properties.Add('Bitmap');
  FMXComp.Properties.Add('WrapMode');
  FMXComp.Properties.Add('DisableInterpolation');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TTabControl';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Tabs');
  FMXComp.Properties.Add('TabIndex');
  FMXComp.Properties.Add('TabPosition');
  FMXComp.Events.Add('OnChange');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TTabItem';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('IsSelected');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TGrid';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('RowCount');
  FMXComp.Properties.Add('ColumnCount');
  FMXComp.Properties.Add('DefaultRowHeight');
  FMXComp.Properties.Add('ShowScrollBars');
  FMXComp.Events.Add('OnCellClick');
  FMXComp.Events.Add('OnCellDblClick');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TStringGrid';
  FMXComp.ParentClass := 'TCustomGrid';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('RowCount');
  FMXComp.Properties.Add('ColumnCount');
  FMXComp.Properties.Add('DefaultRowHeight');
  FMXComp.Properties.Add('ShowScrollBars');
  FMXComp.Events.Add('OnCellClick');
  FMXComp.Events.Add('OnCellDblClick');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TLayout';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('EnableDrag');
  FMXComp.Properties.Add('HitTest');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TPanel';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Align');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Properties.Add('ClipChildren');
  FMXComp.Properties.Add('Height');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('Margins');
  FMXComp.Properties.Add('Opacity');
  FMXComp.Properties.Add('Padding');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('ShowHint');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('Visible');
  FMXComp.Properties.Add('Width');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TGroupBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Align');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Properties.Add('ClipChildren');
  FMXComp.Properties.Add('Height');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('Margins');
  FMXComp.Properties.Add('Opacity');
  FMXComp.Properties.Add('Padding');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('ShowHint');
  FMXComp.Properties.Add('StyledSettings');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Properties.Add('WordWrap');
  FMXComp.Properties.Add('Visible');
  FMXComp.Properties.Add('Width');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TRectangle';
  FMXComp.ParentClass := 'TShape';
  FMXComp.Category := 'Shapes';
  FMXComp.Properties.Add('Fill');
  FMXComp.Properties.Add('Fill.Color');
  FMXComp.Properties.Add('Stroke');
  FMXComp.Properties.Add('Stroke.Color');
  FMXComp.Properties.Add('Corners');
  FMXComp.Properties.Add('Sides');
  FMXComp.Properties.Add('XRadius');
  FMXComp.Properties.Add('YRadius');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TCircle';
  FMXComp.ParentClass := 'TShape';
  FMXComp.Category := 'Shapes';
  FMXComp.Properties.Add('Fill');
  FMXComp.Properties.Add('Fill.Color');
  FMXComp.Properties.Add('Stroke');
  FMXComp.Properties.Add('Stroke.Color');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TScrollBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('ShowScrollBars');
  FMXComp.Properties.Add('AniCalculations');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TMenuBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TMenuItem';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('Items');
  FMXComp.Events.Add('OnClick');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TPopupMenu';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Properties.Add('PopupComponent');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TTimer';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'System';
  FMXComp.Properties.Add('Interval');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Events.Add('OnTimer');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TOpenDialog';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Dialogs';
  FMXComp.Properties.Add('FileName');
  FMXComp.Properties.Add('Filter');
  FMXComp.Properties.Add('DefaultExt');
  FMXComp.Properties.Add('Title');
  FMXComp.Events.Add('OnClose');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TSaveDialog';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Dialogs';
  FMXComp.Properties.Add('FileName');
  FMXComp.Properties.Add('Filter');
  FMXComp.Properties.Add('DefaultExt');
  FMXComp.Properties.Add('Title');
  FMXComp.Events.Add('OnClose');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TColorDialog';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Dialogs';
  FMXComp.Properties.Add('Color');
  FMXComp.Events.Add('OnClose');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TActionList';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Actions');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TAction';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('AutoCheck');
  FMXComp.Properties.Add('Text');
  FMXComp.Properties.Add('ShortCut');
  FMXComp.Properties.Add('SecondaryShortCuts');
  FMXComp.Properties.Add('Enabled');
  FMXComp.Properties.Add('Checked');
  FMXComp.Properties.Add('GroupIndex');
  FMXComp.Properties.Add('HelpContext');
  FMXComp.Properties.Add('HelpKeyword');
  FMXComp.Properties.Add('HelpType');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('ImageIndex');
  FMXComp.Properties.Add('Visible');
  FMXComp.Events.Add('OnExecute');
  FMXComp.Events.Add('OnUpdate');
  FMXComp.Events.Add('OnHint');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TImageList';
  FMXComp.ParentClass := 'TComponent';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Source');
  FMXComp.Properties.Add('Size');
  FMXComp.Properties.Add('Bitmap');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TSplitter';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('ResizeControl');
  FMXComp.Properties.Add('ResizeStyle');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TStatusBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Panels');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TToolBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TBindNavigator';
  FMXComp.ParentClass := 'TLayout';
  FMXComp.Category := 'DataBinding';
  FMXComp.Properties.Add('DataSource');
  FMXComp.Properties.Add('VisibleButtons');
  FMXComp.Properties.Add('BeforeAction');
  FMXComp.Properties.Add('Hint');
  FMXComp.Properties.Add('ShowHint');
  FMXComp.Properties.Add('TabOrder');
  FMXComp.Properties.Add('Position');
  FMXComp.Properties.Add('Size');
  FMXComp.Properties.Add('Width');
  FMXComp.Properties.Add('Height');
  FMXComp.Events.Add('BeforeAction');
  FMXComp.Events.Add('OnClick');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TProgressBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Value');
  FMXComp.Properties.Add('Min');
  FMXComp.Properties.Add('Max');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TTrackBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Value');
  FMXComp.Properties.Add('Min');
  FMXComp.Properties.Add('Max');
  FMXComp.Properties.Add('Orientation');
  FMXComp.Properties.Add('Anchors');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnDblClick');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TSpinBox';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Value');
  FMXComp.Properties.Add('Min');
  FMXComp.Properties.Add('Max');
  FMXComp.Properties.Add('Frequency');
  FMXComp.Events.Add('OnChange');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TDateEdit';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Date');
  FMXComp.Properties.Add('ShowClearButton');
  FMXComp.Properties.Add('ShowToday');
  FMXComp.Events.Add('OnChange');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TCalendar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Date');
  FMXComp.Properties.Add('FirstDayOfWeek');
  FMXComp.Properties.Add('ShowToday');
  FMXComp.Events.Add('OnChange');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TTreeView';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnItemClick');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TListView';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Items');
  FMXComp.Properties.Add('ItemAppearance');
  FMXComp.Properties.Add('EditMode');
  FMXComp.Events.Add('OnChange');
  FMXComp.Events.Add('OnItemClick');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TWebBrowser';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('URL');
  FMXComp.Events.Add('OnDidFinishLoad');
  FMXComp.Events.Add('OnDidStartLoad');
  FMXComp.Events.Add('OnDidFailLoad');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TShape';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Shapes';
  FMXComp.Properties.Add('Fill');
  FMXComp.Properties.Add('Fill.Color');
  FMXComp.Properties.Add('Stroke');
  FMXComp.Properties.Add('Stroke.Color');
  FMXComp.Properties.Add('ShapeType');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TLine';
  FMXComp.ParentClass := 'TShape';
  FMXComp.Category := 'Shapes';
  FMXComp.Properties.Add('LineType');
  FMXComp.Properties.Add('Stroke');
  FMXComp.Properties.Add('Stroke.Color');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TScrollBar';
  FMXComp.ParentClass := 'TControl';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Value');
  FMXComp.Properties.Add('Min');
  FMXComp.Properties.Add('Max');
  FMXComp.Properties.Add('Orientation');
  FMXComp.Events.Add('OnChange');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TSpeedButton';
  FMXComp.ParentClass := 'TButton';
  FMXComp.Category := 'Standard';
  FMXComp.Properties.Add('Images');
  FMXComp.Properties.Add('ImageIndex');
  FMXComp.Properties.Add('GroupName');
  FMXComp.Properties.Add('Down');
  FMXComp.Properties.Add('TextSettings');
  FMXComp.Properties.Add('WordWrap');
  FFMXComponents.Add(FMXComp);

  FMXComp := TFMXComponentInfo.Create;
  FMXComp.FMXClassName := 'TMediaPlayer';
  FMXComp.ParentClass := 'TFmxObject';
  FMXComp.Category := 'Media';
  FMXComp.Properties.Add('FileName');
  FMXComp.Properties.Add('Duration');
  FMXComp.Properties.Add('CurrentTime');
  FMXComp.Properties.Add('Volume');
  FMXComp.Properties.Add('State');
  FFMXComponents.Add(FMXComp);
end;

procedure TComponentMapper.BuildRTTIInventories;
var
  RttiType: TRttiType;
  Mapping: TComponentMapping;
  FMXComp: TFMXComponentInfo;
begin
  FVCLInventories.Clear;
  FFMXInventories.Clear;

  for RttiType in FRTTIContext.GetTypes do
  begin
    if not (RttiType is TRttiInstanceType) then
      Continue;

    if RttiType.QualifiedName.StartsWith('Vcl.') then
      RegisterInventoryType(FVCLInventories, RttiType)
    else if RttiType.QualifiedName.StartsWith('FMX.') then
      RegisterInventoryType(FFMXInventories, RttiType);
  end;

  for Mapping in FMappingDatabase do
  begin
    RttiType := ResolveVclRttiType(Mapping.VCLClassName);
    if Assigned(RttiType) then
      RegisterInventoryType(FVCLInventories, RttiType);

    RttiType := ResolveFmxRttiType(Mapping.FMXClassName);
    if Assigned(RttiType) then
      RegisterInventoryType(FFMXInventories, RttiType);
  end;

  for FMXComp in FFMXComponents do
  begin
    RttiType := ResolveFmxRttiType(FMXComp.FMXClassName);
    if Assigned(RttiType) then
      RegisterInventoryType(FFMXInventories, RttiType);
  end;

  RttiType := ResolveVclRttiType('TForm');
  if Assigned(RttiType) then
    RegisterInventoryType(FVCLInventories, RttiType);

  RttiType := ResolveFmxRttiType('TForm');
  if Assigned(RttiType) then
    RegisterInventoryType(FFMXInventories, RttiType);
end;

procedure TComponentMapper.RegisterInventoryType(
  Inventory: TObjectDictionary<string, TRttiClassInventory>; RttiType: TRttiType);
var
  ClassInfo: TRttiClassInventory;
  Prop: TRttiProperty;
  PropTypeName: string;
begin
  if (RttiType = nil) or (RttiType.Name = '') or not RttiType.Name.StartsWith('T') then
    Exit;

  if not Inventory.TryGetValue(RttiType.Name, ClassInfo) then
  begin
    ClassInfo := TRttiClassInventory.Create;
    ClassInfo.RttiClassName := RttiType.Name;
    ClassInfo.QualifiedName := RttiType.QualifiedName;
    if Assigned(RttiType.BaseType) then
      ClassInfo.ParentClass := RttiType.BaseType.Name;
    Inventory.Add(RttiType.Name, ClassInfo);
  end;

  for Prop in RttiType.GetProperties do
  begin
    if Prop.Visibility <> mvPublished then
      Continue;

    if Assigned(Prop.PropertyType) then
      PropTypeName := Prop.PropertyType.Name
    else
      PropTypeName := '';

    if Assigned(Prop.PropertyType) and (Prop.PropertyType.TypeKind = tkMethod) then
      ClassInfo.Events.AddOrSetValue(Prop.Name, BuildEventSignature(Prop.PropertyType))
    else
      ClassInfo.Properties.AddOrSetValue(Prop.Name, PropTypeName);
  end;
end;

function TComponentMapper.BuildEventSignature(const RttiType: TRttiType): string;
var
  Invokable: TRttiInvokableType;
  Params: TArray<TRttiParameter>;
  Param: TRttiParameter;
  Parts: TStringList;
  ParamTypeName: string;
begin
  Result := '';
  if not (RttiType is TRttiInvokableType) then
    Exit;

  Invokable := TRttiInvokableType(RttiType);
  Parts := TStringList.Create;
  try
    Params := Invokable.GetParameters;
    for Param in Params do
    begin
      if Assigned(Param.ParamType) then
        ParamTypeName := Param.ParamType.Name
      else
        ParamTypeName := '';

      Parts.Add(Format('%s:%s', [
        Param.Name,
        ParamTypeName
      ]));
    end;

    Result := Format('%d|%s', [Ord(Invokable.CallingConvention), Parts.DelimitedText]);
    if Assigned(Invokable.ReturnType) then
      Result := Result + '->' + Invokable.ReturnType.Name;
  finally
    Parts.Free;
  end;
end;

function TComponentMapper.FindInventory(const ClassName: string;
  Inventory: TObjectDictionary<string, TRttiClassInventory>): TRttiClassInventory;
var
  NormalizedClassName: string;
  InventoryKey: string;
begin
  Result := nil;
  if (ClassName = '') or (Inventory = nil) then
    Exit;

  NormalizedClassName := NormalizeClassName(ClassName);
  if NormalizedClassName = '' then
    Exit;

  if Inventory.TryGetValue(NormalizedClassName, Result) then
    Exit;

  for InventoryKey in Inventory.Keys do
    if SameText(InventoryKey, NormalizedClassName) then
      Exit(Inventory.Items[InventoryKey]);
end;

procedure TComponentMapper.EnrichFMXCatalogFromInventory;
var
  Pair: TPair<string, TRttiClassInventory>;
  FMXComp: TFMXComponentInfo;
  PropName: string;
  EventName: string;
  Existing: TFMXComponentInfo;
  Found: Boolean;
begin
  for Pair in FFMXInventories do
  begin
    if (Pair.Value = nil) or
       ((Pair.Value.Properties.Count = 0) and (Pair.Value.Events.Count = 0)) then
      Continue;

    Found := False;
    for Existing in FFMXComponents do
      if SameText(Existing.FMXClassName, Pair.Key) then
      begin
        for PropName in Pair.Value.Properties.Keys do
          if not Existing.Properties.Contains(PropName) then
            Existing.Properties.Add(PropName);
        for EventName in Pair.Value.Events.Keys do
          if not Existing.Events.Contains(EventName) then
            Existing.Events.Add(EventName);
        Found := True;
        Break;
      end;

    if Found then
      Continue;

    FMXComp := TFMXComponentInfo.Create;
    FMXComp.FMXClassName := Pair.Value.RttiClassName;
    FMXComp.ParentClass := Pair.Value.ParentClass;
    FMXComp.Category := 'RTTI';
    for PropName in Pair.Value.Properties.Keys do
      FMXComp.Properties.Add(PropName);
    for EventName in Pair.Value.Events.Keys do
      FMXComp.Events.Add(EventName);
    FFMXComponents.Add(FMXComp);
  end;
end;

procedure TComponentMapper.NormalizeFMXCatalogAgainstInventory;
var
  FMXComp: TFMXComponentInfo;
  Inventory: TRttiClassInventory;
  I: Integer;
  PropName: string;
  function InventorySupportsEvent(const SourceInventory: TRttiClassInventory;
    const EventName: string): Boolean;
  var
    CurrentInventory: TRttiClassInventory;
    ParentClassName: string;
  begin
    Result := False;
    CurrentInventory := SourceInventory;
    while Assigned(CurrentInventory) do
    begin
      if CurrentInventory.Events.ContainsKey(EventName) then
        Exit(True);

      ParentClassName := CurrentInventory.ParentClass;
      if ParentClassName = '' then
        Break;

      CurrentInventory := FindInventory(ParentClassName, FFMXInventories);
    end;
  end;

  function InventorySupportsProperty(const SourceInventory: TRttiClassInventory;
    const PropertyName: string): Boolean;
  var
    CurrentInventory: TRttiClassInventory;
    ParentClassName: string;
    LocalBasePropName: string;
  begin
    Result := False;
    CurrentInventory := SourceInventory;
    LocalBasePropName := PropertyName;
    if LocalBasePropName.Contains('.') then
      LocalBasePropName := LocalBasePropName.Split(['.'])[0];

    while Assigned(CurrentInventory) do
    begin
      if CurrentInventory.Properties.ContainsKey(PropertyName) or
         CurrentInventory.Properties.ContainsKey(LocalBasePropName) then
        Exit(True);

      ParentClassName := CurrentInventory.ParentClass;
      if ParentClassName = '' then
        Break;

      CurrentInventory := FindInventory(ParentClassName, FFMXInventories);
    end;
  end;
begin
  for FMXComp in FFMXComponents do
  begin
    Inventory := FindInventory(FMXComp.FMXClassName, FFMXInventories);
    if not Assigned(Inventory) then
      Continue;

    for I := FMXComp.Events.Count - 1 downto 0 do
      if not InventorySupportsEvent(Inventory, FMXComp.Events[I]) then
        FMXComp.Events.Delete(I);

    for I := FMXComp.Properties.Count - 1 downto 0 do
    begin
      PropName := FMXComp.Properties[I];
      if not InventorySupportsProperty(Inventory, PropName) then
        FMXComp.Properties.Delete(I);
    end;
  end;
end;

function TComponentMapper.ResolveVclRttiType(const TypeName: string): TRttiType;
const
  PREFIXES: array[0..4] of string = (
    '',
    'Vcl.Forms.',
    'Vcl.Controls.',
    'Vcl.StdCtrls.',
    'Vcl.ExtCtrls.'
  );
var
  Prefix: string;
begin
  Result := nil;
  if TypeName = '' then
    Exit;

  if TypeName.Contains('.') then
    Exit(FRTTIContext.FindType(TypeName));

  for Prefix in PREFIXES do
  begin
    Result := FRTTIContext.FindType(Prefix + TypeName);
    if Assigned(Result) and Result.QualifiedName.StartsWith('Vcl.') then
      Exit;
    Result := nil;
  end;
end;

function TComponentMapper.ResolveFmxRttiType(const TypeName: string): TRttiType;
const
  PREFIXES: array[0..23] of string = (
    '',
    'FMX.Forms.',
    'FMX.Controls.',
    'FMX.StdCtrls.',
    'FMX.Edit.',
    'FMX.ComboEdit.',
    'FMX.ListBox.',
    'FMX.Memo.',
    'FMX.Layouts.',
    'FMX.Objects.',
    'FMX.ExtCtrls.',
    'FMX.ScrollBox.',
    'FMX.TabControl.',
    'FMX.Grid.',
    'FMX.Menus.',
    'FMX.Dialogs.',
    'FMX.ActnList.',
    'FMX.TreeView.',
    'FMX.DateTimeCtrls.',
    'FMX.Colors.',
    'FMX.SpinBox.',
    'FMX.NumberBox.',
    'FMX.Calendar.',
    'FMX.Media.'
  );
var
  Prefix: string;
begin
  Result := nil;
  if TypeName = '' then
    Exit;

  if TypeName.Contains('.') then
    Exit(FRTTIContext.FindType(TypeName));

  for Prefix in PREFIXES do
  begin
    Result := FRTTIContext.FindType(Prefix + TypeName);
    if Assigned(Result) and Result.QualifiedName.StartsWith('FMX.') then
      Exit;
    Result := nil;
  end;
end;

function TComponentMapper.KnowsFMXClass(const FMXClassName: string): Boolean;
var
  FMXComp: TFMXComponentInfo;
begin
  Result := False;
  if FMXClassName = '' then
    Exit;

  if Assigned(FindInventory(FMXClassName, FFMXInventories)) then
    Exit(True);

  if Assigned(ResolveFmxRttiType(FMXClassName)) then
    Exit(True);

  for FMXComp in FFMXComponents do
    if SameText(FMXComp.FMXClassName, FMXClassName) then
      Exit(True);
end;

function TComponentMapper.KnowsVCLClass(const VCLClassName: string): Boolean;
begin
  Result := False;
  if VCLClassName = '' then
    Exit;

  if Assigned(FindInventory(VCLClassName, FVCLInventories)) then
    Exit(True);

  Result := Assigned(ResolveVclRttiType(VCLClassName));
end;

function TComponentMapper.GetVCLInventory(
  const VCLClassName: string): TRttiClassInventory;
var
  RttiType: TRttiType;
begin
  Result := FindInventory(VCLClassName, FVCLInventories);
  if Assigned(Result) then
    Exit;

  RttiType := ResolveVclRttiType(VCLClassName);
  if Assigned(RttiType) then
  begin
    RegisterInventoryType(FVCLInventories, RttiType);
    Result := FindInventory(VCLClassName, FVCLInventories);
  end;
end;

function TComponentMapper.GetFMXInventory(
  const FMXClassName: string): TRttiClassInventory;
var
  RttiType: TRttiType;
begin
  Result := FindInventory(FMXClassName, FFMXInventories);
  if Assigned(Result) then
    Exit;

  RttiType := ResolveFmxRttiType(FMXClassName);
  if Assigned(RttiType) then
  begin
    RegisterInventoryType(FFMXInventories, RttiType);
    Result := FindInventory(FMXClassName, FFMXInventories);
  end;
end;

function TComponentMapper.SupportsFMXProperty(const FMXClassName,
  PropName: string): Boolean;
var
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  BasePropName: string;
  FMXComp: TFMXComponentInfo;
  Inventory: TRttiClassInventory;
  ParentInventory: TRttiClassInventory;
  ParentClassName: string;
  ParentType: TRttiType;
  ParentComp: TFMXComponentInfo;
begin
  Result := False;
  if (FMXClassName = '') or (PropName = '') then
    Exit;

  BasePropName := PropName;
  if BasePropName.Contains('.') then
    BasePropName := BasePropName.Split(['.'])[0];

  Inventory := GetFMXInventory(FMXClassName);
  if Assigned(Inventory) then
  begin
    if Inventory.Properties.ContainsKey(BasePropName) or
       Inventory.Properties.ContainsKey(PropName) then
      Exit(True);

    ParentClassName := Inventory.ParentClass;
    while ParentClassName <> '' do
    begin
      ParentInventory := FindInventory(ParentClassName, FFMXInventories);
      if not Assigned(ParentInventory) then
        Break;
      if ParentInventory.Properties.ContainsKey(BasePropName) or
         ParentInventory.Properties.ContainsKey(PropName) then
        Exit(True);
      ParentClassName := ParentInventory.ParentClass;
    end;
  end;

  RttiType := ResolveFmxRttiType(FMXClassName);
  if Assigned(RttiType) then
  begin
    ParentType := RttiType;
    while Assigned(ParentType) do
    begin
      RttiProp := ParentType.GetProperty(BasePropName);
      if Assigned(RttiProp) then
        Exit(True);
      RttiProp := ParentType.GetProperty(PropName);
      if Assigned(RttiProp) then
        Exit(True);
      ParentType := ParentType.BaseType;
    end;
  end;

  for FMXComp in FFMXComponents do
    if SameText(FMXComp.FMXClassName, FMXClassName) then
    begin
      if FMXComp.Properties.Contains(BasePropName) or
         FMXComp.Properties.Contains(PropName) then
        Exit(True);

      ParentClassName := FMXComp.ParentClass;
      while ParentClassName <> '' do
      begin
        ParentComp := nil;
        for ParentComp in FFMXComponents do
          if SameText(ParentComp.FMXClassName, ParentClassName) then
            Break;

        if (ParentComp = nil) or not SameText(ParentComp.FMXClassName, ParentClassName) then
          Break;

        if ParentComp.Properties.Contains(BasePropName) or
           ParentComp.Properties.Contains(PropName) then
          Exit(True);

        ParentClassName := ParentComp.ParentClass;
      end;

      Break;
    end;
end;

function TComponentMapper.SupportsFMXEvent(const FMXClassName,
  EventName: string): Boolean;
var
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  FMXComp: TFMXComponentInfo;
  Inventory: TRttiClassInventory;
  ParentInventory: TRttiClassInventory;
  ParentClassName: string;
  ParentType: TRttiType;
  ParentComp: TFMXComponentInfo;
begin
  Result := False;
  if (FMXClassName = '') or (EventName = '') then
    Exit;

  Inventory := GetFMXInventory(FMXClassName);
  if Assigned(Inventory) then
  begin
    if Inventory.Events.ContainsKey(EventName) then
      Exit(True);

    ParentClassName := Inventory.ParentClass;
    while ParentClassName <> '' do
    begin
      ParentInventory := FindInventory(ParentClassName, FFMXInventories);
      if not Assigned(ParentInventory) then
        Break;
      if ParentInventory.Events.ContainsKey(EventName) then
        Exit(True);
      ParentClassName := ParentInventory.ParentClass;
    end;
  end;

  RttiType := ResolveFmxRttiType(FMXClassName);
  if Assigned(RttiType) then
  begin
    ParentType := RttiType;
    while Assigned(ParentType) do
    begin
      RttiProp := ParentType.GetProperty(EventName);
      if Assigned(RttiProp) and Assigned(RttiProp.PropertyType) and
         (RttiProp.PropertyType.TypeKind = tkMethod) then
        Exit(True);
      ParentType := ParentType.BaseType;
    end;
  end;

  for FMXComp in FFMXComponents do
    if SameText(FMXComp.FMXClassName, FMXClassName) then
    begin
      if FMXComp.Events.Contains(EventName) then
        Exit(True);

      ParentClassName := FMXComp.ParentClass;
      while ParentClassName <> '' do
      begin
        ParentComp := nil;
        for ParentComp in FFMXComponents do
          if SameText(ParentComp.FMXClassName, ParentClassName) then
            Break;

        if (ParentComp = nil) or not SameText(ParentComp.FMXClassName, ParentClassName) then
          Break;

        if ParentComp.Events.Contains(EventName) then
          Exit(True);

        ParentClassName := ParentComp.ParentClass;
      end;

      Break;
    end;
end;

function TComponentMapper.AreEventSignaturesCompatible(const VCLClassName,
  VCLEvent, FMXClassName, FMXEvent: string): Boolean;
var
  VCLInfo: TRttiClassInventory;
  FMXInfo: TRttiClassInventory;
  VCLSignature: string;
  FMXSignature: string;
begin
  Result := True;
  if (VCLClassName = '') or (VCLEvent = '') or (FMXClassName = '') or (FMXEvent = '') then
    Exit;

  VCLInfo := GetVCLInventory(VCLClassName);
  FMXInfo := GetFMXInventory(FMXClassName);

  if not Assigned(VCLInfo) or not Assigned(FMXInfo) then
    Exit(True);

  if not VCLInfo.Events.TryGetValue(VCLEvent, VCLSignature) then
    Exit(True);
  if not FMXInfo.Events.TryGetValue(FMXEvent, FMXSignature) then
    Exit(True);

  Result := SameText(VCLSignature, FMXSignature);
end;

function TComponentMapper.TryFindExplicitPropertyMapping(
  const Mapping: TComponentMapping; const PropName: string;
  out PropMap: TPropertyMapping): Boolean;
var
  Candidate: TPropertyMapping;
begin
  Result := False;
  PropMap.VCLProp := '';
  PropMap.FMXProp := '';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';

  if not Assigned(Mapping) then
    Exit;

  for Candidate in Mapping.PropertyMaps do
    if (Trim(Candidate.VCLProp) <> '') and
       (SameText(Candidate.VCLProp, PropName) or
        PropName.StartsWith(Candidate.VCLProp + '.')) then
    begin
      PropMap := Candidate;
      Exit(True);
    end;
end;

function TComponentMapper.TryFindExplicitEventMapping(
  const Mapping: TComponentMapping; const EventName: string;
  out EventMap: TEventMapping): Boolean;
var
  Candidate: TEventMapping;
begin
  Result := False;
  EventMap.VCLEvent := '';
  EventMap.FMXEvent := '';
  EventMap.SignatureMatch := False;

  if not Assigned(Mapping) then
    Exit;

  for Candidate in Mapping.EventMaps do
    if (Trim(Candidate.VCLEvent) <> '') and
       SameText(Candidate.VCLEvent, EventName) then
    begin
      EventMap := Candidate;
      Exit(True);
    end;
end;

procedure TComponentMapper.PopulateDiscoverableVCLComponentClasses(
  AClasses: TStrings);
var
  Mapping: TComponentMapping;
  ClassName: string;
begin
  if AClasses = nil then
    Exit;

  for Mapping in FMappingDatabase do
    AddUniqueString(AClasses, Mapping.VCLClassName);

  for ClassName in FVCLInventories.Keys do
    AddUniqueString(AClasses, ClassName);
end;

procedure TComponentMapper.PopulateDiscoverablePropertyNames(
  const VCLClassName: string; APropertyNames: TStrings);
var
  Mapping: TComponentMapping;
  VCLInventory: TRttiClassInventory;
  PropName: string;
  PropMap: TPropertyMapping;
begin
  if (APropertyNames = nil) or (Trim(VCLClassName) = '') then
    Exit;

  VCLInventory := GetVCLInventory(VCLClassName);
  if Assigned(VCLInventory) then
    for PropName in VCLInventory.Properties.Keys do
      AddUniqueString(APropertyNames, PropName);

  Mapping := FindBestMatch(VCLClassName);
  if not Assigned(Mapping) then
    Exit;

  for PropMap in Mapping.PropertyMaps do
    AddUniqueString(APropertyNames, PropMap.VCLProp);
end;

procedure TComponentMapper.PopulateDiscoverableEventNames(
  const VCLClassName: string; AEventNames: TStrings);
var
  Mapping: TComponentMapping;
  VCLInventory: TRttiClassInventory;
  EventName: string;
  EventMap: TEventMapping;
begin
  if (AEventNames = nil) or (Trim(VCLClassName) = '') then
    Exit;

  VCLInventory := GetVCLInventory(VCLClassName);
  if Assigned(VCLInventory) then
    for EventName in VCLInventory.Events.Keys do
      AddUniqueString(AEventNames, EventName);

  Mapping := FindBestMatch(VCLClassName);
  if not Assigned(Mapping) then
    Exit;

  for EventMap in Mapping.EventMaps do
    AddUniqueString(AEventNames, EventMap.VCLEvent);
end;

function TComponentMapper.ResolvePropertyMapping(const VCLClassName,
  PropName: string; out PropMap: TPropertyMapping): Boolean;
var
  Mapping: TComponentMapping;
begin
  Result := False;
  PropMap.VCLProp := '';
  PropMap.FMXProp := '';
  PropMap.NeedsTransformation := False;
  PropMap.TransformerFunc := '';

  if (Trim(VCLClassName) = '') or (Trim(PropName) = '') then
    Exit;

  Mapping := FindBestMatch(VCLClassName);
  if not Assigned(Mapping) then
    Exit;

  if TryFindExplicitPropertyMapping(Mapping, PropName, PropMap) then
    Exit(Trim(PropMap.FMXProp) <> '');

  if Trim(Mapping.FMXClassName) = '' then
    Exit;

  PropMap.VCLProp := PropName;

  if SupportsFMXProperty(Mapping.FMXClassName, PropName) then
  begin
    PropMap.FMXProp := PropName;
    Exit(True);
  end;

  if SameText(PropName, 'Caption') and
     SupportsFMXProperty(Mapping.FMXClassName, 'Text') then
  begin
    PropMap.FMXProp := 'Text';
    Exit(True);
  end;

  if SameText(PropName, 'Color') and
     SupportsFMXProperty(Mapping.FMXClassName, 'Color') then
  begin
    PropMap.FMXProp := 'Color';
    PropMap.NeedsTransformation := True;
    PropMap.TransformerFunc := 'TransformColor';
    Exit(True);
  end;

  if SameText(PropName, 'Color') and
     SupportsFMXProperty(Mapping.FMXClassName, 'Fill.Color') then
  begin
    PropMap.FMXProp := 'Fill.Color';
    PropMap.NeedsTransformation := True;
    PropMap.TransformerFunc := 'TransformColor';
    Exit(True);
  end;
end;

function TComponentMapper.ResolveEventMapping(const VCLClassName,
  EventName: string; out EventMap: TEventMapping): Boolean;
var
  Mapping: TComponentMapping;
begin
  Result := False;
  EventMap.VCLEvent := '';
  EventMap.FMXEvent := '';
  EventMap.SignatureMatch := False;

  if (Trim(VCLClassName) = '') or (Trim(EventName) = '') then
    Exit;

  Mapping := FindBestMatch(VCLClassName);
  if not Assigned(Mapping) then
    Exit;

  if TryFindExplicitEventMapping(Mapping, EventName, EventMap) then
    Exit(Trim(EventMap.FMXEvent) <> '');

  if Trim(Mapping.FMXClassName) = '' then
    Exit;

  if SupportsFMXEvent(Mapping.FMXClassName, EventName) then
  begin
    EventMap.VCLEvent := EventName;
    EventMap.FMXEvent := EventName;
    EventMap.SignatureMatch := AreEventSignaturesCompatible(
      VCLClassName, EventName, Mapping.FMXClassName, EventName);
    Exit(True);
  end;
end;

procedure TComponentMapper.LoadMappings(const MappingsFile: string = '');
var
  JSONFile: string;
  JSONStr: string;
  JSONValue: TJSONValue;
  JSONArray: TJSONArray;
  JSONObj: TJSONObject;
  Mapping: TComponentMapping;
  PropArray: TJSONArray;
  PropObj: TJSONObject;
  PropMap: TPropertyMapping;
  EventArray: TJSONArray;
  EventObj: TJSONObject;
  EventMap: TEventMapping;
  I, J: Integer;
begin
  if MappingsFile = '' then
    JSONFile := 'component_mappings.json'
  else
    JSONFile := MappingsFile;

  if not FileExists(JSONFile) then
  begin
    SaveMappings(JSONFile);
    Exit;
  end;

  try
    JSONStr := TFile.ReadAllText(JSONFile);
    JSONValue := TJSONObject.ParseJSONValue(JSONStr);

    if Assigned(JSONValue) and (JSONValue is TJSONArray) then
    begin
      JSONArray := JSONValue as TJSONArray;

      FMappingDatabase.Clear;

      for I := 0 to JSONArray.Count - 1 do
      begin
        if JSONArray.Items[I] is TJSONObject then
        begin
          JSONObj := JSONArray.Items[I] as TJSONObject;

          Mapping := TComponentMapping.Create;
          Mapping.VCLClassName := JSONObj.GetValue<string>('vcl_class', '');
          Mapping.FMXClassName := JSONObj.GetValue<string>('fmx_class', '');
          Mapping.MappingType := JSONObj.GetValue<string>('mapping_type', 'Direct');
          Mapping.Confidence := JSONObj.GetValue<Integer>('confidence', 50);
          Mapping.Notes := JSONObj.GetValue<string>('notes', '');

          // Load property mappings
          if JSONObj.TryGetValue<TJSONArray>('property_maps', PropArray) then
          begin
            for J := 0 to PropArray.Count - 1 do
            begin
              if PropArray.Items[J] is TJSONObject then
              begin
                PropObj := PropArray.Items[J] as TJSONObject;
                PropMap.VCLProp := PropObj.GetValue<string>('vcl_prop', '');
                PropMap.FMXProp := PropObj.GetValue<string>('fmx_prop', '');
                PropMap.NeedsTransformation := PropObj.GetValue<Boolean>('needs_transform', False);
                PropMap.TransformerFunc := PropObj.GetValue<string>('transformer', '');
                Mapping.PropertyMaps.Add(PropMap);
              end;
            end;
          end;

          // Load event mappings
          if JSONObj.TryGetValue<TJSONArray>('event_maps', EventArray) then
          begin
            for J := 0 to EventArray.Count - 1 do
            begin
              if EventArray.Items[J] is TJSONObject then
              begin
                EventObj := EventArray.Items[J] as TJSONObject;
                EventMap.VCLEvent := EventObj.GetValue<string>('vcl_event', '');
                EventMap.FMXEvent := EventObj.GetValue<string>('fmx_event', '');
                EventMap.SignatureMatch := EventObj.GetValue<Boolean>('signature_match', True);
                Mapping.EventMaps.Add(EventMap);
              end;
            end;
          end;

          FMappingDatabase.Add(Mapping);
        end;
      end;

      JSONValue.Free;
    end;

  except
    on E: Exception do
      FContext.AddIssue(csError, 'Failed to load mappings: ' + E.Message);
  end;

  RebuildMappingIndex;
  ExportReferenceArtifacts(ExtractFilePath(ExpandFileName(JSONFile)));
end;

procedure TComponentMapper.SaveMappings(const MappingsFile: string);
var
  JSONArray: TJSONArray;
  JSONObj: TJSONObject;
  Mapping: TComponentMapping;
  PropMap: TPropertyMapping;
  EventMap: TEventMapping;
  PropArray: TJSONArray;
  PropObj: TJSONObject;
  EventArray: TJSONArray;
  EventObj: TJSONObject;
  JSONStr: string;
begin
  JSONArray := TJSONArray.Create;

  try
    for Mapping in FMappingDatabase do
    begin
      JSONObj := TJSONObject.Create;
      JSONObj.AddPair('vcl_class', Mapping.VCLClassName);
      JSONObj.AddPair('fmx_class', Mapping.FMXClassName);
      JSONObj.AddPair('mapping_type', Mapping.MappingType);
      JSONObj.AddPair('confidence', TJSONNumber.Create(Mapping.Confidence));
      JSONObj.AddPair('notes', Mapping.Notes);

      // Save property mappings
      PropArray := TJSONArray.Create;
      for PropMap in Mapping.PropertyMaps do
      begin
        PropObj := TJSONObject.Create;
        PropObj.AddPair('vcl_prop', PropMap.VCLProp);
        PropObj.AddPair('fmx_prop', PropMap.FMXProp);
        PropObj.AddPair('needs_transform', TJSONBool.Create(PropMap.NeedsTransformation));
        PropObj.AddPair('transformer', PropMap.TransformerFunc);
        PropArray.Add(PropObj);
      end;
      JSONObj.AddPair('property_maps', PropArray);

      // Save event mappings
      EventArray := TJSONArray.Create;
      for EventMap in Mapping.EventMaps do
      begin
        EventObj := TJSONObject.Create;
        EventObj.AddPair('vcl_event', EventMap.VCLEvent);
        EventObj.AddPair('fmx_event', EventMap.FMXEvent);
        EventObj.AddPair('signature_match', TJSONBool.Create(EventMap.SignatureMatch));
        EventArray.Add(EventObj);
      end;
      JSONObj.AddPair('event_maps', EventArray);

      JSONArray.Add(JSONObj);
    end;

    JSONStr := JSONArray.Format(2);
    TFile.WriteAllText(MappingsFile, JSONStr, TEncoding.UTF8);
    ExportReferenceArtifacts(ExtractFilePath(ExpandFileName(MappingsFile)));

  finally
    JSONArray.Free;
  end;
end;

function TComponentMapper.FindMapping(const VCLClassName: string): TComponentMapping;
var
  LookupKey: string;
begin
  Result := nil;
  LookupKey := BuildClassLookupKey(VCLClassName);
  if LookupKey = '' then
    Exit;

  FMappingIndex.TryGetValue(LookupKey, Result);
end;

function TComponentMapper.IsPreservedCrossPlatformComponent(
  const VCLClassName: string): Boolean;
begin
  Result := SameText(VCLClassName, 'TDataSource') or
            VCLClassName.StartsWith('TFD') or
            VCLClassName.StartsWith('TId');
end;
function TComponentMapper.BuildPreservedComponentMapping(
  const VCLClassName: string): TComponentMapping;
begin
  Result := TComponentMapping.Create;
  Result.VCLClassName := VCLClassName;
  Result.FMXClassName := VCLClassName;
  Result.MappingType := 'Preserved';
  Result.Confidence := 85;

  if SameText(VCLClassName, 'TDataSource') then
    Result.Notes := 'Preserved as a shared data-access component that can remain in an FMX project'
  else if VCLClassName.StartsWith('TFD') then
    Result.Notes := 'Preserved as a FireDAC data-access component that can remain in an FMX project'
  else if VCLClassName.StartsWith('TId') then
    Result.Notes := 'Preserved as an Indy networking component that can remain in an FMX project'
  else
    Result.Notes := 'Preserved as a cross-platform component that can remain in an FMX project';
end;

function TComponentMapper.BuildBestMatch(const VCLClassName: string;
  const ReportIssues: Boolean): TComponentMapping;
var
  Research: TComponentResearch;
  NormalizedClassName: string;
begin
  Result := nil;
  NormalizedClassName := NormalizeClassName(VCLClassName);
  if NormalizedClassName = '' then
    Exit;

  if IsPreservedCrossPlatformComponent(NormalizedClassName) then
  begin
    if ReportIssues then
      FContext.AddIssue(csInfo,
        'Preserving cross-platform component as-is for FMX output: ' + NormalizedClassName);
    Exit(BuildPreservedComponentMapping(NormalizedClassName));
  end;

  if ReportIssues then
    FContext.AddIssue(csInfo, 'Researching component: ' + NormalizedClassName);

  Research := ResearchVCLComponent(VCLClassName, ReportIssues);
  try
    Result := FindFMXMatch(Research, ReportIssues);

    if Assigned(Result) then
    begin
      Result.VCLClassName := NormalizedClassName;
      if ReportIssues then
        FContext.AddIssue(csInfo, Format('Found match for %s: %s (confidence: %d%%)',
          [NormalizedClassName, Result.FMXClassName, Result.Confidence]));
    end
    else
    begin
      if ReportIssues then
        FContext.AddIssue(csInfo, 'No generic FMX match found for component: ' + NormalizedClassName);

      Result := TComponentMapping.Create;
      Result.VCLClassName := NormalizedClassName;
      Result.FMXClassName := '';
      Result.MappingType := 'Unmapped';
      Result.Confidence := 0;
      Result.Notes := 'No suitable FMX component found';
    end;
  finally
    Research.Free;
  end;
end;

function TComponentMapper.EnsureBestMatch(const VCLClassName: string): TComponentMapping;
var
  LookupKey: string;
begin
  Result := FindMapping(VCLClassName);
  if Assigned(Result) then
    Exit;

  LookupKey := BuildClassLookupKey(VCLClassName);
  if LookupKey = '' then
    Exit(nil);

  Result := BuildBestMatch(VCLClassName, True);
  if Assigned(Result) then
    RegisterResolvedMapping(LookupKey, Result);
end;

function TComponentMapper.FindBestMatch(const VCLClassName: string): TComponentMapping;
var
  LookupKey: string;
begin
  Result := FindMapping(VCLClassName);
  if Assigned(Result) then
    Exit;

  LookupKey := BuildClassLookupKey(VCLClassName);
  if LookupKey = '' then
    Exit(nil);

  if FDerivedMappingCache.TryGetValue(LookupKey, Result) then
    Exit;

  Result := BuildBestMatch(VCLClassName, False);
  if Assigned(Result) then
    FDerivedMappingCache.AddOrSetValue(LookupKey, Result);
end;

function TComponentMapper.ResearchVCLComponent(
  const VCLClassName: string; const ReportIssues: Boolean = True): TComponentResearch;
var
  RttiType: TRttiType;
  Method: TRttiMethod;
  Prop: TRttiProperty;
begin
  Result := TComponentResearch.Create;
  Result.VCLClassName := NormalizeClassName(VCLClassName);

  try
    RttiType := ResolveVclRttiType(VCLClassName);

    if Assigned(RttiType) then
    begin
      if Assigned(RttiType.BaseType) then
        Result.ParentClass := RttiType.BaseType.Name;

      for Prop in RttiType.GetProperties do
      begin
        if Prop.IsReadable then
          Result.Properties.Add(Prop.Name);
      end;

      for Method in RttiType.GetMethods do
      begin
        if Method.Visibility = mvPublished then
          Result.Methods.Add(Method.Name);
      end;

      for Prop in RttiType.GetProperties do
      begin
        if (Prop.PropertyType is TRttiMethodType) then
          Result.Events.Add(Prop.Name);
      end;
    end
    else
    begin
      if ReportIssues then
        FContext.AddIssue(csInfo, 'No RTTI for ' + NormalizeClassName(VCLClassName) +
          ', using heuristic analysis');

      if VCLClassName.Contains('Grid') then
        Result.ParentClass := 'TCustomGrid'
      else if VCLClassName.Contains('Edit') then
        Result.ParentClass := 'TCustomEdit'
      else if VCLClassName.Contains('Button') then
        Result.ParentClass := 'TButtonControl'
      else if VCLClassName.Contains('List') then
        Result.ParentClass := 'TCustomListBox'
      else if VCLClassName.Contains('Combo') then
        Result.ParentClass := 'TCustomComboBox';
    end;

  except
    on E: Exception do
      if ReportIssues then
        FContext.AddIssue(csWarning, 'Error researching component: ' + E.Message);
  end;
end;
function TComponentMapper.FindFMXMatch(
  const Research: TComponentResearch; const ReportIssues: Boolean = True): TComponentMapping;
var
  FMXComp: TFMXComponentInfo;
  BestMatch: TFMXComponentInfo;
  BestScore: Integer;
  Score: Integer;
  Mapping: TComponentMapping;
begin
  Result := nil;
  BestScore := 0;
  BestMatch := nil;

  for FMXComp in FFMXComponents do
  begin
    Score := CalculateMatchScore(Research, FMXComp);

    if Score > BestScore then
    begin
      BestScore := Score;
      BestMatch := FMXComp;
    end;
  end;

  if Assigned(BestMatch) and (BestScore > 50) then
  begin
    Mapping := TComponentMapping.Create;
    Mapping.VCLClassName := Research.VCLClassName;
    Mapping.FMXClassName := BestMatch.FMXClassName;
    Mapping.MappingType := 'Researched';
    Mapping.Confidence := BestScore;
    Mapping.Notes := Format('Auto-matched based on %d%% similarity', [BestScore]);

    ResearchPropertyMapping(Research.VCLClassName, BestMatch.FMXClassName, Mapping,
      ReportIssues);
    ResearchEventMappings(Research.VCLClassName, BestMatch.FMXClassName, Mapping);

    Result := Mapping;
  end;
end;

function TComponentMapper.CalculateMatchScore(const VCLResearch: TComponentResearch;
  const FMXComp: TFMXComponentInfo): Integer;
var
  TotalScore: Integer;
begin
  TotalScore := 0;

  TotalScore := TotalScore + AnalyzeInheritance(VCLResearch, FMXComp);
  TotalScore := TotalScore + AnalyzeProperties(VCLResearch, FMXComp);
  TotalScore := TotalScore + AnalyzeMethods(VCLResearch, FMXComp);
  TotalScore := TotalScore + AnalyzeEvents(VCLResearch, FMXComp);

  Result := TotalScore div 4;
end;

function TComponentMapper.AnalyzeInheritance(const VCLComp: TComponentResearch;
  const FMXComp: TFMXComponentInfo): Integer;
begin
  if VCLComp.ParentClass.Contains('Control') and
     FMXComp.ParentClass.Contains('Control') then
    Result := 80
  else if VCLComp.ParentClass.Contains('Component') and
          FMXComp.ParentClass.Contains('Component') then
    Result := 70
  else if VCLComp.ParentClass = FMXComp.ParentClass then
    Result := 100
  else
    Result := 40;
end;

function TComponentMapper.AnalyzeProperties(const VCLComp: TComponentResearch;
  const FMXComp: TFMXComponentInfo): Integer;
var
  MatchCount: Integer;
  TotalProps: Integer;
  VCLProp: string;
begin
  MatchCount := 0;
  TotalProps := VCLComp.Properties.Count;

  if TotalProps = 0 then
    Exit(50);

  for VCLProp in VCLComp.Properties do
  begin
    if FMXComp.Properties.Contains(VCLProp) then
      Inc(MatchCount)
    else if (VCLProp = 'Caption') and FMXComp.Properties.Contains('Text') then
      Inc(MatchCount)
    else if (VCLProp = 'Color') and
            (FMXComp.Properties.Contains('Fill.Color') or
             FMXComp.Properties.Contains('Fill') or
             FMXComp.Properties.Contains('Color')) then
      Inc(MatchCount);
  end;

  Result := Round((MatchCount / TotalProps) * 100);
end;

function TComponentMapper.AnalyzeMethods(const VCLComp: TComponentResearch;
  const FMXComp: TFMXComponentInfo): Integer;
var
  MatchCount: Integer;
  TotalMethods: Integer;
  VCLMethod: string;
begin
  MatchCount := 0;
  TotalMethods := VCLComp.Methods.Count;

  if TotalMethods = 0 then
    Exit(50);

  for VCLMethod in VCLComp.Methods do
  begin
    if FMXComp.Methods.Contains(VCLMethod) then
      Inc(MatchCount);
  end;

  Result := Round((MatchCount / TotalMethods) * 100);
end;

function TComponentMapper.AnalyzeEvents(const VCLComp: TComponentResearch;
  const FMXComp: TFMXComponentInfo): Integer;
var
  MatchCount: Integer;
  TotalEvents: Integer;
  VCLEvent: string;
begin
  MatchCount := 0;
  TotalEvents := VCLComp.Events.Count;

  if TotalEvents = 0 then
    Exit(50);

  for VCLEvent in VCLComp.Events do
  begin
    if FMXComp.Events.Contains(VCLEvent) and
       AreEventSignaturesCompatible(VCLComp.VCLClassName, VCLEvent,
         FMXComp.FMXClassName, VCLEvent) then
      Inc(MatchCount);
  end;

  Result := Round((MatchCount / TotalEvents) * 100);
end;

procedure TComponentMapper.ResearchPropertyMapping(const VCLComp, FMXComp: string;
  var Mapping: TComponentMapping; const ReportIssues: Boolean = True);
var
  VCLRttiType: TRttiType;
  FMXRttiType: TRttiType;
  VCLProp: TRttiProperty;
  FMXProp: TRttiProperty;
  PropMap: TPropertyMapping;
begin
  try
    VCLRttiType := ResolveVclRttiType(VCLComp);
    FMXRttiType := ResolveFmxRttiType(FMXComp);

    if Assigned(VCLRttiType) and Assigned(FMXRttiType) then
    begin
      for VCLProp in VCLRttiType.GetProperties do
      begin
        FMXProp := FMXRttiType.GetProperty(VCLProp.Name);

        if Assigned(FMXProp) then
        begin
          PropMap.VCLProp := VCLProp.Name;
          PropMap.FMXProp := VCLProp.Name;
          PropMap.NeedsTransformation := False;
          PropMap.TransformerFunc := '';
          Mapping.PropertyMaps.Add(PropMap);
        end
        else
        begin
          if VCLProp.Name = 'Caption' then
          begin
            FMXProp := FMXRttiType.GetProperty('Text');
            if Assigned(FMXProp) then
            begin
              PropMap.VCLProp := 'Caption';
              PropMap.FMXProp := 'Text';
              PropMap.NeedsTransformation := False;
              PropMap.TransformerFunc := '';
              Mapping.PropertyMaps.Add(PropMap);
            end;
          end
          else if VCLProp.Name = 'Color' then
          begin
            if Assigned(FMXRttiType.GetProperty('Color')) then
            begin
              PropMap.VCLProp := 'Color';
              PropMap.FMXProp := 'Color';
              PropMap.NeedsTransformation := True;
              PropMap.TransformerFunc := 'TransformColor';
              Mapping.PropertyMaps.Add(PropMap);
            end
            else if Assigned(FMXRttiType.GetProperty('Fill')) then
            begin
              PropMap.VCLProp := 'Color';
              PropMap.FMXProp := 'Fill.Color';
              PropMap.NeedsTransformation := True;
              PropMap.TransformerFunc := 'TransformColor';
              Mapping.PropertyMaps.Add(PropMap);
            end;
          end;
        end;
      end;
    end;
  except
    on E: Exception do
      if ReportIssues then
        FContext.AddIssue(csInfo, 'Error researching property mappings: ' + E.Message);
  end;
end;

procedure TComponentMapper.ResearchEventMappings(const VCLComp, FMXComp: string;
  var Mapping: TComponentMapping);
var
  VCLInfo: TRttiClassInventory;
  FMXInfo: TRttiClassInventory;
  VCLEvent: string;
  EventMap: TEventMapping;
begin
  VCLInfo := GetVCLInventory(VCLComp);
  FMXInfo := GetFMXInventory(FMXComp);
  if not Assigned(VCLInfo) or not Assigned(FMXInfo) then
    Exit;

  for VCLEvent in VCLInfo.Events.Keys do
  begin
    if FMXInfo.Events.ContainsKey(VCLEvent) then
    begin
      EventMap.VCLEvent := VCLEvent;
      EventMap.FMXEvent := VCLEvent;
      EventMap.SignatureMatch := AreEventSignaturesCompatible(
        VCLComp, VCLEvent, FMXComp, VCLEvent);
      Mapping.EventMaps.Add(EventMap);
    end;
  end;
end;

procedure TComponentMapper.AddUserMapping(const Mapping: TComponentMapping);
var
  I: Integer;
begin
  for I := FMappingDatabase.Count - 1 downto 0 do
  begin
    if SameText(BuildClassLookupKey(FMappingDatabase[I].VCLClassName),
                BuildClassLookupKey(Mapping.VCLClassName)) then
    begin
      FMappingDatabase.Delete(I);
      Break;
    end;
  end;

  FMappingDatabase.Add(Mapping);
  RebuildMappingIndex;

  if FContext.Options.UserMappingsFile <> '' then
    SaveMappings(FContext.Options.UserMappingsFile);
end;

end.


