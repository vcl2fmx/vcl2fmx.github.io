{VCL2FMX (c) 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Rewrite.LiveBindings;

interface

uses
  System.SysUtils,
  System.Classes,
  System.RegularExpressions,
  System.StrUtils,
  System.Generics.Collections,
  Converter.Core.Types,
  Converter.Parser.DFM,
  Converter.Advanced.DataAware;

type
  TLiveBindingCodeProc = procedure(var Code: string) of object;

  TLiveBindingInjector = class
  private
    FContext: TConversionContext;
    FDfmParser: TDFMParser;
    FDataAware: TLiveBindingConverter;
    FGridDblClickHandlers: TDictionary<string, string>;
    FNormalizeRuntimeColors: TLiveBindingCodeProc;
    function SanitizeIdentifier(const S: string): string;
    procedure NormalizeRuntimeColors(var Code: string);
    procedure AppendCalcFieldMethodImplementations(const FormClassName: string;
      CalcFieldAssignments: TObjectDictionary<string, TStringList>;
      CalcMethodNames: TDictionary<string, string>;
      MethodImplementationLines: TStringList);
    procedure AppendComboDataChangeMethodImplementations(const FormClassName: string;
      ComboDataChangeSyncMap: TObjectDictionary<string, TStringList>;
      ComboDataChangeHandlerNames, ComboOriginalDataChangeHandlers: TDictionary<string, string>;
      MethodImplementationLines: TStringList);
    procedure AppendNavigatorMethodImplementations(const FormClassName: string;
      ManualFieldNavigatorHandlerNames, NavigatorOriginalBeforeActionFields: TDictionary<string, string>;
      ManualFieldNavigatorCommitMap, ManualFieldNavigatorSyncMap: TObjectDictionary<string, TStringList>;
      MethodImplementationLines: TStringList);
    procedure AppendAfterOpenMethodImplementations(const FormClassName: string;
      AfterOpenLinkMap: TObjectDictionary<string, TStringList>;
      AfterOpenHandlerNames, OriginalAfterOpenHandlerFields: TDictionary<string, string>;
      MethodImplementationLines: TStringList);
  public
    constructor Create(AContext: TConversionContext; ADfmParser: TDFMParser;
      ADataAware: TLiveBindingConverter; AGridDblClickHandlers: TDictionary<string, string>;
      ANormalizeRuntimeColors: TLiveBindingCodeProc);
    procedure WarnIfMultipleFormDeclarations(const FileName, Code: string);
    procedure Inject(var Code: string);
  end;

implementation

constructor TLiveBindingInjector.Create(AContext: TConversionContext;
  ADfmParser: TDFMParser; ADataAware: TLiveBindingConverter;
  AGridDblClickHandlers: TDictionary<string, string>;
  ANormalizeRuntimeColors: TLiveBindingCodeProc);
begin
  inherited Create;
  FContext := AContext;
  FDfmParser := ADfmParser;
  FDataAware := ADataAware;
  FGridDblClickHandlers := AGridDblClickHandlers;
  FNormalizeRuntimeColors := ANormalizeRuntimeColors;
end;

procedure TLiveBindingInjector.NormalizeRuntimeColors(var Code: string);
begin
  if Assigned(FNormalizeRuntimeColors) then
    FNormalizeRuntimeColors(Code);
end;

function TLiveBindingInjector.SanitizeIdentifier(const S: string): string;
begin
  Result := TRegEx.Replace(S, '[^A-Za-z0-9_]', '_');
  if Result = '' then
    Result := 'Generated';
end;

procedure TLiveBindingInjector.AppendCalcFieldMethodImplementations(
  const FormClassName: string;
  CalcFieldAssignments: TObjectDictionary<string, TStringList>;
  CalcMethodNames: TDictionary<string, string>;
  MethodImplementationLines: TStringList);
var
  Pair: TPair<string, TStringList>;
  CalcMethodName: string;
  ImplLine: string;
begin
  if not Assigned(CalcFieldAssignments) or not Assigned(CalcMethodNames) or
     not Assigned(MethodImplementationLines) then
    Exit;

  for Pair in CalcFieldAssignments do
  begin
    if not CalcMethodNames.TryGetValue(Pair.Key, CalcMethodName) then
      Continue;

    MethodImplementationLines.Add('');
    MethodImplementationLines.Add('procedure ' + FormClassName + '.' +
      CalcMethodName + '(DataSet: TDataSet);');
    MethodImplementationLines.Add('begin');
    MethodImplementationLines.Add('  if Assigned(FOriginal_' +
      SanitizeIdentifier(Pair.Key) + '_OnCalcFields) then');
    MethodImplementationLines.Add('    FOriginal_' + SanitizeIdentifier(Pair.Key) +
      '_OnCalcFields(DataSet);');
    if Pair.Value.Count = 0 then
      MethodImplementationLines.Add('  // No generated display fields needed.')
    else
      for ImplLine in Pair.Value do
        MethodImplementationLines.Add(ImplLine);
    MethodImplementationLines.Add('end;');
  end;
end;

procedure TLiveBindingInjector.AppendComboDataChangeMethodImplementations(
  const FormClassName: string;
  ComboDataChangeSyncMap: TObjectDictionary<string, TStringList>;
  ComboDataChangeHandlerNames, ComboOriginalDataChangeHandlers: TDictionary<string, string>;
  MethodImplementationLines: TStringList);
var
  DataChangePair: TPair<string, TStringList>;
  HandlerName: string;
  OriginalDataChangeHandler: string;
  SyncCall: string;
begin
  if not Assigned(ComboDataChangeSyncMap) or
     not Assigned(ComboDataChangeHandlerNames) or
     not Assigned(ComboOriginalDataChangeHandlers) or
     not Assigned(MethodImplementationLines) then
    Exit;

  for DataChangePair in ComboDataChangeSyncMap do
  begin
    if not ComboDataChangeHandlerNames.TryGetValue(DataChangePair.Key, HandlerName) then
      Continue;

    MethodImplementationLines.Add('');
    MethodImplementationLines.Add('procedure ' + FormClassName + '.' + HandlerName +
      '(Sender: TObject; Field: TField);');
    MethodImplementationLines.Add('begin');
    if ComboOriginalDataChangeHandlers.TryGetValue(DataChangePair.Key,
         OriginalDataChangeHandler) and (Trim(OriginalDataChangeHandler) <> '') then
      MethodImplementationLines.Add('  ' + OriginalDataChangeHandler + '(Sender, Field);');
    MethodImplementationLines.Add('  if (Sender is TDataSource) and Assigned(TDataSource(Sender).DataSet) and');
    MethodImplementationLines.Add('     (TDataSource(Sender).DataSet.State in dsEditModes) then');
    MethodImplementationLines.Add('    Exit;');
    for SyncCall in DataChangePair.Value do
      MethodImplementationLines.Add('  ' + SyncCall + ';');
    MethodImplementationLines.Add('end;');
  end;
end;

procedure TLiveBindingInjector.AppendNavigatorMethodImplementations(
  const FormClassName: string;
  ManualFieldNavigatorHandlerNames, NavigatorOriginalBeforeActionFields: TDictionary<string, string>;
  ManualFieldNavigatorCommitMap, ManualFieldNavigatorSyncMap: TObjectDictionary<string, TStringList>;
  MethodImplementationLines: TStringList);
var
  NavigatorPair: TPair<string, string>;
  OriginalBeforeActionField: string;
  SyncCall: string;
begin
  if not Assigned(ManualFieldNavigatorHandlerNames) or
     not Assigned(NavigatorOriginalBeforeActionFields) or
     not Assigned(ManualFieldNavigatorCommitMap) or
     not Assigned(ManualFieldNavigatorSyncMap) or
     not Assigned(MethodImplementationLines) then
    Exit;

  for NavigatorPair in ManualFieldNavigatorHandlerNames do
  begin
    OriginalBeforeActionField := '';
    NavigatorOriginalBeforeActionFields.TryGetValue(NavigatorPair.Key,
      OriginalBeforeActionField);
    MethodImplementationLines.Add('');
    MethodImplementationLines.Add('procedure ' + FormClassName + '.' +
      NavigatorPair.Value + '(Sender: TObject; Button: TBindNavigateBtn);');
    MethodImplementationLines.Add('begin');
    MethodImplementationLines.Add('  case Button of');
    MethodImplementationLines.Add('    nbFirst, nbPrior, nbNext, nbLast, nbPost, nbInsert, nbRefresh:');
    MethodImplementationLines.Add('    begin');
    if ManualFieldNavigatorCommitMap.ContainsKey(NavigatorPair.Key) then
      for SyncCall in ManualFieldNavigatorCommitMap[NavigatorPair.Key] do
        MethodImplementationLines.Add('      ' + SyncCall + ';');
    MethodImplementationLines.Add('    end;');
    MethodImplementationLines.Add('    nbCancel:');
    MethodImplementationLines.Add('    begin');
    if ManualFieldNavigatorSyncMap.ContainsKey(NavigatorPair.Key) then
      for SyncCall in ManualFieldNavigatorSyncMap[NavigatorPair.Key] do
        MethodImplementationLines.Add('      ' + SyncCall + ';');
    MethodImplementationLines.Add('    end;');
    MethodImplementationLines.Add('  end;');
    if OriginalBeforeActionField <> '' then
    begin
      MethodImplementationLines.Add('  if Assigned(' + OriginalBeforeActionField + ') then');
      MethodImplementationLines.Add('    ' + OriginalBeforeActionField + '(Sender, Button);');
    end;
    MethodImplementationLines.Add('end;');
  end;
end;

procedure TLiveBindingInjector.AppendAfterOpenMethodImplementations(
  const FormClassName: string;
  AfterOpenLinkMap: TObjectDictionary<string, TStringList>;
  AfterOpenHandlerNames, OriginalAfterOpenHandlerFields: TDictionary<string, string>;
  MethodImplementationLines: TStringList);
var
  AfterOpenPair: TPair<string, TStringList>;
  HandlerName: string;
  OriginalAfterOpenHandlerField: string;
  LinkName: string;
begin
  if not Assigned(AfterOpenLinkMap) or not Assigned(AfterOpenHandlerNames) or
     not Assigned(OriginalAfterOpenHandlerFields) or
     not Assigned(MethodImplementationLines) then
    Exit;

  for AfterOpenPair in AfterOpenLinkMap do
  begin
    if not AfterOpenHandlerNames.TryGetValue(AfterOpenPair.Key, HandlerName) then
      Continue;

    OriginalAfterOpenHandlerField := '';
    OriginalAfterOpenHandlerFields.TryGetValue(AfterOpenPair.Key,
      OriginalAfterOpenHandlerField);

    MethodImplementationLines.Add('');
    MethodImplementationLines.Add('procedure ' + FormClassName + '.' + HandlerName +
      '(DataSet: TDataSet);');
    MethodImplementationLines.Add('begin');
    if OriginalAfterOpenHandlerField <> '' then
    begin
      MethodImplementationLines.Add('  if Assigned(' + OriginalAfterOpenHandlerField + ') then');
      MethodImplementationLines.Add('    ' + OriginalAfterOpenHandlerField + '(DataSet);');
    end;
    for LinkName in AfterOpenPair.Value do
    begin
      MethodImplementationLines.Add('  if ' + LinkName + ' <> nil then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    ' + LinkName + '.Active := False;');
      MethodImplementationLines.Add('    ' + LinkName + '.Active := True;');
      MethodImplementationLines.Add('    if ' + LinkName + '.GridControl is TControl then');
      MethodImplementationLines.Add('      TControl(' + LinkName + '.GridControl).Repaint;');
      MethodImplementationLines.Add('  end;');
    end;
    MethodImplementationLines.Add('end;');
  end;
end;

procedure TLiveBindingInjector.WarnIfMultipleFormDeclarations(const FileName,
  Code: string);
var
  Matches: TMatchCollection;
  AnalysisCode: string;
begin
  AnalysisCode := VCL2FMXStripCommentsForAnalysis(Code);
  Matches := TRegEx.Matches(AnalysisCode,
    '=\s*class\s*\(\s*T(?:Form|Frame|DataModule)\b',
    [roIgnoreCase]);

  if Matches.Count > 1 then
    FContext.AddIssue(csWarning,
      Format('Multiple form/frame/datamodule declarations found in %s; generated LiveBindings may need manual review.',
        [ExtractFileName(FileName)]),
      'Multi-form unit LiveBindings review',
      '',
      'Review generated LiveBindings in this unit. The converter is optimized for the common one form/frame/datamodule per unit layout.',
      -1,
      False);
end;
procedure TLiveBindingInjector.Inject(var Code: string);
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  DeclarationLines: TStringList;
  MethodDeclarationLines: TStringList;
  EarlySetupLines: TStringList;
  SetupLines: TStringList;
  CleanupLines: TStringList;
  MethodImplementationLines: TStringList;
  BindSources: TDictionary<string, string>;
  GeneratedLinks: TDictionary<string, Boolean>;
  GeneratedDisplayFields: TDictionary<string, Boolean>;
  CalcMethodNames: TDictionary<string, string>;
  CalcFieldAssignments: TObjectDictionary<string, TStringList>;
  AfterOpenHandlerNames: TDictionary<string, string>;
  OriginalAfterOpenHandlerFields: TDictionary<string, string>;
  AfterOpenLinkMap: TObjectDictionary<string, TStringList>;
  ComboDataChangeHandlerNames: TDictionary<string, string>;
  ComboOriginalDataChangeHandlers: TDictionary<string, string>;
  ComboDataChangeSyncMap: TObjectDictionary<string, TStringList>;
  ManualFieldNavigatorHandlerNames: TDictionary<string, string>;
  NavigatorOriginalBeforeActionFields: TDictionary<string, string>;
  ManualFieldNavigatorCommitMap: TObjectDictionary<string, TStringList>;
  ManualFieldNavigatorSyncMap: TObjectDictionary<string, TStringList>;
  ToggleClickHandlerNames: TDictionary<string, string>;
  ToggleChangeHandlerNames: TDictionary<string, string>;
  EnterHandlerNames: TDictionary<string, string>;
  TimerSourceOnTimerHandlers: TDictionary<string, string>;
  TimerComponentNames: TStringList;
  TimerHandlerNames: TStringList;
  MediaNotifyPlayers: TStringList;
  MediaNotifyHandlerPlayers: TStringList;
  MediaNotifyEnabledPlayers: TStringList;
  MediaNotifyMatches: TMatchCollection;
  MediaNotifyMatch: TMatch;
  i, InsertIdx, ClassIdx, BeginIdx, EndIdx, Depth, SearchIdx, MethodInsertIdx: Integer;
  PrivateIdx, FirstVisibilityIdx, EndClassIdx, FinalInsertIdx: Integer;
  DestroyBeginIdx: Integer;
  DestroyEndIdx: Integer;
  Binding: TDataBindingInfo;
  BindSourceField: string;
  LinkField: string;
  FormClassName: string;
  TrimmedLine: string;
  CleanLine: string;
  HandlerName: string;
  GridAdapterName: string;
  OriginalHandlerName: string;
  OriginalAfterOpenHandlerField: string;
  ComboSyncMethodName: string;
  ComboChangeMethodName: string;
  ComboPopupMethodName: string;
  ComboClosePopupMethodName: string;
  ComboGuardField: string;
  ComboOriginalChangeField: string;
  ComboOriginalPopupField: string;
  ComboOriginalClosePopupField: string;
  ComboDataSetComponent: string;
  ComboOriginalDataChangeHandler: string;
  ComboSyncCall: string;
  NavigatorOriginalBeforeActionField: string;
  ToggleOriginalClickField: string;
  ToggleOriginalChangeField: string;
  ToggleSuppressField: string;
  ToggleSetStateMethodName: string;
  ToggleChangeMethodName: string;
  EnterOriginalField: string;
  EnterWrapperMethodName: string;
  PlayerName: string;
  SanitizedPlayerName: string;
  MediaNotifyHandlerField: string;
  MediaNotifyTimerField: string;
  MediaNotifyWasPlayingField: string;
  MediaNotifyRegisterMethod: string;
  MediaNotifyEnabledMethod: string;
  MediaNotifyTimerMethod: string;
  EarlyDestroyLines: TStringList;
  function SanitizeIdentifier(const S: string): string;
  begin
    Result := TRegEx.Replace(S, '[^A-Za-z0-9_]', '_');
    if Result = '' then
      Result := 'Generated';
  end;

  function UnquoteValue(const S: string): string;
  begin
    Result := Trim(S);
    if (Length(Result) >= 2) and (Result[1] = '''') and
       (Result[Length(Result)] = '''') then
      Result := Copy(Result, 2, Length(Result) - 2);
    Result := StringReplace(Result, '''''', '''', [rfReplaceAll]);
  end;

  function QuoteValue(const S: string): string;
  begin
    Result := QuotedStr(UnquoteValue(S));
  end;

  function TransformVclColorLiteral(const VCLColor: string): string;
  var
    ColorStr: string;
    RawValue: Cardinal;
    R, G, B: Cardinal;
    IntValue: Integer;
  begin
    ColorStr := Trim(VCLColor);

    if TryStrToInt(ColorStr, IntValue) then
    begin
      RawValue := Cardinal(IntValue);
      B := RawValue and $FF;
      G := (RawValue shr 8) and $FF;
      R := (RawValue shr 16) and $FF;
      Exit(Format('$FF%.2X%.2X%.2X', [R, G, B]));
    end;

    if ColorStr.StartsWith('$') then
    begin
      try
        RawValue := StrToInt(ColorStr);
        if RawValue <= $FFFFFF then
        begin
          B := RawValue and $FF;
          G := (RawValue shr 8) and $FF;
          R := (RawValue shr 16) and $FF;
          Exit(Format('$FF%.2X%.2X%.2X', [R, G, B]));
        end;
        Exit(Format('$%.8X', [RawValue]));
      except
        Exit(ColorStr);
      end;
    end;

    if SameText(ColorStr, 'clBlack') then
      Result := 'claBlack'
    else if SameText(ColorStr, 'clWhite') then
      Result := 'claWhite'
    else if SameText(ColorStr, 'clRed') then
      Result := 'claRed'
    else if SameText(ColorStr, 'clGreen') then
      Result := 'claGreen'
    else if SameText(ColorStr, 'clBlue') then
      Result := 'claBlue'
    else if SameText(ColorStr, 'clYellow') then
      Result := 'claYellow'
    else if SameText(ColorStr, 'clBtnFace') then
      Result := '$FFF0F0F0'
    else if SameText(ColorStr, 'clWindow') then
      Result := 'claWhite'
    else if SameText(ColorStr, 'clHighlight') then
      Result := '$FF0078D7'
    else if SameText(ColorStr, 'clIvory') then
      Result := 'claIvory'
    else if SameText(ColorStr, 'clCream') then
      Result := '$FFFFFBF0'
    else if SameText(ColorStr, 'clMaroon') then
      Result := 'claMaroon'
    else if SameText(ColorStr, 'clNavy') then
      Result := 'claNavy'
    else if SameText(ColorStr, 'clTeal') then
      Result := 'claTeal'
    else if SameText(ColorStr, 'clOlive') then
      Result := 'claOlive'
    else if SameText(ColorStr, 'clPurple') then
      Result := 'claPurple'
    else if SameText(ColorStr, 'clSilver') then
      Result := 'claSilver'
    else if SameText(ColorStr, 'clGray') then
      Result := 'claGray'
    else
      Result := ColorStr;
  end;

  function DataSourceHasStandaloneEditors(const ADataSource: string): Boolean;
  var
    Candidate: TDataBindingInfo;
  begin
    Result := False;
    if Trim(ADataSource) = '' then
      Exit;

    for Candidate in FDataAware.DataBindings do
    begin
      if not Assigned(Candidate) then
        Continue;
      if not SameText(Candidate.DataSource, ADataSource) then
        Continue;
      if SameText(Candidate.DataLinkType, 'Grid') or
         SameText(Candidate.DataLinkType, 'Navigator') then
        Continue;
      if Trim(Candidate.DataField) = '' then
        Continue;
      Exit(True);
    end;
  end;

  function GridUsesSelectorEditors(const ABinding: TDataBindingInfo): Boolean;
  var
    OptionsValue: string;
  begin
    Result := False;
    if not Assigned(ABinding) then
      Exit;
    if not SameText(ABinding.DataLinkType, 'Grid') then
      Exit;
    if not ABinding.OriginalProperties.TryGetValue('Options', OptionsValue) then
      Exit;

    Result := ContainsText(OptionsValue, 'dgEditing') and
      not DataSourceHasStandaloneEditors(ABinding.DataSource);
  end;

  function GridUsesStandaloneEditorBrowseMode(const ABinding: TDataBindingInfo): Boolean;
  begin
    Result := Assigned(ABinding) and
      SameText(ABinding.DataLinkType, 'Grid') and
      DataSourceHasStandaloneEditors(ABinding.DataSource);
  end;

  procedure EmitStyledBackgroundSetup;
  var
    AddedComponents: TDictionary<string, Boolean>;

    function SourceComponentClass(const AComponent: TDFMComponent): string;
    begin
      Result := '';
      if AComponent = nil then
        Exit;
      Result := Trim(AComponent.ComponentClass);
      if Result = '' then
        Result := Trim(AComponent.ObjectClass);
    end;

    procedure VisitComponents(const Items: TObjectList<TDFMComponent>);
    var
      Comp: TDFMComponent;
      SourceClass: string;
      ColorValue: string;
    begin
      if Items = nil then
        Exit;

      for Comp in Items do
      begin
        if Comp = nil then
          Continue;

        SourceClass := SourceComponentClass(Comp);
        if (Comp.Name <> '') and
           (not AddedComponents.ContainsKey(Comp.Name)) and
           Comp.Properties.ContainsKey('Color') and
           (SameText(SourceClass, 'TPanel') or
            SameText(SourceClass, 'TGroupBox') or
            SameText(SourceClass, 'TStatusBar') or
            SameText(SourceClass, 'TToolBar')) then
        begin
          ColorValue := Trim(Comp.GetPropertyValue('Color', ''));
          if ColorValue <> '' then
          begin
            AddedComponents.Add(Comp.Name, True);
            SetupLines.Add('  if Assigned(' + Comp.Name + ') then');
            SetupLines.Add('    ApplyStyledBackgroundColor(' + Comp.Name +
              ', ' + TransformVclColorLiteral(ColorValue) + ', False);');
            SetupLines.Add('');
          end;
        end;

        VisitComponents(Comp.Children);
        VisitComponents(Comp.CollectionItems);
      end;
    end;
  begin
    if not Assigned(FDfmParser) or (FDfmParser.Components.Count = 0) then
      Exit;

    AddedComponents := TDictionary<string, Boolean>.Create;
    try
      VisitComponents(FDfmParser.Components);
    finally
      AddedComponents.Free;
    end;
  end;

  procedure PrepareSelectorGridDisplayFields(const ABinding: TDataBindingInfo);
  var
    ColumnCount: Integer;
    I: Integer;
    DisplayCount: Integer;
    CountValue: string;
    FieldName: string;
    NormalizedFieldName: string;
    DisplayFieldName: string;
    AddedFields: TDictionary<string, string>;
  begin
    if not Assigned(ABinding) then
      Exit;
    if not GridUsesSelectorEditors(ABinding) then
      Exit;

    if not ABinding.OriginalProperties.TryGetValue('GridColumnCount', CountValue) then
      CountValue := '0';
    ColumnCount := StrToIntDef(CountValue, 0);
    if ColumnCount <= 0 then
      Exit;

    AddedFields := TDictionary<string, string>.Create;
    try
      DisplayCount := 0;
      for I := 0 to ColumnCount - 1 do
      begin
        if not ABinding.OriginalProperties.TryGetValue(
             Format('GridColumn%d.FieldName', [I]), FieldName) then
          Continue;

        NormalizedFieldName := UnquoteValue(FieldName);
        if Trim(NormalizedFieldName) = '' then
          Continue;

        if not AddedFields.TryGetValue(NormalizedFieldName, DisplayFieldName) then
        begin
          DisplayFieldName := NormalizedFieldName + '_display';
          AddedFields.Add(NormalizedFieldName, DisplayFieldName);
          ABinding.OriginalProperties.AddOrSetValue(
            Format('GridDisplayField%d.SourceFieldName', [DisplayCount]),
            NormalizedFieldName);
          ABinding.OriginalProperties.AddOrSetValue(
            Format('GridDisplayField%d.DisplayFieldName', [DisplayCount]),
            DisplayFieldName);
          ABinding.OriginalProperties.AddOrSetValue(
            Format('GridDisplayField%d.DisplayFieldClass', [DisplayCount]),
            'TWideStringField');
          Inc(DisplayCount);
        end;

        ABinding.OriginalProperties.AddOrSetValue(
          Format('GridColumn%d.DisplayFieldName', [I]),
          QuotedStr(DisplayFieldName));
      end;

      if DisplayCount > 0 then
        ABinding.OriginalProperties.AddOrSetValue('GridDisplayFieldCount',
          IntToStr(DisplayCount));
    finally
      AddedFields.Free;
    end;
  end;

  function CountKeyword(const S, Keyword: string): Integer;
  begin
    Result := TRegEx.Matches(S, '\b' + Keyword + '\b', [roIgnoreCase]).Count;
  end;

  function StartsMethodDeclaration(const S: string): Boolean;
  var
    Trimmed: string;
  begin
    Trimmed := TrimLeft(S);
    Result := StartsText('procedure ', Trimmed) or
              StartsText('function ', Trimmed) or
              StartsText('constructor ', Trimmed) or
              StartsText('destructor ', Trimmed);
  end;

  function ExtractFormClassName: string;
  var
    Match: TMatch;
  begin
    Result := '';
    if (ClassIdx >= 0) and (ClassIdx < Lines.Count) then
    begin
      Match := TRegEx.Match(Trim(Lines[ClassIdx]),
        '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*class\b', [roIgnoreCase]);
      if Match.Success then
        Result := Match.Groups[1].Value;
    end;
  end;

  function HasMediaNotifyCandidates: Boolean;
  begin
    Result :=
      TRegEx.IsMatch(Code,
        '^\s*(?://\s*FMX manual review:\s*)?\w*MediaPlayer\w*\.OnNotify\s*:=',
        [roIgnoreCase, roMultiLine]) or
      TRegEx.IsMatch(Code,
        '^\s*(?://\s*FMX manual review:\s*)?\w*MediaPlayer\w*\.Notify\s*:=',
        [roIgnoreCase, roMultiLine]);
  end;

  function ShouldEmulateMediaNotify(const APlayerName: string): Boolean;
  begin
    Result := (Trim(APlayerName) <> '') and
      (MediaNotifyHandlerPlayers.IndexOf(APlayerName) >= 0) and
      (MediaNotifyEnabledPlayers.IndexOf(APlayerName) >= 0);
  end;

  function HandlerContainsStartupSensitiveToggleLogic(const AHandlerName: string): Boolean;
  var
    Match: TMatch;
    MethodText: string;
  begin
    Result := False;
    if Trim(AHandlerName) = '' then
      Exit;

    Match := TRegEx.Match(Code,
      '(?is)(?:procedure|function)\s+[A-Za-z_][A-Za-z0-9_\.]*\.' +
      TRegEx.Escape(AHandlerName) +
      '\s*\([^)]*\)\s*;(?<Body>.*?)(?=^\s*(?:procedure|function|constructor|destructor)\b|\Z)',
      [roIgnoreCase, roMultiLine]);
    if not Match.Success then
      Exit;

    MethodText := Match.Value;
    Result :=
      TRegEx.IsMatch(MethodText, '\.(?:IsChecked|Checked)\s*:=', [roIgnoreCase]) or
      ContainsText(MethodText, 'GeneratedSetToggleState_');
  end;

  function HasToggleClickCandidates: Boolean;
    procedure VisitComponents(const Items: TObjectList<TDFMComponent>; var AFound: Boolean);
    var
      Comp: TDFMComponent;
      ClickHandler: string;
      SourceClass: string;
    begin
      if AFound or (Items = nil) then
        Exit;
      for Comp in Items do
      begin
        if not Assigned(Comp) then
          Continue;
        SourceClass := Trim(Comp.ComponentClass);
        if (SameText(SourceClass, 'TCheckBox') or SameText(SourceClass, 'TRadioButton')) and
           Comp.Events.TryGetValue('OnClick', ClickHandler) and
           (Trim(ClickHandler) <> '') then
        begin
          AFound := True;
          Exit;
        end;
        VisitComponents(Comp.Children, AFound);
        if AFound then
          Exit;
        VisitComponents(Comp.CollectionItems, AFound);
        if AFound then
          Exit;
      end;
    end;
  begin
    Result := False;
    if Assigned(FDfmParser) then
      VisitComponents(FDfmParser.Components, Result);
  end;

  function HasStartupEnterCandidates: Boolean;
    procedure VisitComponents(const Items: TObjectList<TDFMComponent>; var AFound: Boolean);
    var
      Comp: TDFMComponent;
      EnterHandler: string;
    begin
      if AFound or (Items = nil) then
        Exit;
      for Comp in Items do
      begin
        if not Assigned(Comp) then
          Continue;
        if Assigned(FDfmParser) and (FDfmParser.Components.Count > 0) and
           (Comp = FDfmParser.Components[0]) then
        begin
          VisitComponents(Comp.Children, AFound);
          if AFound then
            Exit;
          VisitComponents(Comp.CollectionItems, AFound);
          if AFound then
            Exit;
          Continue;
        end;
        if Comp.Events.TryGetValue('OnEnter', EnterHandler) and
           HandlerContainsStartupSensitiveToggleLogic(EnterHandler) then
        begin
          AFound := True;
          Exit;
        end;
        VisitComponents(Comp.Children, AFound);
        if AFound then
          Exit;
        VisitComponents(Comp.CollectionItems, AFound);
        if AFound then
          Exit;
      end;
    end;
  begin
    Result := False;
    if Assigned(FDfmParser) then
      VisitComponents(FDfmParser.Components, Result);
  end;

  procedure CollectToggleClickCandidates;
    procedure VisitComponents(const Items: TObjectList<TDFMComponent>);
    var
      Comp: TDFMComponent;
      ClickHandler: string;
      ChangeHandler: string;
      SourceClass: string;
    begin
      if Items = nil then
        Exit;
      for Comp in Items do
      begin
        if not Assigned(Comp) then
          Continue;
        SourceClass := Trim(Comp.ComponentClass);
        if (SameText(SourceClass, 'TCheckBox') or SameText(SourceClass, 'TRadioButton')) and
           Comp.Events.TryGetValue('OnClick', ClickHandler) and
           (Trim(ClickHandler) <> '') then
        begin
          ToggleClickHandlerNames.AddOrSetValue(Comp.Name, ClickHandler);
          if Comp.Events.TryGetValue('OnChange', ChangeHandler) and (Trim(ChangeHandler) <> '') then
            ToggleChangeHandlerNames.AddOrSetValue(Comp.Name, ChangeHandler);
        end;
        VisitComponents(Comp.Children);
        VisitComponents(Comp.CollectionItems);
      end;
    end;
  begin
    if Assigned(FDfmParser) then
      VisitComponents(FDfmParser.Components);
  end;

  procedure CollectStartupEnterCandidates;
    procedure VisitComponents(const Items: TObjectList<TDFMComponent>);
    var
      Comp: TDFMComponent;
      EnterHandler: string;
    begin
      if Items = nil then
        Exit;
      for Comp in Items do
      begin
        if not Assigned(Comp) then
          Continue;
        if Assigned(FDfmParser) and (FDfmParser.Components.Count > 0) and
           (Comp = FDfmParser.Components[0]) then
        begin
          VisitComponents(Comp.Children);
          VisitComponents(Comp.CollectionItems);
          Continue;
        end;
        if Comp.Events.TryGetValue('OnEnter', EnterHandler) and
           HandlerContainsStartupSensitiveToggleLogic(EnterHandler) and
           (Trim(Comp.Name) <> '') then
          EnterHandlerNames.AddOrSetValue(Comp.Name, EnterHandler);
        VisitComponents(Comp.Children);
        VisitComponents(Comp.CollectionItems);
      end;
    end;
  begin
    if Assigned(FDfmParser) then
      VisitComponents(FDfmParser.Components);
  end;

  procedure CollectTimerComponentNames;
    procedure VisitComponents(const Items: TObjectList<TDFMComponent>);
    var
      Comp: TDFMComponent;
      SourceClass: string;
      TimerHandler: string;
    begin
      if Items = nil then
        Exit;
      for Comp in Items do
      begin
        if not Assigned(Comp) then
          Continue;
        SourceClass := Trim(Comp.ComponentClass);
        if SameText(SourceClass, 'TTimer') then
        begin
          if Trim(Comp.Name) <> '' then
            TimerComponentNames.Add(Comp.Name);
          if Comp.Events.TryGetValue('OnTimer', TimerHandler) and
             (Trim(TimerHandler) <> '') then
          begin
            TimerHandlerNames.Add(TimerHandler);
            if Trim(Comp.Name) <> '' then
              TimerSourceOnTimerHandlers.AddOrSetValue(Comp.Name, TimerHandler);
          end;
        end;
        VisitComponents(Comp.Children);
        VisitComponents(Comp.CollectionItems);
      end;
    end;
  begin
    if Assigned(FDfmParser) then
      VisitComponents(FDfmParser.Components);
  end;

  procedure EnsureGeneratedShutdownGuard;
  const
    HelperKey = 'GeneratedShutdownGuard';
  begin
    if GeneratedLinks.ContainsKey(HelperKey) then
      Exit;

    GeneratedLinks.Add(HelperKey, True);
    DeclarationLines.Add('    FGeneratedShuttingDown: Boolean;');
    CleanupLines.Insert(0, '  FGeneratedShuttingDown := True;');
  end;

  function LeadingWhitespace(const S: string): string;
  var
    K: Integer;
  begin
    Result := '';
    for K := 1 to Length(S) do
    begin
      if not CharInSet(S[K], [#9, ' ']) then
        Break;
      Result := Result + S[K];
    end;
  end;

  function FindMethodBeginLine(const MethodName: string; out MethodIdx,
    BeginLineIdx: Integer): Boolean;
  var
    SearchIdx: Integer;
  begin
    Result := False;
    MethodIdx := -1;
    BeginLineIdx := -1;
    if Trim(MethodName) = '' then
      Exit;

    for SearchIdx := 0 to Lines.Count - 1 do
      if TRegEx.IsMatch(Lines[SearchIdx],
           '^\s*procedure\s+[A-Za-z0-9_\.]+\.' + TRegEx.Escape(MethodName) + '\s*\(',
           [roIgnoreCase]) or
         TRegEx.IsMatch(Lines[SearchIdx],
           '^\s*function\s+[A-Za-z0-9_\.]+\.' + TRegEx.Escape(MethodName) + '\s*\(',
           [roIgnoreCase]) then
      begin
        MethodIdx := SearchIdx;
        Break;
      end;

    if MethodIdx = -1 then
      Exit;

    for SearchIdx := MethodIdx to Lines.Count - 1 do
      if SameText(Trim(Lines[SearchIdx]), 'begin') then
      begin
        BeginLineIdx := SearchIdx;
        Result := True;
        Exit;
      end;
  end;

  procedure InsertShutdownGuardIntoMethod(const MethodName: string);
  var
    MethodIdx: Integer;
    BeginLineIdx: Integer;
    SearchIdx: Integer;
    BeginLine: string;
    Indent: string;
    K: Integer;
  begin
    if Trim(MethodName) = '' then
      Exit;

    MethodIdx := -1;
    for SearchIdx := 0 to Lines.Count - 1 do
      if TRegEx.IsMatch(Lines[SearchIdx],
           '^\s*procedure\s+[A-Za-z0-9_\.]+\.' + TRegEx.Escape(MethodName) + '\s*\(',
           [roIgnoreCase]) or
         TRegEx.IsMatch(Lines[SearchIdx],
           '^\s*function\s+[A-Za-z0-9_\.]+\.' + TRegEx.Escape(MethodName) + '\s*\(',
           [roIgnoreCase]) then
      begin
        MethodIdx := SearchIdx;
        Break;
      end;

    if MethodIdx = -1 then
      Exit;

    BeginLineIdx := -1;
    for SearchIdx := MethodIdx to Lines.Count - 1 do
      if SameText(Trim(Lines[SearchIdx]), 'begin') then
      begin
        BeginLineIdx := SearchIdx;
        Break;
      end;

    if BeginLineIdx = -1 then
      Exit;
    if (BeginLineIdx + 1 < Lines.Count) and ContainsText(Lines[BeginLineIdx + 1],
         'FGeneratedShuttingDown') then
      Exit;

    BeginLine := Lines[BeginLineIdx];
    Indent := '';
    for K := 1 to Length(BeginLine) do
    begin
      if not CharInSet(BeginLine[K], [#9, ' ']) then
        Break;
      Indent := Indent + BeginLine[K];
    end;

    Lines.Insert(BeginLineIdx + 1, Indent + '  if FGeneratedShuttingDown then');
    Lines.Insert(BeginLineIdx + 2, Indent + '    Exit;');
  end;

  procedure RewriteDeferredToggleCallsInFormShow;
  var
    MethodIdx: Integer;
    BeginLineIdx: Integer;
    EndLineIdx: Integer;
    DepthCounter: Integer;
    LineIdx: Integer;
    TogglePair: TPair<string, string>;
    SetStateMethodName: string;
    CurrentLine: string;
    NextLine: string;
    Indent: string;

    function LeadingWhitespace(const S: string): string;
    var
      K: Integer;
    begin
      K := 1;
      while (K <= Length(S)) and CharInSet(S[K], [#9, ' ']) do
        Inc(K);
      Result := Copy(S, 1, K - 1);
    end;

    function IsFormShowDeclaration(const S: string): Boolean;
    begin
      Result := TRegEx.IsMatch(S,
        '^\s*procedure\s+[A-Za-z0-9_\.]+\.FormShow\s*\(',
        [roIgnoreCase]);
    end;
  begin
    MethodIdx := 0;
    while MethodIdx < Lines.Count do
    begin
      if not IsFormShowDeclaration(Lines[MethodIdx]) then
      begin
        Inc(MethodIdx);
        Continue;
      end;

      BeginLineIdx := -1;
      EndLineIdx := -1;
      DepthCounter := 0;

      for LineIdx := MethodIdx + 1 to Lines.Count - 1 do
      begin
        if BeginLineIdx = -1 then
        begin
          if SameText(Trim(Lines[LineIdx]), 'begin') then
          begin
            BeginLineIdx := LineIdx;
            DepthCounter := 1;
          end;
          Continue;
        end;

        Inc(DepthCounter, CountKeyword(Lines[LineIdx], 'begin'));
        Dec(DepthCounter, CountKeyword(Lines[LineIdx], 'end'));
        if DepthCounter = 0 then
        begin
          EndLineIdx := LineIdx;
          Break;
        end;
      end;

      if (BeginLineIdx = -1) or (EndLineIdx = -1) then
      begin
        Inc(MethodIdx);
        Continue;
      end;

      for LineIdx := BeginLineIdx + 1 to EndLineIdx - 1 do
      begin
        CurrentLine := Lines[LineIdx];
        for TogglePair in ToggleClickHandlerNames do
        begin
          SetStateMethodName := 'GeneratedSetToggleState_' + SanitizeIdentifier(TogglePair.Key);
          if not TRegEx.IsMatch(CurrentLine,
               '^\s*' + TRegEx.Escape(SetStateMethodName) + '\s*\(.+\)\s*;\s*$',
               [roIgnoreCase]) then
            Continue;

          if LineIdx + 1 >= EndLineIdx then
            Continue;

          NextLine := Lines[LineIdx + 1];
          if not TRegEx.IsMatch(NextLine,
               '^\s*' + TRegEx.Escape(TogglePair.Value) + '\s*\(\s*Self\s*\)\s*;\s*$',
               [roIgnoreCase]) then
            Continue;

          Indent := LeadingWhitespace(NextLine);
          Lines[LineIdx + 1] := Indent + 'if not (csDestroying in ComponentState) then';
          Lines.Insert(LineIdx + 2, Indent + '  ' + TogglePair.Value + '(Self);');
          Inc(EndLineIdx, 1);
          Break;
        end;
      end;

      MethodIdx := EndLineIdx + 1;
    end;
  end;

  procedure AddBindSource(const ADataSourceName: string);
  begin
    if (ADataSourceName = '') or BindSources.ContainsKey(ADataSourceName) then
      Exit;

    BindSourceField := 'BindSourceDB_' + SanitizeIdentifier(ADataSourceName);
    BindSources.Add(ADataSourceName, BindSourceField);
    DeclarationLines.Add('    ' + BindSourceField + ': TBindSourceDB;');

    SetupLines.Add('  if ' + BindSourceField + ' = nil then');
    SetupLines.Add('  begin');
    SetupLines.Add('    ' + BindSourceField + ' := TBindSourceDB.Create(Self);');
    SetupLines.Add('    ' + BindSourceField + '.DataSource := ' + ADataSourceName + ';');
    SetupLines.Add('  end;');
    SetupLines.Add('');

  end;

  procedure RegisterGridAfterOpenHandler(const ABinding: TDataBindingInfo;
    const ALinkField: string);
  var
    DataSetComponent: string;
    LinkList: TStringList;
    OriginalAfterOpenField: string;
  begin
    if not Assigned(ABinding) then
      Exit;
    if not ABinding.OriginalProperties.TryGetValue('DataSetComponent', DataSetComponent) then
      Exit;
    if Trim(DataSetComponent) = '' then
      Exit;

    if not AfterOpenHandlerNames.TryGetValue(DataSetComponent, HandlerName) then
    begin
      HandlerName := SanitizeIdentifier(DataSetComponent) + '_GeneratedAfterOpen';
      AfterOpenHandlerNames.Add(DataSetComponent, HandlerName);
      OriginalAfterOpenField := 'FOriginal_' + SanitizeIdentifier(DataSetComponent) + '_AfterOpen';
      OriginalAfterOpenHandlerFields.AddOrSetValue(DataSetComponent, OriginalAfterOpenField);
      DeclarationLines.Add('    ' + OriginalAfterOpenField + ': TDataSetNotifyEvent;');
      MethodDeclarationLines.Add('    procedure ' + HandlerName + '(DataSet: TDataSet);');

      LinkList := TStringList.Create;
      LinkList.CaseSensitive := False;
      LinkList.Sorted := True;
      LinkList.Duplicates := dupIgnore;
      AfterOpenLinkMap.Add(DataSetComponent, LinkList);

      EarlySetupLines.Add('  if Assigned(' + DataSetComponent + ') then');
      EarlySetupLines.Add('  begin');
      EarlySetupLines.Add('    ' + OriginalAfterOpenField + ' := ' + DataSetComponent + '.AfterOpen;');
      EarlySetupLines.Add('    ' + DataSetComponent + '.AfterOpen := ' + HandlerName + ';');
      EarlySetupLines.Add('  end;');
      EarlySetupLines.Add('');
      CleanupLines.Add('  if Assigned(' + DataSetComponent + ') and (' + DataSetComponent + '.Owner <> Self) then');
      CleanupLines.Add('    ' + DataSetComponent + '.AfterOpen := ' + OriginalAfterOpenField + ';');
    end;

    LinkList := AfterOpenLinkMap[DataSetComponent];
    if LinkList.IndexOf(ALinkField) = -1 then
      LinkList.Add(ALinkField);
  end;

  procedure AddLinkControlField(const ALinkField, ABindSourceField, AComponentName,
    AFieldName: string);
  var
    NormalizedFieldName: string;
  begin
    if GeneratedLinks.ContainsKey(ALinkField) then
      Exit;

    NormalizedFieldName := UnquoteValue(AFieldName);
    GeneratedLinks.Add(ALinkField, True);
    DeclarationLines.Add('    ' + ALinkField + ': TLinkControlToField;');
    SetupLines.Add('  if ' + ALinkField + ' = nil then');
    SetupLines.Add('  begin');
    SetupLines.Add('    ' + ALinkField + ' := TLinkControlToField.Create(Self);');
    SetupLines.Add('    ' + ALinkField + '.DataSource := ' + ABindSourceField + ';');
    SetupLines.Add('    ' + ALinkField + '.FieldName := ''' + NormalizedFieldName + ''';');
    SetupLines.Add('    ' + ALinkField + '.Control := ' + AComponentName + ';');
    SetupLines.Add('    ' + ALinkField + '.AutoActivate := True;');
    SetupLines.Add('  end;');
    SetupLines.Add('');

  end;

  procedure EnsureGeneratedBoundFieldHelpers;
  const
    HelperKey = 'GeneratedBoundFieldHelpers';
  var
    TimerName: string;
    TimerSourceHandlerName: string;
    TimerOriginalOnTimerField: string;
  begin
    if GeneratedLinks.ContainsKey(HelperKey) then
      Exit;

    GeneratedLinks.Add(HelperKey, True);
    EnsureGeneratedShutdownGuard;
    for TimerName in TimerComponentNames do
    begin
      TimerSourceHandlerName := '';
      TimerOriginalOnTimerField := '';
      if not TimerSourceOnTimerHandlers.TryGetValue(TimerName, TimerSourceHandlerName) then
      begin
        TimerOriginalOnTimerField := 'FGeneratedOriginalOnTimer_' +
          SanitizeIdentifier(TimerName);
        DeclarationLines.Add('    ' + TimerOriginalOnTimerField + ': TNotifyEvent;');
        SetupLines.Add('  if Assigned(' + TimerName + ') and (' + TimerName + '.Owner <> Self) then');
        SetupLines.Add('    ' + TimerOriginalOnTimerField + ' := ' + TimerName + '.OnTimer;');
      end;
      CleanupLines.Add('  if Assigned(' + TimerName + ') then');
      CleanupLines.Add('  begin');
      CleanupLines.Add('    ' + TimerName + '.Enabled := False;');
      if TimerOriginalOnTimerField <> '' then
      begin
        CleanupLines.Add('    if ' + TimerName + '.Owner <> Self then');
        CleanupLines.Add('      ' + TimerName + '.OnTimer := ' + TimerOriginalOnTimerField);
        CleanupLines.Add('    else');
        CleanupLines.Add('      ' + TimerName + '.OnTimer := nil;');
      end
      else
        CleanupLines.Add('    ' + TimerName + '.OnTimer := nil;');
      CleanupLines.Add('  end;');
    end;
    CleanupLines.Add('  GeneratedCleanupManualFieldBindingsForOwner(Self);');
  end;

  procedure AddManualFieldBinding(const ABinding: TDataBindingInfo);
  var
    BindingKey: string;
    DataSetComponent: string;
    DataSourceComponent: string;
    DataSourceHandlerName: string;
    DataSourceHandlerNameValue: string;
    SyncMethods: TStringList;
    NormalizedFieldName: string;
    NavigatorComponentName: string;
    NavigatorBeforeActionMethodName: string;
    NavigatorOriginalBeforeActionField: string;
    NavBinding: TDataBindingInfo;
    CommitList: TStringList;
    SyncList: TStringList;
    SyncCall: string;
    CommitCall: string;
  begin
    if not Assigned(ABinding) then
      Exit;
    if (ABinding.ComponentName = '') or (ABinding.DataSource = '') or
       (ABinding.DataField = '') then
      Exit;
    if not ABinding.OriginalProperties.TryGetValue('DataSetComponent', DataSetComponent) then
      Exit;
    if Trim(DataSetComponent) = '' then
      Exit;

    DataSourceComponent := ABinding.DataSource;
    NormalizedFieldName := UnquoteValue(ABinding.DataField);
    BindingKey := 'ManualField_' + SanitizeIdentifier(ABinding.ComponentName);
    if GeneratedLinks.ContainsKey(BindingKey) then
      Exit;
    GeneratedLinks.Add(BindingKey, True);

    NavigatorComponentName := '';
    for NavBinding in FDataAware.DataBindings do
      if SameText(NavBinding.DataLinkType, 'Navigator') and
         SameText(NavBinding.DataSource, DataSourceComponent) then
      begin
        NavigatorComponentName := NavBinding.ComponentName;
        Break;
      end;

    EnsureGeneratedBoundFieldHelpers;

    SetupLines.Add('  GeneratedRegisterManualFieldBinding(' + ABinding.ComponentName +
      ', ' + DataSetComponent + ', ''' + NormalizedFieldName + ''');');
    SetupLines.Add('');

    if not ComboDataChangeHandlerNames.TryGetValue(DataSourceComponent, DataSourceHandlerName) then
    begin
      DataSourceHandlerName := SanitizeIdentifier(DataSourceComponent) + '_GeneratedDataChange';
      ComboDataChangeHandlerNames.Add(DataSourceComponent, DataSourceHandlerName);
      MethodDeclarationLines.Add('    procedure ' + DataSourceHandlerName + '(Sender: TObject; Field: TField);');

      SyncMethods := TStringList.Create;
      SyncMethods.CaseSensitive := False;
      SyncMethods.Sorted := True;
      SyncMethods.Duplicates := dupIgnore;
      ComboDataChangeSyncMap.Add(DataSourceComponent, SyncMethods);

      if ABinding.OriginalProperties.TryGetValue('DataSource.OnDataChange',
           DataSourceHandlerNameValue) and (Trim(DataSourceHandlerNameValue) <> '') then
      begin
        ComboOriginalDataChangeHandlers.AddOrSetValue(DataSourceComponent,
          DataSourceHandlerNameValue);
        SetupLines.Add('  if Assigned(' + DataSourceComponent + ') then');
        SetupLines.Add('    ' + DataSourceComponent + '.OnDataChange := ' + DataSourceHandlerName + ';');
        CleanupLines.Add('  if Assigned(' + DataSourceComponent + ') and (' +
          DataSourceComponent + '.Owner <> Self) then');
        CleanupLines.Add('    ' + DataSourceComponent + '.OnDataChange := ' +
          DataSourceHandlerNameValue + ';');
      end
      else
      begin
        SetupLines.Add('  if Assigned(' + DataSourceComponent + ') and not Assigned(' +
          DataSourceComponent + '.OnDataChange) then');
        SetupLines.Add('    ' + DataSourceComponent + '.OnDataChange := ' + DataSourceHandlerName + ';');
        CleanupLines.Add('  if Assigned(' + DataSourceComponent + ') and (' +
          DataSourceComponent + '.Owner <> Self) then');
        CleanupLines.Add('    ' + DataSourceComponent + '.OnDataChange := nil;');
      end;
      SetupLines.Add('');
    end;

    SyncCall := 'GeneratedSyncManualFieldBindingsForDataSet(' + DataSetComponent + ');';
    SyncMethods := ComboDataChangeSyncMap[DataSourceComponent];
    if SyncMethods.IndexOf(SyncCall) = -1 then
      SyncMethods.Add(SyncCall);

    if NavigatorComponentName <> '' then
    begin
      if not ManualFieldNavigatorHandlerNames.TryGetValue(NavigatorComponentName,
           NavigatorBeforeActionMethodName) then
      begin
        NavigatorBeforeActionMethodName :=
          SanitizeIdentifier(NavigatorComponentName) + '_GeneratedBeforeAction';
        ManualFieldNavigatorHandlerNames.Add(NavigatorComponentName,
          NavigatorBeforeActionMethodName);
        MethodDeclarationLines.Add('    procedure ' +
          NavigatorBeforeActionMethodName +
          '(Sender: TObject; Button: TBindNavigateBtn);');
        if not NavigatorOriginalBeforeActionFields.TryGetValue(
             NavigatorComponentName, NavigatorOriginalBeforeActionField) then
        begin
          NavigatorOriginalBeforeActionField := 'FOriginal_' +
            SanitizeIdentifier(NavigatorComponentName) + '_BeforeAction';
          NavigatorOriginalBeforeActionFields.Add(NavigatorComponentName,
            NavigatorOriginalBeforeActionField);
          DeclarationLines.Add('    ' + NavigatorOriginalBeforeActionField +
            ': EBindNavClick;');
        end;
        CommitList := TStringList.Create;
        CommitList.CaseSensitive := False;
        CommitList.Sorted := True;
        CommitList.Duplicates := dupIgnore;
        ManualFieldNavigatorCommitMap.Add(NavigatorComponentName, CommitList);
        SyncList := TStringList.Create;
        SyncList.CaseSensitive := False;
        SyncList.Sorted := True;
        SyncList.Duplicates := dupIgnore;
        ManualFieldNavigatorSyncMap.Add(NavigatorComponentName, SyncList);
        SetupLines.Add('  if Assigned(' + NavigatorComponentName + ') then');
        SetupLines.Add('  begin');
        SetupLines.Add('    ' + NavigatorOriginalBeforeActionField + ' := ' +
          NavigatorComponentName + '.BeforeAction;');
        SetupLines.Add('    ' + NavigatorComponentName + '.BeforeAction := ' +
          NavigatorBeforeActionMethodName + ';');
        SetupLines.Add('  end;');
        CleanupLines.Add('  if Assigned(' + NavigatorComponentName + ') and (' +
          NavigatorComponentName + '.Owner <> Self) then');
        CleanupLines.Add('    ' + NavigatorComponentName + '.BeforeAction := ' +
          NavigatorOriginalBeforeActionField + ';');
        SetupLines.Add('');
      end
      else
      begin
        CommitList := ManualFieldNavigatorCommitMap[NavigatorComponentName];
        SyncList := ManualFieldNavigatorSyncMap[NavigatorComponentName];
      end;

      CommitCall := 'GeneratedCommitManualFieldBindingsForDataSet(' +
        DataSetComponent + ');';
      if CommitList.IndexOf(CommitCall) = -1 then
        CommitList.Add(CommitCall);
      if SyncList.IndexOf(SyncCall) = -1 then
        SyncList.Add(SyncCall);
    end;
  end;

  procedure AddLinkPropertyField(const ALinkField, ABindSourceField, AComponentName,
    AFieldName, APropertyName: string);
  var
    NormalizedFieldName: string;
  begin
    if GeneratedLinks.ContainsKey(ALinkField) then
      Exit;

    NormalizedFieldName := UnquoteValue(AFieldName);
    GeneratedLinks.Add(ALinkField, True);
    DeclarationLines.Add('    ' + ALinkField + ': TLinkPropertyToField;');
    SetupLines.Add('  if ' + ALinkField + ' = nil then');
    SetupLines.Add('  begin');
    SetupLines.Add('    ' + ALinkField + ' := TLinkPropertyToField.Create(Self);');
    SetupLines.Add('    ' + ALinkField + '.DataSource := ' + ABindSourceField + ';');
    SetupLines.Add('    ' + ALinkField + '.FieldName := ''' + NormalizedFieldName + ''';');
    SetupLines.Add('    ' + ALinkField + '.Component := ' + AComponentName + ';');
    SetupLines.Add('    ' + ALinkField + '.ComponentProperty := ''' + APropertyName + ''';');
    SetupLines.Add('    ' + ALinkField + '.AutoActivate := True;');
    SetupLines.Add('  end;');
    SetupLines.Add('');

  end;

  procedure AddLinkGridField(const ALinkField, ABindSourceField, AComponentName: string;
    const ABinding: TDataBindingInfo);
  var
    ColumnCount: Integer;
    I: Integer;
    SelectorMode: Boolean;
    BrowseMode: Boolean;
    FieldName: string;
    ActualFieldName: string;
    HeaderValue: string;
    WidthValue: string;
    DataSetComponent: string;
    WheelHandlerName: string;
    WheelKey: string;
  begin
    if GeneratedLinks.ContainsKey(ALinkField) then
      Exit;

    DataSetComponent := '';
    if Assigned(ABinding) then
      ABinding.OriginalProperties.TryGetValue('DataSetComponent', DataSetComponent);
    GeneratedLinks.Add(ALinkField, True);
    DeclarationLines.Add('    ' + ALinkField + ': TLinkGridToDataSource;');
    SetupLines.Add('  if ' + ALinkField + ' = nil then');
    SetupLines.Add('  begin');
    SetupLines.Add('    ' + ALinkField + ' := TLinkGridToDataSource.Create(Self);');
    SetupLines.Add('    ' + ALinkField + '.AutoActivate := False;');
    SetupLines.Add('    ' + ALinkField + '.DataSource := ' + ABindSourceField + ';');
    SetupLines.Add('    ' + ALinkField + '.GridControl := ' + AComponentName + ';');
    SetupLines.Add('    ApplyGridSelectionColor(' + AComponentName + ', $FFD7E8FA);');
    ColumnCount := 0;
    if Assigned(ABinding) and
       ABinding.OriginalProperties.ContainsKey('GridColumnCount') then
      ColumnCount := StrToIntDef(ABinding.OriginalProperties['GridColumnCount'], 0);
    SelectorMode := GridUsesSelectorEditors(ABinding);
    if ColumnCount > 0 then
    begin
      SetupLines.Add('    ' + ALinkField + '.Columns.Clear;');
      for I := 0 to ColumnCount - 1 do
      begin
        if not ABinding.OriginalProperties.TryGetValue(
          Format('GridColumn%d.FieldName', [I]), FieldName) then
          Continue;
        if not ABinding.OriginalProperties.TryGetValue(
             Format('GridColumn%d.DisplayFieldName', [I]), ActualFieldName) or
           (Trim(ActualFieldName) = '') then
          ActualFieldName := FieldName;
        SetupLines.Add('    with TLinkGridToDataSourceColumn(' + ALinkField + '.Columns.Add) do');
        SetupLines.Add('    begin');
        SetupLines.Add('      MemberName := ' + QuoteValue(ActualFieldName) + ';');
        if ABinding.OriginalProperties.TryGetValue(
          Format('GridColumn%d.Title.Caption', [I]), HeaderValue) then
          SetupLines.Add('      Header := ' + HeaderValue + ';');
        if ABinding.OriginalProperties.TryGetValue(
          Format('GridColumn%d.Width', [I]), WidthValue) then
          SetupLines.Add('      Width := ' + WidthValue + ';');
        SetupLines.Add('    end;');
      end;
    end;
    SetupLines.Add('    ' + ALinkField + '.Active := True;');
    if ColumnCount = 0 then
      SetupLines.Add('    ' + ALinkField + '.UpdateColumns;');
    SetupLines.Add('    if Assigned(' + AComponentName + ') then');
    SetupLines.Add('      ' + AComponentName + '.Repaint;');
    SetupLines.Add('  end;');
    SetupLines.Add('');

    BrowseMode := GridUsesStandaloneEditorBrowseMode(ABinding);
    if SelectorMode then
    begin
      SetupLines.Add('  if Assigned(' + AComponentName + ') then');
      SetupLines.Add('    ' + AComponentName + '.Options := ' + AComponentName +
        '.Options - [TGridOption.Editing, TGridOption.CancelEditingByDefault];');
      SetupLines.Add('');
    end;

    if BrowseMode then
    begin
      SetupLines.Add('  if Assigned(' + AComponentName + ') then');
      SetupLines.Add('  begin');
      SetupLines.Add('    ' + AComponentName + '.ReadOnly := True;');
      SetupLines.Add('    ' + AComponentName + '.Options := ' + AComponentName +
        '.Options - [TGridOption.Editing, TGridOption.CancelEditingByDefault];');
      SetupLines.Add('  end;');
      SetupLines.Add('');
    end;

    if Trim(DataSetComponent) <> '' then
    begin
      WheelHandlerName := SanitizeIdentifier(AComponentName) + '_GeneratedMouseWheel';
      WheelKey := 'GridMouseWheel_' + SanitizeIdentifier(AComponentName);
      if not GeneratedLinks.ContainsKey(WheelKey) then
      begin
        GeneratedLinks.Add(WheelKey, True);
        MethodDeclarationLines.Add('    procedure ' + WheelHandlerName +
          '(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);');
        MethodImplementationLines.Add('procedure __FORM_CLASS__.' + WheelHandlerName +
          '(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);');
        MethodImplementationLines.Add('begin');
        MethodImplementationLines.Add('  if Assigned(' + DataSetComponent + ') and ' + DataSetComponent +
          '.Active and (not ' + DataSetComponent + '.IsEmpty) then');
        MethodImplementationLines.Add('  begin');
        MethodImplementationLines.Add('    if WheelDelta > 0 then');
        MethodImplementationLines.Add('    begin');
        MethodImplementationLines.Add('      if not ' + DataSetComponent + '.BOF then');
        MethodImplementationLines.Add('        ' + DataSetComponent + '.Prior;');
        MethodImplementationLines.Add('    end');
        MethodImplementationLines.Add('    else if WheelDelta < 0 then');
        MethodImplementationLines.Add('    begin');
        MethodImplementationLines.Add('      if not ' + DataSetComponent + '.EOF then');
        MethodImplementationLines.Add('        ' + DataSetComponent + '.Next;');
        MethodImplementationLines.Add('      if ' + DataSetComponent + '.EOF and (not ' + DataSetComponent + '.IsEmpty) then');
        MethodImplementationLines.Add('        ' + DataSetComponent + '.Last;');
        MethodImplementationLines.Add('    end;');
        MethodImplementationLines.Add('    if Assigned(' + AComponentName + ') then');
        MethodImplementationLines.Add('    begin');
        MethodImplementationLines.Add('      if ' + DataSetComponent + '.RecNo > 0 then');
        MethodImplementationLines.Add('        ' + AComponentName + '.Selected := ' + DataSetComponent + '.RecNo - 1');
        MethodImplementationLines.Add('      else');
        MethodImplementationLines.Add('        ' + AComponentName + '.Selected := 0;');
        MethodImplementationLines.Add('    end;');
        MethodImplementationLines.Add('    Handled := True;');
        MethodImplementationLines.Add('  end;');
        MethodImplementationLines.Add('end;');
        MethodImplementationLines.Add('');
        SetupLines.Add('  if Assigned(' + AComponentName + ') and not Assigned(' +
          AComponentName + '.OnMouseWheel) then');
        SetupLines.Add('    ' + AComponentName + '.OnMouseWheel := ' + WheelHandlerName + ';');
        SetupLines.Add('');
      end;

      SetupLines.Add('  if (' + ALinkField + ' <> nil) and Assigned(' + DataSetComponent + ') and ' +
        DataSetComponent + '.Active then');
      SetupLines.Add('  begin');
      SetupLines.Add('    ' + ALinkField + '.Active := False;');
      SetupLines.Add('    ' + ALinkField + '.Active := True;');
      SetupLines.Add('    if Assigned(' + AComponentName + ') then');
      SetupLines.Add('      ' + AComponentName + '.Repaint;');
      SetupLines.Add('  end;');
      SetupLines.Add('');
    end;

end;

  procedure AddSelectorGridEditors(const ABinding: TDataBindingInfo;
    const ABindSourceField, AGridName: string);
  var
    ColumnCount: Integer;
    I: Integer;
    FieldName: string;
    NormalizedFieldName: string;
    HeaderValue: string;
    WidthValue: string;
    DataSetComponent: string;
    DataSourceComponent: string;
    DataSourceHandlerName: string;
    DataSourceHandlerNameValue: string;
    RefreshMethodName: string;
    SyncMethodName: string;
    CommitMethodName: string;
    TryParseDateMethodName: string;
    TryParseTimeMethodName: string;
    AssignFieldValueMethodName: string;
    NavigatorBeforeActionMethodName: string;
    NavigatorOriginalBeforeActionField: string;
    SyncMethods: TStringList;
    PanelField: string;
    LabelField: string;
    EditField: string;
    ExitMethodName: string;
    ChangeTrackingMethodName: string;
    KeyDownMethodName: string;
    SelChangedHandler: string;
    CellClickHandler: string;
    GuardField: string;
    WheelHandlerName: string;
    WheelKey: string;
    NavigatorComponentName: string;
    NavBinding: TDataBindingInfo;
  begin
    if not GridUsesSelectorEditors(ABinding) then
      Exit;

    if not ABinding.OriginalProperties.TryGetValue('DataSetComponent', DataSetComponent) then
      Exit;
    if Trim(DataSetComponent) = '' then
      Exit;

    DataSourceComponent := ABinding.DataSource;
    ColumnCount := StrToIntDef(ABinding.OriginalProperties['GridColumnCount'], 0);
    if ColumnCount <= 0 then
      Exit;

    PanelField := 'GridEditorPanel_' + SanitizeIdentifier(AGridName);
    SelChangedHandler := SanitizeIdentifier(AGridName) + '_GeneratedSelChanged';
    CellClickHandler := SanitizeIdentifier(AGridName) + '_GeneratedCellClick';
    RefreshMethodName := SanitizeIdentifier(AGridName) + '_RefreshSelectorGrid';
    SyncMethodName := SanitizeIdentifier(AGridName) + '_SyncGeneratedEditors';
    CommitMethodName := SanitizeIdentifier(AGridName) + '_CommitGeneratedEditors';
    TryParseDateMethodName := SanitizeIdentifier(AGridName) + '_TryParseGeneratedDate';
    TryParseTimeMethodName := SanitizeIdentifier(AGridName) + '_TryParseGeneratedTime';
    AssignFieldValueMethodName := SanitizeIdentifier(AGridName) + '_AssignGeneratedFieldValue';
    GuardField := 'FUpdatingSelection_' + SanitizeIdentifier(AGridName);
    NavigatorComponentName := '';
    for NavBinding in FDataAware.DataBindings do
      if SameText(NavBinding.DataLinkType, 'Navigator') and
         SameText(NavBinding.DataSource, DataSourceComponent) then
      begin
        NavigatorComponentName := NavBinding.ComponentName;
        Break;
      end;
    NavigatorBeforeActionMethodName := '';
    NavigatorOriginalBeforeActionField := '';
    if NavigatorComponentName <> '' then
    begin
      NavigatorBeforeActionMethodName := SanitizeIdentifier(NavigatorComponentName) + '_GeneratedBeforeAction';
      if not NavigatorOriginalBeforeActionFields.TryGetValue(
           NavigatorComponentName, NavigatorOriginalBeforeActionField) then
      begin
        NavigatorOriginalBeforeActionField := 'FOriginal_' +
          SanitizeIdentifier(NavigatorComponentName) + '_BeforeAction';
        NavigatorOriginalBeforeActionFields.Add(NavigatorComponentName,
          NavigatorOriginalBeforeActionField);
        DeclarationLines.Add('    ' + NavigatorOriginalBeforeActionField +
          ': EBindNavClick;');
      end;
    end;

    if not GeneratedLinks.ContainsKey('SelectorEditors_' + SanitizeIdentifier(AGridName)) then
    begin
      GeneratedLinks.Add('SelectorEditors_' + SanitizeIdentifier(AGridName), True);
      DeclarationLines.Add('    ' + PanelField + ': TPanel;');
      DeclarationLines.Add('    ' + GuardField + ': Integer;');
      MethodDeclarationLines.Add('    procedure ' + SelChangedHandler + '(Sender: TObject);');
      MethodDeclarationLines.Add('    procedure ' + CellClickHandler + '(const Column: TColumn; const Row: Integer);');
      MethodDeclarationLines.Add('    procedure ' + RefreshMethodName + ';');
      MethodDeclarationLines.Add('    procedure ' + SyncMethodName + ';');
      MethodDeclarationLines.Add('    procedure ' + CommitMethodName + ';');
      MethodDeclarationLines.Add('    function ' + TryParseDateMethodName + '(const AInput: string; out AValue: TDateTime): Boolean;');
      MethodDeclarationLines.Add('    function ' + TryParseTimeMethodName + '(const AInput: string; out AValue: TDateTime): Boolean;');
      MethodDeclarationLines.Add('    function ' + AssignFieldValueMethodName + '(AField: TField; const AInput: string; out ANormalized: string; out AError: string): Boolean;');
      if NavigatorBeforeActionMethodName <> '' then
        MethodDeclarationLines.Add('    procedure ' + NavigatorBeforeActionMethodName + '(Sender: TObject; Button: TBindNavigateBtn);');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + SelChangedHandler + '(Sender: TObject);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if ' + GuardField + ' > 0 then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if Assigned(' + DataSetComponent + ') and ' + DataSetComponent + '.Active and');
      MethodImplementationLines.Add('     (not ' + DataSetComponent + '.IsEmpty) and Assigned(' + AGridName + ') then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    if (' + AGridName + '.Selected >= 0) and');
      MethodImplementationLines.Add('       (' + AGridName + '.Selected < ' + AGridName + '.RowCount) and');
      MethodImplementationLines.Add('       (' + DataSetComponent + '.RecNo <> ' + AGridName + '.Selected + 1) then');
      MethodImplementationLines.Add('    begin');
      MethodImplementationLines.Add('      Inc(' + GuardField + ');');
      MethodImplementationLines.Add('      try');
      MethodImplementationLines.Add('        ' + DataSetComponent + '.RecNo := ' + AGridName + '.Selected + 1;');
      MethodImplementationLines.Add('      finally');
      MethodImplementationLines.Add('        Dec(' + GuardField + ');');
      MethodImplementationLines.Add('      end;');
      MethodImplementationLines.Add('    end;');
      MethodImplementationLines.Add('    ' + SyncMethodName + ';');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      MethodImplementationLines.Add('function __FORM_CLASS__.' + TryParseDateMethodName + '(const AInput: string; out AValue: TDateTime): Boolean;');
      MethodImplementationLines.Add('var');
      MethodImplementationLines.Add('  LText: string;');
      MethodImplementationLines.Add('  FS: TFormatSettings;');
      MethodImplementationLines.Add('  Parts: TArray<string>;');
      MethodImplementationLines.Add('  A, B, C: Integer;');
      MethodImplementationLines.Add('  Y, M, D: Word;');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  Result := False;');
      MethodImplementationLines.Add('  AValue := 0;');
      MethodImplementationLines.Add('  LText := Trim(AInput);');
      MethodImplementationLines.Add('  if LText = '''' then');
      MethodImplementationLines.Add('    Exit(False);');
      MethodImplementationLines.Add('  FS := TFormatSettings.Create;');
      MethodImplementationLines.Add('  if TryStrToDate(LText, AValue, FS) or TryStrToDateTime(LText, AValue, FS) then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    AValue := Trunc(AValue);');
      MethodImplementationLines.Add('    Exit(True);');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  LText := StringReplace(LText, ''-'', ''/'', [rfReplaceAll]);');
      MethodImplementationLines.Add('  LText := StringReplace(LText, ''.'', ''/'', [rfReplaceAll]);');
      MethodImplementationLines.Add('  Parts := LText.Split([''/'']);');
      MethodImplementationLines.Add('  if Length(Parts) <> 3 then');
      MethodImplementationLines.Add('    Exit(False);');
      MethodImplementationLines.Add('  if not TryStrToInt(Trim(Parts[0]), A) then');
      MethodImplementationLines.Add('    Exit(False);');
      MethodImplementationLines.Add('  if not TryStrToInt(Trim(Parts[1]), B) then');
      MethodImplementationLines.Add('    Exit(False);');
      MethodImplementationLines.Add('  if not TryStrToInt(Trim(Parts[2]), C) then');
      MethodImplementationLines.Add('    Exit(False);');
      MethodImplementationLines.Add('  if Length(Trim(Parts[0])) = 4 then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    Y := A; M := B; D := C;');
      MethodImplementationLines.Add('  end');
      MethodImplementationLines.Add('  else');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    Y := C;');
      MethodImplementationLines.Add('    if Y < 100 then');
      MethodImplementationLines.Add('      if Y < 50 then Inc(Y, 2000) else Inc(Y, 1900);');
      MethodImplementationLines.Add('    if A > 12 then');
      MethodImplementationLines.Add('    begin');
      MethodImplementationLines.Add('      D := A; M := B;');
      MethodImplementationLines.Add('    end');
      MethodImplementationLines.Add('    else if B > 12 then');
      MethodImplementationLines.Add('    begin');
      MethodImplementationLines.Add('      M := A; D := B;');
      MethodImplementationLines.Add('    end');
      MethodImplementationLines.Add('    else');
      MethodImplementationLines.Add('    begin');
      MethodImplementationLines.Add('      M := A; D := B;');
      MethodImplementationLines.Add('    end;');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  try');
      MethodImplementationLines.Add('    AValue := EncodeDate(Y, M, D);');
      MethodImplementationLines.Add('    Result := True;');
      MethodImplementationLines.Add('  except');
      MethodImplementationLines.Add('    Result := False;');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      MethodImplementationLines.Add('function __FORM_CLASS__.' + TryParseTimeMethodName + '(const AInput: string; out AValue: TDateTime): Boolean;');
      MethodImplementationLines.Add('var');
      MethodImplementationLines.Add('  LText: string;');
      MethodImplementationLines.Add('  FS: TFormatSettings;');
      MethodImplementationLines.Add('  Hours: Integer;');
      MethodImplementationLines.Add('  Minutes: Integer;');
      MethodImplementationLines.Add('  Seconds: Integer;');
      MethodImplementationLines.Add('  P: Integer;');
      MethodImplementationLines.Add('  Parts: TArray<string>;');
      MethodImplementationLines.Add('  Suffix: string;');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  Result := False;');
      MethodImplementationLines.Add('  AValue := 0;');
      MethodImplementationLines.Add('  LText := UpperCase(Trim(AInput));');
      MethodImplementationLines.Add('  if LText = '''' then');
      MethodImplementationLines.Add('    Exit(False);');
      MethodImplementationLines.Add('  FS := TFormatSettings.Create;');
      MethodImplementationLines.Add('  if TryStrToTime(LText, AValue, FS) or TryStrToDateTime(LText, AValue, FS) then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    AValue := Frac(AValue);');
      MethodImplementationLines.Add('    Exit(True);');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  LText := StringReplace(LText, ''.'', '':'', [rfReplaceAll]);');
      MethodImplementationLines.Add('  while Pos(''  '', LText) > 0 do');
      MethodImplementationLines.Add('    LText := StringReplace(LText, ''  '', '' '', [rfReplaceAll]);');
      MethodImplementationLines.Add('  Suffix := '''';');
      MethodImplementationLines.Add('  if Length(LText) >= 2 then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    if SameText(Copy(LText, Length(LText) - 1, 2), ''AM'') or');
      MethodImplementationLines.Add('       SameText(Copy(LText, Length(LText) - 1, 2), ''PM'') then');
      MethodImplementationLines.Add('    begin');
      MethodImplementationLines.Add('      Suffix := Copy(LText, Length(LText) - 1, 2);');
      MethodImplementationLines.Add('      Delete(LText, Length(LText) - 1, 2);');
      MethodImplementationLines.Add('      LText := Trim(LText);');
      MethodImplementationLines.Add('    end;');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  Hours := 0;');
      MethodImplementationLines.Add('  Minutes := 0;');
      MethodImplementationLines.Add('  Seconds := 0;');
      MethodImplementationLines.Add('  if Pos('':'', LText) = 0 then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    if (Suffix = '''') and (Length(LText) in [3, 4]) then');
      MethodImplementationLines.Add('    begin');
      MethodImplementationLines.Add('      if not TryStrToInt(Copy(LText, 1, Length(LText) - 2), Hours) then');
      MethodImplementationLines.Add('        Exit(False);');
      MethodImplementationLines.Add('      if not TryStrToInt(Copy(LText, Length(LText) - 1, 2), Minutes) then');
      MethodImplementationLines.Add('        Exit(False);');
      MethodImplementationLines.Add('    end');
      MethodImplementationLines.Add('    else');
      MethodImplementationLines.Add('    begin');
      MethodImplementationLines.Add('      if not TryStrToInt(LText, Hours) then');
      MethodImplementationLines.Add('        Exit(False);');
      MethodImplementationLines.Add('    end;');
      MethodImplementationLines.Add('  end');
      MethodImplementationLines.Add('  else');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    Parts := LText.Split(['':'']);');
      MethodImplementationLines.Add('    if (Length(Parts) < 2) or (Length(Parts) > 3) then');
      MethodImplementationLines.Add('      Exit(False);');
      MethodImplementationLines.Add('    if not TryStrToInt(Trim(Parts[0]), Hours) then');
      MethodImplementationLines.Add('      Exit(False);');
      MethodImplementationLines.Add('    if not TryStrToInt(Trim(Parts[1]), Minutes) then');
      MethodImplementationLines.Add('      Exit(False);');
      MethodImplementationLines.Add('    if Length(Parts) = 3 then');
      MethodImplementationLines.Add('      if not TryStrToInt(Trim(Parts[2]), Seconds) then');
      MethodImplementationLines.Add('        Exit(False);');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  if (Minutes < 0) or (Minutes > 59) or (Seconds < 0) or (Seconds > 59) then');
      MethodImplementationLines.Add('    Exit(False);');
      MethodImplementationLines.Add('  if Suffix = ''AM'' then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    if (Hours < 1) or (Hours > 12) then');
      MethodImplementationLines.Add('      Exit(False);');
      MethodImplementationLines.Add('    if Hours = 12 then');
      MethodImplementationLines.Add('      Hours := 0;');
      MethodImplementationLines.Add('  end');
      MethodImplementationLines.Add('  else if Suffix = ''PM'' then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    if (Hours < 1) or (Hours > 12) then');
      MethodImplementationLines.Add('      Exit(False);');
      MethodImplementationLines.Add('    if Hours < 12 then');
      MethodImplementationLines.Add('      Inc(Hours, 12);');
      MethodImplementationLines.Add('  end');
      MethodImplementationLines.Add('  else if (Hours < 0) or (Hours > 23) then');
      MethodImplementationLines.Add('    Exit(False);');
      MethodImplementationLines.Add('  try');
      MethodImplementationLines.Add('    AValue := EncodeTime(Hours, Minutes, Seconds, 0);');
      MethodImplementationLines.Add('    Result := True;');
      MethodImplementationLines.Add('  except');
      MethodImplementationLines.Add('    Result := False;');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      MethodImplementationLines.Add('function __FORM_CLASS__.' + AssignFieldValueMethodName + '(AField: TField; const AInput: string; out ANormalized: string; out AError: string): Boolean;');
      MethodImplementationLines.Add('var');
      MethodImplementationLines.Add('  LValue: string;');
      MethodImplementationLines.Add('  LDateTime: TDateTime;');
      MethodImplementationLines.Add('  LFieldName: string;');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  Result := False;');
      MethodImplementationLines.Add('  ANormalized := '''';');
      MethodImplementationLines.Add('  AError := '''';');
      MethodImplementationLines.Add('  if AField = nil then');
      MethodImplementationLines.Add('    Exit(False);');
      MethodImplementationLines.Add('  LValue := Trim(AInput);');
      MethodImplementationLines.Add('  if LValue = '''' then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    AField.Clear;');
      MethodImplementationLines.Add('    ANormalized := '''';');
      MethodImplementationLines.Add('    Exit(True);');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  LFieldName := UpperCase(AField.FieldName);');
      MethodImplementationLines.Add('  if (AField.DataType = ftTime) or');
      MethodImplementationLines.Add('     (((AField.DataType in [ftUnknown, ftString, ftWideString, ftMemo, ftWideMemo, ftFmtMemo, ftFixedChar, ftFixedWideChar]) and');
      MethodImplementationLines.Add('       ((Pos(''_TIME'', LFieldName) > 0) or (Pos(''TIME_'', LFieldName) > 0) or (Pos(''PLAY_TIME'', LFieldName) > 0) or (Pos(''SCHEDULED_TIME'', LFieldName) > 0))) and');
      MethodImplementationLines.Add('      (Pos(''DATE'', LFieldName) = 0)) then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    if not ' + TryParseTimeMethodName + '(LValue, LDateTime) then');
      MethodImplementationLines.Add('    begin');
      MethodImplementationLines.Add('      AError := ''"'' + AInput + ''" is not a valid time.'';');
      MethodImplementationLines.Add('      Exit(False);');
      MethodImplementationLines.Add('    end;');
      MethodImplementationLines.Add('    AField.AsDateTime := LDateTime;');
      MethodImplementationLines.Add('    ANormalized := AField.DisplayText;');
      MethodImplementationLines.Add('    Exit(True);');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  if (AField.DataType in [ftDate, ftDateTime, ftTimeStamp]) or');
      MethodImplementationLines.Add('     ((AField.DataType in [ftUnknown, ftString, ftWideString, ftMemo, ftWideMemo, ftFmtMemo, ftFixedChar, ftFixedWideChar]) and');
      MethodImplementationLines.Add('      (Pos(''DATE'', LFieldName) > 0)) then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    if not ' + TryParseDateMethodName + '(LValue, LDateTime) then');
      MethodImplementationLines.Add('    begin');
      MethodImplementationLines.Add('      AError := ''"'' + AInput + ''" is not a valid date.'';');
      MethodImplementationLines.Add('      Exit(False);');
      MethodImplementationLines.Add('    end;');
      MethodImplementationLines.Add('    AField.AsDateTime := LDateTime;');
      MethodImplementationLines.Add('    ANormalized := AField.DisplayText;');
      MethodImplementationLines.Add('    Exit(True);');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  try');
      MethodImplementationLines.Add('    AField.Text := LValue;');
      MethodImplementationLines.Add('    ANormalized := AField.DisplayText;');
      MethodImplementationLines.Add('    Result := True;');
      MethodImplementationLines.Add('  except');
      MethodImplementationLines.Add('    on E: Exception do');
      MethodImplementationLines.Add('    begin');
      MethodImplementationLines.Add('      AError := E.Message;');
      MethodImplementationLines.Add('      Result := False;');
      MethodImplementationLines.Add('    end;');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + CommitMethodName + ';');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if ' + GuardField + ' > 0 then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if not Assigned(' + DataSetComponent + ') or not ' + DataSetComponent + '.Active or ' +
        DataSetComponent + '.IsEmpty then');
      MethodImplementationLines.Add('    Exit;');
      for I := 0 to ColumnCount - 1 do
      begin
        EditField := 'Ed_' + SanitizeIdentifier(AGridName) + '_' + IntToStr(I);
        ExitMethodName := EditField + '_GeneratedExit';
        MethodImplementationLines.Add('  if Assigned(' + EditField + ') then');
        MethodImplementationLines.Add('    ' + ExitMethodName + '(' + EditField + ');');
      end;
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      if NavigatorBeforeActionMethodName <> '' then
      begin
        MethodImplementationLines.Add('procedure __FORM_CLASS__.' + NavigatorBeforeActionMethodName + '(Sender: TObject; Button: TBindNavigateBtn);');
        MethodImplementationLines.Add('begin');
        MethodImplementationLines.Add('  case Button of');
        MethodImplementationLines.Add('    nbFirst, nbPrior, nbNext, nbLast, nbPost, nbInsert, nbRefresh:');
        MethodImplementationLines.Add('      ' + CommitMethodName + ';');
        MethodImplementationLines.Add('    nbCancel:');
        MethodImplementationLines.Add('      ' + SyncMethodName + ';');
        MethodImplementationLines.Add('  end;');
        if NavigatorOriginalBeforeActionField <> '' then
        begin
          MethodImplementationLines.Add('  if Assigned(' + NavigatorOriginalBeforeActionField + ') then');
          MethodImplementationLines.Add('    ' + NavigatorOriginalBeforeActionField + '(Sender, Button);');
        end;
        MethodImplementationLines.Add('end;');
        MethodImplementationLines.Add('');
      end;

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + CellClickHandler + '(const Column: TColumn; const Row: Integer);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if ' + GuardField + ' > 0 then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if Assigned(' + AGridName + ') and Assigned(' + DataSetComponent + ') and ' +
        DataSetComponent + '.Active and (not ' + DataSetComponent + '.IsEmpty) and');
      MethodImplementationLines.Add('     (Row >= 0) and (Row < ' + AGridName + '.RowCount) then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    Inc(' + GuardField + ');');
      MethodImplementationLines.Add('    try');
      MethodImplementationLines.Add('      ' + AGridName + '.Selected := Row;');
      MethodImplementationLines.Add('      if ' + DataSetComponent + '.RecNo <> Row + 1 then');
      MethodImplementationLines.Add('        ' + DataSetComponent + '.RecNo := Row + 1;');
      MethodImplementationLines.Add('    finally');
      MethodImplementationLines.Add('      Dec(' + GuardField + ');');
      MethodImplementationLines.Add('    end;');
      MethodImplementationLines.Add('    ' + SyncMethodName + ';');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + RefreshMethodName + ';');
      MethodImplementationLines.Add('var');
      MethodImplementationLines.Add('  LBookmark: TBookmark;');
      MethodImplementationLines.Add('  LRow: Integer;');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if ' + GuardField + ' > 0 then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if not Assigned(' + AGridName + ') or (' + AGridName + '.ColumnCount = 0) then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  Inc(' + GuardField + ');');
      MethodImplementationLines.Add('  try');
      MethodImplementationLines.Add('    ' + AGridName + '.BeginUpdate;');
      MethodImplementationLines.Add('    try');
      MethodImplementationLines.Add('      if Assigned(' + DataSetComponent + ') and ' + DataSetComponent + '.Active and');
      MethodImplementationLines.Add('         (not ' + DataSetComponent + '.IsEmpty) then');
      MethodImplementationLines.Add('      begin');
      MethodImplementationLines.Add('        LBookmark := nil;');
      MethodImplementationLines.Add('        ' + DataSetComponent + '.DisableControls;');
      MethodImplementationLines.Add('        try');
      MethodImplementationLines.Add('          LBookmark := ' + DataSetComponent + '.GetBookmark;');
      MethodImplementationLines.Add('          ' + AGridName + '.RowCount := 0;');
      MethodImplementationLines.Add('          ' + DataSetComponent + '.First;');
      MethodImplementationLines.Add('          LRow := 0;');
      MethodImplementationLines.Add('          while not ' + DataSetComponent + '.Eof do');
      MethodImplementationLines.Add('          begin');
      MethodImplementationLines.Add('            if ' + AGridName + '.RowCount <= LRow then');
      MethodImplementationLines.Add('              ' + AGridName + '.RowCount := LRow + 1;');
      for I := 0 to ColumnCount - 1 do
      begin
        if not ABinding.OriginalProperties.TryGetValue(Format('GridColumn%d.FieldName', [I]), FieldName) then
          Continue;
        NormalizedFieldName := UnquoteValue(FieldName);
        if Trim(NormalizedFieldName) = '' then
          Continue;
        MethodImplementationLines.Add('            if ' + DataSetComponent + '.FindField(''' + NormalizedFieldName + ''') <> nil then');
        MethodImplementationLines.Add('              ' + AGridName + '.Cells[' + IntToStr(I) + ', LRow] := ' +
          DataSetComponent + '.FieldByName(''' + NormalizedFieldName + ''').DisplayText');
        MethodImplementationLines.Add('            else');
        MethodImplementationLines.Add('              ' + AGridName + '.Cells[' + IntToStr(I) + ', LRow] := '''';');
      end;
      MethodImplementationLines.Add('            Inc(LRow);');
      MethodImplementationLines.Add('            ' + DataSetComponent + '.Next;');
      MethodImplementationLines.Add('          end;');
      MethodImplementationLines.Add('          if (LBookmark <> nil) and ' + DataSetComponent + '.BookmarkValid(LBookmark) then');
      MethodImplementationLines.Add('            ' + DataSetComponent + '.GotoBookmark(LBookmark);');
      MethodImplementationLines.Add('        finally');
      MethodImplementationLines.Add('          if LBookmark <> nil then');
      MethodImplementationLines.Add('            ' + DataSetComponent + '.FreeBookmark(LBookmark);');
      MethodImplementationLines.Add('          ' + DataSetComponent + '.EnableControls;');
      MethodImplementationLines.Add('        end;');
      MethodImplementationLines.Add('        if ' + DataSetComponent + '.RecNo > 0 then');
      MethodImplementationLines.Add('          ' + AGridName + '.Selected := ' + DataSetComponent + '.RecNo - 1');
      MethodImplementationLines.Add('        else');
      MethodImplementationLines.Add('          ' + AGridName + '.Selected := 0;');
      MethodImplementationLines.Add('      end');
      MethodImplementationLines.Add('      else');
      MethodImplementationLines.Add('        ' + AGridName + '.RowCount := 0;');
      MethodImplementationLines.Add('    finally');
      MethodImplementationLines.Add('      ' + AGridName + '.EndUpdate;');
      MethodImplementationLines.Add('    end;');
      MethodImplementationLines.Add('  finally');
      MethodImplementationLines.Add('    Dec(' + GuardField + ');');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      SetupLines.Add('  if Assigned(' + AGridName + ') and not Assigned(' + AGridName + '.OnSelChanged) then');
      SetupLines.Add('    ' + AGridName + '.OnSelChanged := ' + SelChangedHandler + ';');
      SetupLines.Add('  if Assigned(' + AGridName + ') and not Assigned(' + AGridName + '.OnCellClick) then');
      SetupLines.Add('    ' + AGridName + '.OnCellClick := ' + CellClickHandler + ';');
      SetupLines.Add('');

      SetupLines.Add('  if Assigned(' + AGridName + ') then');
      SetupLines.Add('  begin');
      SetupLines.Add('    ApplyGridSelectionColor(' + AGridName + ', $FFD7E8FA);');
      SetupLines.Add('    ' + AGridName + '.Options := ' + AGridName + '.Options - [TGridOption.Editing, TGridOption.CancelEditingByDefault];');
      SetupLines.Add('  end;');
      SetupLines.Add('');

      SetupLines.Add('  if Assigned(' + AGridName + ') and (' + AGridName + '.ColumnCount = 0) then');
      SetupLines.Add('  begin');
      SetupLines.Add('    ' + AGridName + '.BeginUpdate;');
      SetupLines.Add('    try');
      for I := 0 to ColumnCount - 1 do
      begin
        if not ABinding.OriginalProperties.TryGetValue(Format('GridColumn%d.FieldName', [I]), FieldName) then
          Continue;
        if not ABinding.OriginalProperties.TryGetValue(Format('GridColumn%d.Title.Caption', [I]), HeaderValue) then
          HeaderValue := QuoteValue(UnquoteValue(FieldName));
        SetupLines.Add('      with TStringColumn.Create(' + AGridName + ') do');
        SetupLines.Add('      begin');
        SetupLines.Add('        Parent := ' + AGridName + ';');
        SetupLines.Add('        Header := ' + HeaderValue + ';');
        if ABinding.OriginalProperties.TryGetValue(Format('GridColumn%d.Width', [I]), WidthValue) then
          SetupLines.Add('        Width := ' + WidthValue + ';');
        SetupLines.Add('        ReadOnly := True;');
        SetupLines.Add('      end;');
      end;
      SetupLines.Add('    finally');
      SetupLines.Add('      ' + AGridName + '.EndUpdate;');
      SetupLines.Add('    end;');
      SetupLines.Add('  end;');
      SetupLines.Add('');

      WheelHandlerName := SanitizeIdentifier(AGridName) + '_GeneratedMouseWheel';
      WheelKey := 'GridMouseWheel_' + SanitizeIdentifier(AGridName);
      if not GeneratedLinks.ContainsKey(WheelKey) then
      begin
        GeneratedLinks.Add(WheelKey, True);
        MethodDeclarationLines.Add('    procedure ' + WheelHandlerName +
          '(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);');
        MethodImplementationLines.Add('procedure __FORM_CLASS__.' + WheelHandlerName +
          '(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);');
        MethodImplementationLines.Add('begin');
        MethodImplementationLines.Add('  if Assigned(' + DataSetComponent + ') and ' + DataSetComponent +
          '.Active and (not ' + DataSetComponent + '.IsEmpty) then');
        MethodImplementationLines.Add('  begin');
        MethodImplementationLines.Add('    if WheelDelta > 0 then');
        MethodImplementationLines.Add('    begin');
        MethodImplementationLines.Add('      if not ' + DataSetComponent + '.BOF then');
        MethodImplementationLines.Add('        ' + DataSetComponent + '.Prior;');
        MethodImplementationLines.Add('    end');
        MethodImplementationLines.Add('    else if WheelDelta < 0 then');
        MethodImplementationLines.Add('    begin');
        MethodImplementationLines.Add('      if not ' + DataSetComponent + '.EOF then');
        MethodImplementationLines.Add('        ' + DataSetComponent + '.Next;');
        MethodImplementationLines.Add('      if ' + DataSetComponent + '.EOF and (not ' + DataSetComponent + '.IsEmpty) then');
        MethodImplementationLines.Add('        ' + DataSetComponent + '.Last;');
        MethodImplementationLines.Add('    end;');
        MethodImplementationLines.Add('    Handled := True;');
        MethodImplementationLines.Add('  end;');
        MethodImplementationLines.Add('end;');
        MethodImplementationLines.Add('');
      SetupLines.Add('  if Assigned(' + AGridName + ') and not Assigned(' + AGridName + '.OnMouseWheel) then');
      SetupLines.Add('    ' + AGridName + '.OnMouseWheel := ' + WheelHandlerName + ';');
      SetupLines.Add('');

      if NavigatorBeforeActionMethodName <> '' then
      begin
        SetupLines.Add('  if Assigned(' + NavigatorComponentName + ') then');
        SetupLines.Add('  begin');
        SetupLines.Add('    ' + NavigatorOriginalBeforeActionField + ' := ' + NavigatorComponentName + '.BeforeAction;');
        SetupLines.Add('    ' + NavigatorComponentName + '.BeforeAction := ' + NavigatorBeforeActionMethodName + ';');
        SetupLines.Add('  end;');
        CleanupLines.Add('  if Assigned(' + NavigatorComponentName + ') and (' + NavigatorComponentName + '.Owner <> Self) then');
        CleanupLines.Add('    ' + NavigatorComponentName + '.BeforeAction := ' + NavigatorOriginalBeforeActionField + ';');
        SetupLines.Add('');
      end;
      end;

      SetupLines.Add('  if Assigned(' + AGridName + ') and (' + PanelField + ' = nil) then');
      SetupLines.Add('  begin');
      SetupLines.Add('    ' + PanelField + ' := TPanel.Create(Self);');
      SetupLines.Add('    ' + PanelField + '.Parent := Self;');
      SetupLines.Add('    ' + PanelField + '.Visible := True;');
      SetupLines.Add('    ' + PanelField + '.Position.Y := ' + AGridName + '.Position.Y;');
      SetupLines.Add('    if Round(Self.ClientWidth - (' + AGridName + '.Position.X + ' + AGridName + '.Width)) >= 190 then');
      SetupLines.Add('    begin');
      SetupLines.Add('      ' + PanelField + '.Position.X := ' + AGridName + '.Position.X + ' + AGridName + '.Width + 12;');
      SetupLines.Add('      ' + PanelField + '.Width := Self.ClientWidth - ' + PanelField + '.Position.X - 12;');
      SetupLines.Add('      if ' + PanelField + '.Width < 180 then');
      SetupLines.Add('        ' + PanelField + '.Width := 180;');
      SetupLines.Add('      ' + PanelField + '.Height := 12 + (' + IntToStr(ColumnCount) + ' * 50);');
      SetupLines.Add('    end');
      SetupLines.Add('    else');
      SetupLines.Add('    begin');
      SetupLines.Add('      ' + PanelField + '.Position.X := ' + AGridName + '.Position.X;');
      SetupLines.Add('      ' + PanelField + '.Position.Y := ' + AGridName + '.Position.Y + ' + AGridName + '.Height + 8;');
      SetupLines.Add('      ' + PanelField + '.Width := ' + AGridName + '.Width;');
      SetupLines.Add('      ' + PanelField + '.Height := 12 + ((((' + IntToStr(ColumnCount) + ' + 1) div 2)) * 50);');
      SetupLines.Add('    end;');
      SetupLines.Add('  end;');
      SetupLines.Add('');
    end;

    for I := 0 to ColumnCount - 1 do
    begin
      if not ABinding.OriginalProperties.TryGetValue(Format('GridColumn%d.FieldName', [I]), FieldName) then
        Continue;
      NormalizedFieldName := UnquoteValue(FieldName);
      if Trim(NormalizedFieldName) = '' then
        Continue;

      if not ABinding.OriginalProperties.TryGetValue(Format('GridColumn%d.Title.Caption', [I]), HeaderValue) then
        HeaderValue := QuoteValue(UnquoteValue(FieldName));

      LabelField := 'Lbl_' + SanitizeIdentifier(AGridName) + '_' + IntToStr(I);
      EditField := 'Ed_' + SanitizeIdentifier(AGridName) + '_' + IntToStr(I);
      ExitMethodName := EditField + '_GeneratedExit';
      ChangeTrackingMethodName := EditField + '_GeneratedChangeTracking';
      KeyDownMethodName := EditField + '_GeneratedKeyDown';

      DeclarationLines.Add('    ' + LabelField + ': TLabel;');
      DeclarationLines.Add('    ' + EditField + ': TEdit;');
      MethodDeclarationLines.Add('    procedure ' + ExitMethodName + '(Sender: TObject);');
      MethodDeclarationLines.Add('    procedure ' + ChangeTrackingMethodName + '(Sender: TObject);');
      MethodDeclarationLines.Add('    procedure ' + KeyDownMethodName + '(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);');

      SetupLines.Add('  if ' + LabelField + ' = nil then');
      SetupLines.Add('  begin');
      SetupLines.Add('    ' + LabelField + ' := TLabel.Create(Self);');
      SetupLines.Add('    ' + LabelField + '.Parent := ' + PanelField + ';');
      SetupLines.Add('    ' + LabelField + '.Text := ' + HeaderValue + ';');
      SetupLines.Add('    ' + LabelField + '.AutoSize := True;');
      SetupLines.Add('  end;');
      SetupLines.Add('  if ' + EditField + ' = nil then');
      SetupLines.Add('  begin');
      SetupLines.Add('    ' + EditField + ' := TEdit.Create(Self);');
      SetupLines.Add('    ' + EditField + '.Parent := ' + PanelField + ';');
      SetupLines.Add('  end;');
      SetupLines.Add('  ' + EditField + '.OnChangeTracking := ' + ChangeTrackingMethodName + ';');
      SetupLines.Add('  ' + EditField + '.OnExit := ' + ExitMethodName + ';');
      SetupLines.Add('  ' + EditField + '.OnKeyDown := ' + KeyDownMethodName + ';');
      SetupLines.Add('  if ' + PanelField + '.Position.X > ' + AGridName + '.Position.X then');
      SetupLines.Add('  begin');
      SetupLines.Add('    ' + LabelField + '.Position.X := 8;');
      SetupLines.Add('    ' + LabelField + '.Position.Y := 8 + (' + IntToStr(I) + ' * 50);');
      SetupLines.Add('    ' + EditField + '.Position.X := 8;');
      SetupLines.Add('    ' + EditField + '.Position.Y := 24 + (' + IntToStr(I) + ' * 50);');
      SetupLines.Add('    ' + EditField + '.Width := ' + PanelField + '.Width - 16;');
      SetupLines.Add('  end');
      SetupLines.Add('  else');
      SetupLines.Add('  begin');
      SetupLines.Add('    ' + LabelField + '.Position.X := 8 + ((' + IntToStr(I) + ' mod 2) * ((' + PanelField + '.Width - 24) / 2));');
      SetupLines.Add('    ' + LabelField + '.Position.Y := 8 + ((' + IntToStr(I) + ' div 2) * 50);');
      SetupLines.Add('    ' + EditField + '.Position.X := 8 + ((' + IntToStr(I) + ' mod 2) * ((' + PanelField + '.Width - 24) / 2));');
      SetupLines.Add('    ' + EditField + '.Position.Y := 24 + ((' + IntToStr(I) + ' div 2) * 50);');
      SetupLines.Add('    ' + EditField + '.Width := ((' + PanelField + '.Width - 24) / 2);');
      SetupLines.Add('  end;');
      SetupLines.Add('');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + ChangeTrackingMethodName + '(Sender: TObject);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if ' + GuardField + ' > 0 then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if not Assigned(' + DataSetComponent + ') or not ' + DataSetComponent + '.Active or ' +
        DataSetComponent + '.IsEmpty then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if not (' + DataSetComponent + '.State in dsEditModes) then');
      MethodImplementationLines.Add('    ' + DataSetComponent + '.Edit;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + ExitMethodName + '(Sender: TObject);');
      MethodImplementationLines.Add('var');
      MethodImplementationLines.Add('  LField: TField;');
      MethodImplementationLines.Add('  LValue: string;');
      MethodImplementationLines.Add('  LNormalized: string;');
      MethodImplementationLines.Add('  LError: string;');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if ' + GuardField + ' > 0 then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if not Assigned(' + DataSetComponent + ') or not ' + DataSetComponent + '.Active or ' +
        DataSetComponent + '.IsEmpty then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  LField := ' + DataSetComponent + '.FindField(''' + NormalizedFieldName + ''');');
      MethodImplementationLines.Add('  if LField = nil then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  LValue := Trim(' + EditField + '.Text);');
      MethodImplementationLines.Add('  if LField.DisplayText = LValue then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if not (' + DataSetComponent + '.State in dsEditModes) then');
      MethodImplementationLines.Add('    ' + DataSetComponent + '.Edit;');
      MethodImplementationLines.Add('  if not ' + AssignFieldValueMethodName + '(LField, LValue, LNormalized, LError) then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    Inc(' + GuardField + ');');
      MethodImplementationLines.Add('    try');
      MethodImplementationLines.Add('      if LError <> '''' then');
      MethodImplementationLines.Add('        ShowMessage(LError);');
      MethodImplementationLines.Add('      ' + EditField + '.Text := LField.DisplayText;');
      MethodImplementationLines.Add('    finally');
      MethodImplementationLines.Add('      Dec(' + GuardField + ');');
      MethodImplementationLines.Add('    end;');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  ' + EditField + '.Text := LNormalized;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + KeyDownMethodName + '(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if Key = vkReturn then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    ' + ExitMethodName + '(Sender);');
      MethodImplementationLines.Add('    Key := 0;');
      MethodImplementationLines.Add('    KeyChar := #0;');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

    end;

    MethodImplementationLines.Add('procedure __FORM_CLASS__.' + SyncMethodName + ';');
    MethodImplementationLines.Add('begin');
    MethodImplementationLines.Add('  if ' + GuardField + ' > 0 then');
    MethodImplementationLines.Add('    Exit;');
    MethodImplementationLines.Add('  Inc(' + GuardField + ');');
      MethodImplementationLines.Add('  try');
      MethodImplementationLines.Add('    if Assigned(' + DataSetComponent + ') and ' + DataSetComponent + '.Active and');
      MethodImplementationLines.Add('       (not ' + DataSetComponent + '.IsEmpty) then');
      MethodImplementationLines.Add('    begin');
    for I := 0 to ColumnCount - 1 do
    begin
      if not ABinding.OriginalProperties.TryGetValue(Format('GridColumn%d.FieldName', [I]), FieldName) then
        Continue;
      NormalizedFieldName := UnquoteValue(FieldName);
      if Trim(NormalizedFieldName) = '' then
        Continue;
      EditField := 'Ed_' + SanitizeIdentifier(AGridName) + '_' + IntToStr(I);
      MethodImplementationLines.Add('      if Assigned(' + EditField + ') then');
      MethodImplementationLines.Add('      begin');
      MethodImplementationLines.Add('        if ' + DataSetComponent + '.FindField(''' + NormalizedFieldName + ''') <> nil then');
      MethodImplementationLines.Add('          ' + EditField + '.Text := ' + DataSetComponent + '.FieldByName(''' +
        NormalizedFieldName + ''').DisplayText');
      MethodImplementationLines.Add('        else');
      MethodImplementationLines.Add('          ' + EditField + '.Text := '''';');
      MethodImplementationLines.Add('      end;');
    end;
    MethodImplementationLines.Add('      if Assigned(' + AGridName + ') and (' + DataSetComponent + '.RecNo > 0) then');
    MethodImplementationLines.Add('        ' + AGridName + '.Selected := ' + DataSetComponent + '.RecNo - 1;');
    MethodImplementationLines.Add('    end');
    MethodImplementationLines.Add('    else');
    MethodImplementationLines.Add('    begin');
    for I := 0 to ColumnCount - 1 do
    begin
      EditField := 'Ed_' + SanitizeIdentifier(AGridName) + '_' + IntToStr(I);
      MethodImplementationLines.Add('      if Assigned(' + EditField + ') then');
      MethodImplementationLines.Add('        ' + EditField + '.Text := '''';');
    end;
    MethodImplementationLines.Add('    end;');
    MethodImplementationLines.Add('  finally');
    MethodImplementationLines.Add('    Dec(' + GuardField + ');');
    MethodImplementationLines.Add('  end;');
    MethodImplementationLines.Add('end;');
    MethodImplementationLines.Add('');

    SetupLines.Add('  ' + RefreshMethodName + ';');
    SetupLines.Add('  ' + SyncMethodName + ';');
    SetupLines.Add('');

    if not ComboDataChangeHandlerNames.TryGetValue(DataSourceComponent, DataSourceHandlerName) then
    begin
      DataSourceHandlerName := SanitizeIdentifier(DataSourceComponent) + '_GeneratedDataChange';
      ComboDataChangeHandlerNames.Add(DataSourceComponent, DataSourceHandlerName);
      MethodDeclarationLines.Add('    procedure ' + DataSourceHandlerName + '(Sender: TObject; Field: TField);');

      SyncMethods := TStringList.Create;
      SyncMethods.CaseSensitive := False;
      SyncMethods.Sorted := True;
      SyncMethods.Duplicates := dupIgnore;
      ComboDataChangeSyncMap.Add(DataSourceComponent, SyncMethods);

      if ABinding.OriginalProperties.TryGetValue('DataSource.OnDataChange',
           DataSourceHandlerNameValue) and (Trim(DataSourceHandlerNameValue) <> '') then
      begin
        ComboOriginalDataChangeHandlers.AddOrSetValue(DataSourceComponent,
          DataSourceHandlerNameValue);
        SetupLines.Add('  if Assigned(' + DataSourceComponent + ') then');
        SetupLines.Add('    ' + DataSourceComponent + '.OnDataChange := ' + DataSourceHandlerName + ';');
        CleanupLines.Add('  if Assigned(' + DataSourceComponent + ') and (' +
          DataSourceComponent + '.Owner <> Self) then');
        CleanupLines.Add('    ' + DataSourceComponent + '.OnDataChange := ' +
          DataSourceHandlerNameValue + ';');
      end
      else
      begin
        SetupLines.Add('  if Assigned(' + DataSourceComponent + ') and not Assigned(' +
          DataSourceComponent + '.OnDataChange) then');
        SetupLines.Add('    ' + DataSourceComponent + '.OnDataChange := ' + DataSourceHandlerName + ';');
        CleanupLines.Add('  if Assigned(' + DataSourceComponent + ') and (' +
          DataSourceComponent + '.Owner <> Self) then');
        CleanupLines.Add('    ' + DataSourceComponent + '.OnDataChange := nil;');
      end;
      SetupLines.Add('');
    end;

    SyncMethods := ComboDataChangeSyncMap[DataSourceComponent];
    if SyncMethods.IndexOf(RefreshMethodName) = -1 then
      SyncMethods.Add(RefreshMethodName);
    if SyncMethods.IndexOf(SyncMethodName) = -1 then
      SyncMethods.Add(SyncMethodName);
  end;

  procedure AddNavigatorBinding(const ABindSourceField, AComponentName: string);
  var
    NavigatorKey: string;
  begin
    NavigatorKey := 'Navigator_' + SanitizeIdentifier(AComponentName);
    if GeneratedLinks.ContainsKey(NavigatorKey) then
      Exit;

    GeneratedLinks.Add(NavigatorKey, True);
    SetupLines.Add('  if Assigned(' + AComponentName + ') then');
    SetupLines.Add('    ' + AComponentName + '.DataSource := ' + ABindSourceField + ';');
    SetupLines.Add('');

  end;

  procedure AddComboTextBinding(const ABinding: TDataBindingInfo);
  var
    BindingKey: string;
    GuardField: string;
    OriginalChangeField: string;
    OriginalPopupField: string;
    OriginalClosePopupField: string;
    SyncMethodName: string;
    ChangeMethodName: string;
    PopupMethodName: string;
    ClosePopupMethodName: string;
    DataSourceHandlerName: string;
    DataSourceHandlerNameValue: string;
    DataSetComponent: string;
    DataSourceComponent: string;
    SyncMethods: TStringList;
  begin
    if not Assigned(ABinding) then
      Exit;

    if (ABinding.ComponentName = '') or (ABinding.DataSource = '') or
       (ABinding.DataField = '') then
      Exit;

    if not ABinding.OriginalProperties.TryGetValue('DataSetComponent', DataSetComponent) then
      Exit;
    if Trim(DataSetComponent) = '' then
      Exit;

    DataSourceComponent := ABinding.DataSource;
    BindingKey := 'ComboText_' + SanitizeIdentifier(ABinding.ComponentName);
    if GeneratedLinks.ContainsKey(BindingKey) then
      Exit;
    GeneratedLinks.Add(BindingKey, True);

    GuardField := 'FUpdating_' + SanitizeIdentifier(ABinding.ComponentName);
    OriginalChangeField := 'FOriginal_' + SanitizeIdentifier(ABinding.ComponentName) + '_OnChange';
    OriginalPopupField := 'FOriginal_' + SanitizeIdentifier(ABinding.ComponentName) + '_OnPopup';
    OriginalClosePopupField := 'FOriginal_' + SanitizeIdentifier(ABinding.ComponentName) + '_OnClosePopup';
    SyncMethodName := SanitizeIdentifier(ABinding.ComponentName) + '_SyncFromField';
    ChangeMethodName := SanitizeIdentifier(ABinding.ComponentName) + '_GeneratedOnChange';
    PopupMethodName := SanitizeIdentifier(ABinding.ComponentName) + '_GeneratedOnPopup';
    ClosePopupMethodName := SanitizeIdentifier(ABinding.ComponentName) + '_GeneratedOnClosePopup';

    DeclarationLines.Add('    ' + GuardField + ': Integer;');
    DeclarationLines.Add('    ' + OriginalChangeField + ': TNotifyEvent;');
    DeclarationLines.Add('    ' + OriginalPopupField + ': TNotifyEvent;');
    DeclarationLines.Add('    ' + OriginalClosePopupField + ': TNotifyEvent;');
    MethodDeclarationLines.Add('    procedure ' + SyncMethodName + ';');
    MethodDeclarationLines.Add('    procedure ' + ChangeMethodName + '(Sender: TObject);');
    MethodDeclarationLines.Add('    procedure ' + PopupMethodName + '(Sender: TObject);');
    MethodDeclarationLines.Add('    procedure ' + ClosePopupMethodName + '(Sender: TObject);');

    SetupLines.Add('  if Assigned(' + ABinding.ComponentName + ') then');
    SetupLines.Add('  begin');
    SetupLines.Add('    ' + OriginalChangeField + ' := ' + ABinding.ComponentName + '.OnChange;');
    SetupLines.Add('    ' + OriginalPopupField + ' := ' + ABinding.ComponentName + '.OnPopup;');
    SetupLines.Add('    ' + OriginalClosePopupField + ' := ' + ABinding.ComponentName + '.OnClosePopup;');
    SetupLines.Add('    ' + ABinding.ComponentName + '.OnChange := ' + ChangeMethodName + ';');
    SetupLines.Add('    ' + ABinding.ComponentName + '.OnClosePopup := ' + ClosePopupMethodName + ';');
    SetupLines.Add('    ' + ABinding.ComponentName + '.OnPopup := ' + PopupMethodName + ';');
    SetupLines.Add('    ' + SyncMethodName + ';');
    SetupLines.Add('  end;');
    SetupLines.Add('');
    CleanupLines.Add('  if Assigned(' + ABinding.ComponentName + ') and (' + ABinding.ComponentName + '.Owner <> Self) then');
    CleanupLines.Add('  begin');
    CleanupLines.Add('    ' + ABinding.ComponentName + '.OnChange := ' + OriginalChangeField + ';');
    CleanupLines.Add('    ' + ABinding.ComponentName + '.OnPopup := ' + OriginalPopupField + ';');
    CleanupLines.Add('    ' + ABinding.ComponentName + '.OnClosePopup := ' + OriginalClosePopupField + ';');
    CleanupLines.Add('  end;');

    if not ComboDataChangeHandlerNames.TryGetValue(DataSourceComponent, DataSourceHandlerName) then
    begin
      DataSourceHandlerName := SanitizeIdentifier(DataSourceComponent) + '_GeneratedDataChange';
      ComboDataChangeHandlerNames.Add(DataSourceComponent, DataSourceHandlerName);
      MethodDeclarationLines.Add('    procedure ' + DataSourceHandlerName + '(Sender: TObject; Field: TField);');

      SyncMethods := TStringList.Create;
      SyncMethods.CaseSensitive := False;
      SyncMethods.Sorted := True;
      SyncMethods.Duplicates := dupIgnore;
      ComboDataChangeSyncMap.Add(DataSourceComponent, SyncMethods);

      if ABinding.OriginalProperties.TryGetValue('DataSource.OnDataChange',
           DataSourceHandlerNameValue) and (Trim(DataSourceHandlerNameValue) <> '') then
      begin
        ComboOriginalDataChangeHandlers.AddOrSetValue(DataSourceComponent,
          DataSourceHandlerNameValue);
        SetupLines.Add('  if Assigned(' + DataSourceComponent + ') then');
        SetupLines.Add('    ' + DataSourceComponent + '.OnDataChange := ' + DataSourceHandlerName + ';');
        CleanupLines.Add('  if Assigned(' + DataSourceComponent + ') and (' +
          DataSourceComponent + '.Owner <> Self) then');
        CleanupLines.Add('    ' + DataSourceComponent + '.OnDataChange := ' +
          DataSourceHandlerNameValue + ';');
      end
      else
      begin
        SetupLines.Add('  if Assigned(' + DataSourceComponent + ') and not Assigned(' +
          DataSourceComponent + '.OnDataChange) then');
        SetupLines.Add('    ' + DataSourceComponent + '.OnDataChange := ' + DataSourceHandlerName + ';');
        CleanupLines.Add('  if Assigned(' + DataSourceComponent + ') and (' +
          DataSourceComponent + '.Owner <> Self) then');
        CleanupLines.Add('    ' + DataSourceComponent + '.OnDataChange := nil;');
      end;
      SetupLines.Add('');
    end;

    SyncMethods := ComboDataChangeSyncMap[DataSourceComponent];
    if SyncMethods.IndexOf(SyncMethodName) = -1 then
      SyncMethods.Add(SyncMethodName);
  end;

  procedure EnsureGridDisplayFields(const ABinding: TDataBindingInfo);
  var
    DataSetComponent: string;
    DisplayFieldCount: Integer;
    SourceFieldName: string;
    DisplayFieldName: string;
    DisplayFieldClass: string;
    MethodName: string;
    FieldKey: string;
    DisplayCountValue: string;
    AssignmentLines: TStringList;
    NeedAssignHandler: Boolean;
    OriginalCalcFieldHandlerField: string;
    I: Integer;
  begin
    if not Assigned(ABinding) then
      Exit;
    if not ABinding.OriginalProperties.TryGetValue('DataSetComponent', DataSetComponent) then
      Exit;

    if not ABinding.OriginalProperties.TryGetValue('GridDisplayFieldCount', DisplayCountValue) then
      DisplayCountValue := '0';
    DisplayFieldCount := StrToIntDef(DisplayCountValue, 0);
    if DisplayFieldCount = 0 then
      Exit;

    NeedAssignHandler := False;
    OriginalCalcFieldHandlerField := 'FOriginal_' + SanitizeIdentifier(DataSetComponent) + '_OnCalcFields';
    if not CalcMethodNames.TryGetValue(DataSetComponent, MethodName) then
    begin
      MethodName := SanitizeIdentifier(DataSetComponent) + '_GeneratedCalcFields';
      CalcMethodNames.Add(DataSetComponent, MethodName);
      DeclarationLines.Add('    ' + OriginalCalcFieldHandlerField + ': TDataSetNotifyEvent;');
      MethodDeclarationLines.Add('    procedure ' + MethodName + '(DataSet: TDataSet);');
      AssignmentLines := TStringList.Create;
      CalcFieldAssignments.Add(DataSetComponent, AssignmentLines);
      NeedAssignHandler := True;
    end
    else
      AssignmentLines := CalcFieldAssignments[DataSetComponent];

    for I := 0 to DisplayFieldCount - 1 do
    begin
      if not ABinding.OriginalProperties.TryGetValue(
           Format('GridDisplayField%d.SourceFieldName', [I]), SourceFieldName) then
        Continue;
      if not ABinding.OriginalProperties.TryGetValue(
           Format('GridDisplayField%d.DisplayFieldName', [I]), DisplayFieldName) then
        Continue;
      if not ABinding.OriginalProperties.TryGetValue(
           Format('GridDisplayField%d.DisplayFieldClass', [I]), DisplayFieldClass) then
        DisplayFieldClass := 'TWideStringField';

      FieldKey := DataSetComponent + '|' + DisplayFieldName;
      if GeneratedDisplayFields.ContainsKey(FieldKey) then
        Continue;
      GeneratedDisplayFields.Add(FieldKey, True);

      EarlySetupLines.Add('  if ' + DataSetComponent + '.Active then');
      EarlySetupLines.Add('    ' + DataSetComponent + '.Close;');
      EarlySetupLines.Add('  if ' + DataSetComponent + '.FindField(''' + DisplayFieldName + ''') = nil then');
      EarlySetupLines.Add('  begin');
      EarlySetupLines.Add('    with ' + DisplayFieldClass + '.Create(Self) do');
      EarlySetupLines.Add('    begin');
      EarlySetupLines.Add('      FieldKind := fkInternalCalc;');
      EarlySetupLines.Add('      FieldName := ''' + DisplayFieldName + ''';');
      EarlySetupLines.Add('      Size := 8192;');
      EarlySetupLines.Add('      DataSet := ' + DataSetComponent + ';');
      EarlySetupLines.Add('    end;');
      EarlySetupLines.Add('  end;');
      EarlySetupLines.Add('');

      AssignmentLines.Add('  if (DataSet.FindField(''' + DisplayFieldName + ''') <> nil) and');
      AssignmentLines.Add('     (DataSet.FindField(''' + SourceFieldName + ''') <> nil) then');
      AssignmentLines.Add('    DataSet.FieldByName(''' + DisplayFieldName + ''').AsString :=');
      AssignmentLines.Add('      DataSet.FieldByName(''' + SourceFieldName + ''').AsString;');
    end;

    if NeedAssignHandler then
    begin
      EarlySetupLines.Add('  if Assigned(' + DataSetComponent + ') then');
      EarlySetupLines.Add('  begin');
      EarlySetupLines.Add('    ' + OriginalCalcFieldHandlerField + ' := ' + DataSetComponent + '.OnCalcFields;');
      EarlySetupLines.Add('    ' + DataSetComponent + '.OnCalcFields := ' + MethodName + ';');
      EarlySetupLines.Add('  end;');
      EarlySetupLines.Add('');
      CleanupLines.Add('  if Assigned(' + DataSetComponent + ') and (' + DataSetComponent + '.Owner <> Self) then');
      CleanupLines.Add('    ' + DataSetComponent + '.OnCalcFields := ' + OriginalCalcFieldHandlerField + ';');
    end;
  end;
begin
  if not FContext.Options.EnableDataAware then
    Exit;

  if (FDataAware.DataBindings.Count = 0) and
     not HasMediaNotifyCandidates and
     not HasToggleClickCandidates and
     not HasStartupEnterCandidates then
    Exit;

  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  DeclarationLines := TStringList.Create;
  MethodDeclarationLines := TStringList.Create;
  EarlySetupLines := TStringList.Create;
  SetupLines := TStringList.Create;
  CleanupLines := TStringList.Create;
  MethodImplementationLines := TStringList.Create;
  EarlyDestroyLines := TStringList.Create;
  BindSources := TDictionary<string, string>.Create;
  GeneratedLinks := TDictionary<string, Boolean>.Create;
  GeneratedDisplayFields := TDictionary<string, Boolean>.Create;
  CalcMethodNames := TDictionary<string, string>.Create;
  CalcFieldAssignments := TObjectDictionary<string, TStringList>.Create([doOwnsValues]);
  AfterOpenHandlerNames := TDictionary<string, string>.Create;
  OriginalAfterOpenHandlerFields := TDictionary<string, string>.Create;
  AfterOpenLinkMap := TObjectDictionary<string, TStringList>.Create([doOwnsValues]);
  ComboDataChangeHandlerNames := TDictionary<string, string>.Create;
  ComboOriginalDataChangeHandlers := TDictionary<string, string>.Create;
  ComboDataChangeSyncMap := TObjectDictionary<string, TStringList>.Create([doOwnsValues]);
  ManualFieldNavigatorHandlerNames := TDictionary<string, string>.Create;
  NavigatorOriginalBeforeActionFields := TDictionary<string, string>.Create;
  ManualFieldNavigatorCommitMap := TObjectDictionary<string, TStringList>.Create([doOwnsValues]);
  ManualFieldNavigatorSyncMap := TObjectDictionary<string, TStringList>.Create([doOwnsValues]);
  ToggleClickHandlerNames := TDictionary<string, string>.Create;
  ToggleChangeHandlerNames := TDictionary<string, string>.Create;
  EnterHandlerNames := TDictionary<string, string>.Create;
  TimerSourceOnTimerHandlers := TDictionary<string, string>.Create;
  TimerComponentNames := TStringList.Create;
  TimerHandlerNames := TStringList.Create;
  MediaNotifyPlayers := TStringList.Create;
  MediaNotifyHandlerPlayers := TStringList.Create;
  MediaNotifyEnabledPlayers := TStringList.Create;
  try
    TimerComponentNames.Sorted := True;
    TimerComponentNames.Duplicates := dupIgnore;
    TimerHandlerNames.Sorted := True;
    TimerHandlerNames.Duplicates := dupIgnore;
    MediaNotifyPlayers.Sorted := True;
    MediaNotifyPlayers.Duplicates := dupIgnore;
    MediaNotifyHandlerPlayers.Sorted := True;
    MediaNotifyHandlerPlayers.Duplicates := dupIgnore;
    MediaNotifyEnabledPlayers.Sorted := True;
    MediaNotifyEnabledPlayers.Duplicates := dupIgnore;
    CollectToggleClickCandidates;
    CollectStartupEnterCandidates;
    CollectTimerComponentNames;

    for var TogglePair in ToggleClickHandlerNames do
      Code := TRegEx.Replace(Code,
        '(^[ \t]*)' + TRegEx.Escape(TogglePair.Key) + '\.(?:IsChecked|Checked)\s*:=\s*(.+?)\s*;\s*$',
        '$1GeneratedSetToggleState_' + SanitizeIdentifier(TogglePair.Key) + '($2);',
        [roIgnoreCase, roMultiLine]);

    MediaNotifyMatches := TRegEx.Matches(Code,
      '(^[ \t]*)(?://\s*FMX manual review:\s*)?(\w*MediaPlayer\w*)\.OnNotify\s*:=\s*([A-Za-z_][A-Za-z0-9_]*)\s*;',
      [roIgnoreCase, roMultiLine]);
    for MediaNotifyMatch in MediaNotifyMatches do
    begin
      PlayerName := MediaNotifyMatch.Groups[2].Value;
      if MediaNotifyHandlerPlayers.IndexOf(PlayerName) = -1 then
        MediaNotifyHandlerPlayers.Add(PlayerName);
    end;

    MediaNotifyMatches := TRegEx.Matches(Code,
      '(^[ \t]*)(?://\s*FMX manual review:\s*)?(\w*MediaPlayer\w*)\.Notify\s*:=\s*(True|False)\s*;',
      [roIgnoreCase, roMultiLine]);
    for MediaNotifyMatch in MediaNotifyMatches do
    begin
      PlayerName := MediaNotifyMatch.Groups[2].Value;
      if MediaNotifyEnabledPlayers.IndexOf(PlayerName) = -1 then
        MediaNotifyEnabledPlayers.Add(PlayerName);
    end;

    for i := 0 to MediaNotifyHandlerPlayers.Count - 1 do
      if ShouldEmulateMediaNotify(MediaNotifyHandlerPlayers[i]) and
         (MediaNotifyPlayers.IndexOf(MediaNotifyHandlerPlayers[i]) = -1) then
        MediaNotifyPlayers.Add(MediaNotifyHandlerPlayers[i]);

    MediaNotifyMatches := TRegEx.Matches(Code,
      '(^[ \t]*)(?://\s*FMX manual review:\s*)?(\w*MediaPlayer\w*)\.OnNotify\s*:=\s*([A-Za-z_][A-Za-z0-9_]*)\s*;',
      [roIgnoreCase, roMultiLine]);
    for MediaNotifyMatch in MediaNotifyMatches do
    begin
      PlayerName := MediaNotifyMatch.Groups[2].Value;
      if ShouldEmulateMediaNotify(PlayerName) then
        Code := StringReplace(Code, MediaNotifyMatch.Value,
          MediaNotifyMatch.Groups[1].Value + 'GeneratedRegisterMediaNotify_' +
          SanitizeIdentifier(PlayerName) + '(' + MediaNotifyMatch.Groups[3].Value + ');',
          [rfReplaceAll])
      else
        Code := StringReplace(Code, MediaNotifyMatch.Value,
          MediaNotifyMatch.Groups[1].Value + '// FMX manual review: ' +
          PlayerName + '.OnNotify := ' + MediaNotifyMatch.Groups[3].Value + ';',
          [rfReplaceAll]);
    end;

    MediaNotifyMatches := TRegEx.Matches(Code,
      '(^[ \t]*)(?://\s*FMX manual review:\s*)?(\w*MediaPlayer\w*)\.Notify\s*:=\s*(True|False)\s*;',
      [roIgnoreCase, roMultiLine]);
    for MediaNotifyMatch in MediaNotifyMatches do
    begin
      PlayerName := MediaNotifyMatch.Groups[2].Value;
      if ShouldEmulateMediaNotify(PlayerName) then
        Code := StringReplace(Code, MediaNotifyMatch.Value,
          MediaNotifyMatch.Groups[1].Value + 'GeneratedSetMediaNotifyEnabled_' +
          SanitizeIdentifier(PlayerName) + '(' + MediaNotifyMatch.Groups[3].Value + ');',
          [rfReplaceAll])
      else
        Code := StringReplace(Code, MediaNotifyMatch.Value,
          MediaNotifyMatch.Groups[1].Value + '// FMX manual review: ' +
          PlayerName + '.Notify := ' + MediaNotifyMatch.Groups[3].Value + ';',
          [rfReplaceAll]);
    end;

    Lines.Text := Code;
    RewriteDeferredToggleCallsInFormShow;
    for var TimerHandlerName in TimerHandlerNames do
    begin
      EnsureGeneratedShutdownGuard;
      InsertShutdownGuardIntoMethod(TimerHandlerName);
    end;

    for Binding in FDataAware.DataBindings do
    begin
      if (Binding.ComponentName = '') or (Binding.DataSource = '') then
        Continue;
      if not SameText(Binding.DataLinkType, 'Grid') and
         not SameText(Binding.DataLinkType, 'Navigator') and
         (Binding.DataField = '') then
        Continue;

      AddBindSource(Binding.DataSource);
      if not BindSources.TryGetValue(Binding.DataSource, BindSourceField) then
        Continue;

      if SameText(Binding.DataLinkType, 'Grid') and
         not GridUsesSelectorEditors(Binding) then
      begin
        PrepareSelectorGridDisplayFields(Binding);
        EnsureGridDisplayFields(Binding);
      end;

      LinkField := 'Link_' + SanitizeIdentifier(Binding.ComponentName);
      if SameText(Binding.DataLinkType, 'Grid') then
      begin
        if GridUsesSelectorEditors(Binding) then
          AddSelectorGridEditors(Binding, BindSourceField, Binding.ComponentName)
        else
        begin
          AddLinkGridField(LinkField, BindSourceField, Binding.ComponentName, Binding);
          RegisterGridAfterOpenHandler(Binding, LinkField);
        end;
      end
      else if SameText(Binding.DataLinkType, 'Navigator') then
        AddNavigatorBinding(BindSourceField, Binding.ComponentName)
      else if SameText(Binding.DataLinkType, 'ComboText') then
        AddComboTextBinding(Binding)
      else if SameText(Binding.DataLinkType, 'Field') then
        AddManualFieldBinding(Binding)
      else if SameText(Binding.DataLinkType, 'Boolean') then
        AddLinkPropertyField(LinkField, BindSourceField, Binding.ComponentName,
          Binding.DataField, 'IsChecked')
      else if SameText(Binding.DataLinkType, 'Text') or
              SameText(Binding.DataLinkType, 'Memo') then
        AddLinkPropertyField(LinkField, BindSourceField, Binding.ComponentName,
          Binding.DataField, 'Text')
      else if SameText(Binding.DataLinkType, 'Blob') then
        AddLinkPropertyField(LinkField, BindSourceField, Binding.ComponentName,
          Binding.DataField, 'Bitmap')
      else
        AddLinkControlField(LinkField, BindSourceField, Binding.ComponentName,
          Binding.DataField);
    end;

    EmitStyledBackgroundSetup;

    if EnterHandlerNames.Count > 0 then
    begin
      EnsureGeneratedShutdownGuard;
      DeclarationLines.Add('    FGeneratedStartupEnterGuard: Boolean;');
      DeclarationLines.Add('    FGeneratedStartupEnterTimer: TTimer;');
      MethodDeclarationLines.Add('    procedure GeneratedReleaseStartupEnterGuard(Sender: TObject);');

      SetupLines.Add('  FGeneratedStartupEnterGuard := True;');
      SetupLines.Add('  if FGeneratedStartupEnterTimer = nil then');
      SetupLines.Add('  begin');
      SetupLines.Add('    FGeneratedStartupEnterTimer := TTimer.Create(Self);');
      SetupLines.Add('    FGeneratedStartupEnterTimer.Enabled := False;');
      SetupLines.Add('    FGeneratedStartupEnterTimer.Interval := 1;');
      SetupLines.Add('    FGeneratedStartupEnterTimer.OnTimer := GeneratedReleaseStartupEnterGuard;');
      SetupLines.Add('  end;');
      SetupLines.Add('  FGeneratedStartupEnterTimer.Enabled := True;');
      SetupLines.Add('');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.GeneratedReleaseStartupEnterGuard(Sender: TObject);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if FGeneratedShuttingDown then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  FGeneratedStartupEnterGuard := False;');
      MethodImplementationLines.Add('  if FGeneratedStartupEnterTimer <> nil then');
      MethodImplementationLines.Add('    FGeneratedStartupEnterTimer.Enabled := False;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');
    end;

    for var TogglePair in ToggleClickHandlerNames do
    begin
      EnsureGeneratedShutdownGuard;
      HandlerName := TogglePair.Key;
      ToggleSuppressField := 'FGeneratedToggleSuppress_' + SanitizeIdentifier(HandlerName);
      ToggleOriginalClickField := 'FGeneratedToggleOriginalClick_' + SanitizeIdentifier(HandlerName);
      ToggleOriginalChangeField := 'FGeneratedToggleOriginalChange_' + SanitizeIdentifier(HandlerName);
      ToggleSetStateMethodName := 'GeneratedSetToggleState_' + SanitizeIdentifier(HandlerName);
      ToggleChangeMethodName := HandlerName + '_GeneratedUserChange';

      DeclarationLines.Add('    ' + ToggleSuppressField + ': Integer;');
      DeclarationLines.Add('    ' + ToggleOriginalClickField + ': TNotifyEvent;');
      DeclarationLines.Add('    ' + ToggleOriginalChangeField + ': TNotifyEvent;');
      MethodDeclarationLines.Add('    procedure ' + ToggleSetStateMethodName + '(AValue: Boolean);');
      MethodDeclarationLines.Add('    procedure ' + ToggleChangeMethodName + '(Sender: TObject);');

      SetupLines.Add('  if Assigned(' + HandlerName + ') then');
      SetupLines.Add('  begin');
      SetupLines.Add('    ' + ToggleOriginalClickField + ' := ' + HandlerName + '.OnClick;');
      SetupLines.Add('    ' + ToggleOriginalChangeField + ' := ' + HandlerName + '.OnChange;');
      SetupLines.Add('    ' + HandlerName + '.OnClick := nil;');
      SetupLines.Add('    ' + HandlerName + '.OnChange := ' + ToggleChangeMethodName + ';');
      SetupLines.Add('  end;');
      SetupLines.Add('');

      CleanupLines.Add('  if Assigned(' + HandlerName + ') then');
      CleanupLines.Add('  begin');
      CleanupLines.Add('    if ' + HandlerName + '.Owner <> Self then');
      CleanupLines.Add('    begin');
      CleanupLines.Add('      ' + HandlerName + '.OnChange := ' + ToggleOriginalChangeField + ';');
      CleanupLines.Add('      ' + HandlerName + '.OnClick := ' + ToggleOriginalClickField + ';');
      CleanupLines.Add('    end');
      CleanupLines.Add('    else');
      CleanupLines.Add('    begin');
      CleanupLines.Add('      ' + HandlerName + '.OnChange := nil;');
      CleanupLines.Add('      ' + HandlerName + '.OnClick := nil;');
      CleanupLines.Add('    end;');
      CleanupLines.Add('  end;');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + ToggleSetStateMethodName + '(AValue: Boolean);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if FGeneratedShuttingDown then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if not Assigned(' + HandlerName + ') then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  Inc(' + ToggleSuppressField + ');');
      MethodImplementationLines.Add('  try');
      MethodImplementationLines.Add('    ' + HandlerName + '.IsChecked := AValue;');
      MethodImplementationLines.Add('  finally');
      MethodImplementationLines.Add('    Dec(' + ToggleSuppressField + ');');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + ToggleChangeMethodName + '(Sender: TObject);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if FGeneratedShuttingDown then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if ' + ToggleSuppressField + ' = 0 then');
      MethodImplementationLines.Add('    if Assigned(' + ToggleOriginalClickField + ') then');
      MethodImplementationLines.Add('      ' + ToggleOriginalClickField + '(Sender);');
      MethodImplementationLines.Add('  if Assigned(' + ToggleOriginalChangeField + ') then');
      MethodImplementationLines.Add('    ' + ToggleOriginalChangeField + '(Sender);');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');
    end;

    for var EnterPair in EnterHandlerNames do
    begin
      HandlerName := EnterPair.Key;
      EnterOriginalField := 'FGeneratedOriginalOnEnter_' + SanitizeIdentifier(HandlerName);
      EnterWrapperMethodName := HandlerName + '_GeneratedStartupGuardEnter';

      DeclarationLines.Add('    ' + EnterOriginalField + ': TNotifyEvent;');
      MethodDeclarationLines.Add('    procedure ' + EnterWrapperMethodName + '(Sender: TObject);');

      SetupLines.Add('  if Assigned(' + HandlerName + ') then');
      SetupLines.Add('  begin');
      SetupLines.Add('    ' + EnterOriginalField + ' := ' + HandlerName + '.OnEnter;');
      SetupLines.Add('    ' + HandlerName + '.OnEnter := ' + EnterWrapperMethodName + ';');
      SetupLines.Add('  end;');
      SetupLines.Add('');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + EnterWrapperMethodName + '(Sender: TObject);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if FGeneratedStartupEnterGuard then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if Assigned(' + EnterOriginalField + ') then');
      MethodImplementationLines.Add('    ' + EnterOriginalField + '(Sender);');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');
    end;

    for i := 0 to MediaNotifyPlayers.Count - 1 do
    begin
      EnsureGeneratedShutdownGuard;
      PlayerName := MediaNotifyPlayers[i];
      SanitizedPlayerName := SanitizeIdentifier(PlayerName);
      MediaNotifyHandlerField := 'FGeneratedMediaNotifyHandler_' + SanitizedPlayerName;
      MediaNotifyTimerField := 'FGeneratedMediaNotifyTimer_' + SanitizedPlayerName;
      MediaNotifyWasPlayingField := 'FGeneratedMediaNotifyWasPlaying_' + SanitizedPlayerName;
      MediaNotifyRegisterMethod := 'GeneratedRegisterMediaNotify_' + SanitizedPlayerName;
      MediaNotifyEnabledMethod := 'GeneratedSetMediaNotifyEnabled_' + SanitizedPlayerName;
      MediaNotifyTimerMethod := 'GeneratedMediaNotifyTimer_' + SanitizedPlayerName;

      DeclarationLines.Add('    ' + MediaNotifyHandlerField + ': TNotifyEvent;');
      DeclarationLines.Add('    ' + MediaNotifyTimerField + ': TTimer;');
      DeclarationLines.Add('    ' + MediaNotifyWasPlayingField + ': Boolean;');
      MethodDeclarationLines.Add('    procedure ' + MediaNotifyRegisterMethod + '(AHandler: TNotifyEvent);');
      MethodDeclarationLines.Add('    procedure ' + MediaNotifyEnabledMethod + '(AEnabled: Boolean);');
      MethodDeclarationLines.Add('    procedure ' + MediaNotifyTimerMethod + '(Sender: TObject);');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + MediaNotifyRegisterMethod + '(AHandler: TNotifyEvent);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if FGeneratedShuttingDown then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if ' + MediaNotifyTimerField + ' = nil then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    ' + MediaNotifyTimerField + ' := TTimer.Create(Self);');
      MethodImplementationLines.Add('    ' + MediaNotifyTimerField + '.Enabled := False;');
      MethodImplementationLines.Add('    ' + MediaNotifyTimerField + '.Interval := 200;');
      MethodImplementationLines.Add('    ' + MediaNotifyTimerField + '.OnTimer := ' + MediaNotifyTimerMethod + ';');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  ' + MediaNotifyHandlerField + ' := AHandler;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + MediaNotifyEnabledMethod + '(AEnabled: Boolean);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if FGeneratedShuttingDown then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if ' + MediaNotifyTimerField + ' = nil then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    ' + MediaNotifyTimerField + ' := TTimer.Create(Self);');
      MethodImplementationLines.Add('    ' + MediaNotifyTimerField + '.Enabled := False;');
      MethodImplementationLines.Add('    ' + MediaNotifyTimerField + '.Interval := 200;');
      MethodImplementationLines.Add('    ' + MediaNotifyTimerField + '.OnTimer := ' + MediaNotifyTimerMethod + ';');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  if not AEnabled then');
      MethodImplementationLines.Add('    ' + MediaNotifyWasPlayingField + ' := False;');
      MethodImplementationLines.Add('  ' + MediaNotifyTimerField + '.Enabled := AEnabled;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      MethodImplementationLines.Add('procedure __FORM_CLASS__.' + MediaNotifyTimerMethod + '(Sender: TObject);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  if FGeneratedShuttingDown then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if not Assigned(' + PlayerName + ') then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if ' + PlayerName + '.State = TMediaState.Playing then');
      MethodImplementationLines.Add('    ' + MediaNotifyWasPlayingField + ' := True');
      MethodImplementationLines.Add('  else if ' + MediaNotifyWasPlayingField + ' and (' + PlayerName + '.State = TMediaState.Stopped) then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    ' + MediaNotifyWasPlayingField + ' := False;');
      MethodImplementationLines.Add('    if Assigned(' + MediaNotifyHandlerField + ') then');
      MethodImplementationLines.Add('      ' + MediaNotifyHandlerField + '(' + PlayerName + ');');
      MethodImplementationLines.Add('  end');
      MethodImplementationLines.Add('  else if ' + PlayerName + '.State = TMediaState.Unavailable then');
      MethodImplementationLines.Add('    ' + MediaNotifyWasPlayingField + ' := False;');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

    end;

    for var GridPair in FGridDblClickHandlers do
    begin
      GridAdapterName := GridPair.Key;
      OriginalHandlerName := GridPair.Value;
      if EndsText('CellDblClick', GridAdapterName) then
      begin
        HandlerName := Copy(GridAdapterName, 1,
          Length(GridAdapterName) - Length('CellDblClick'));
        if HandlerName <> '' then
        begin
          EarlySetupLines.Add('  if Assigned(' + HandlerName + ') then');
          EarlySetupLines.Add('    ' + HandlerName + '.OnCellDblClick := ' +
            GridAdapterName + ';');
          EarlySetupLines.Add('');
        end;
      end;

      if not TRegEx.IsMatch(Code,
           '^\s*procedure\s+' + TRegEx.Escape(OriginalHandlerName) + '\s*\(\s*Sender\s*:\s*TObject\s*\)\s*;',
           [roIgnoreCase, roMultiLine]) and
         not TRegEx.IsMatch(Code,
           '^\s*procedure\s+[A-Za-z0-9_\.]+\.' + TRegEx.Escape(OriginalHandlerName) + '\s*\(\s*Sender\s*:\s*TObject\s*\)\s*;',
           [roIgnoreCase, roMultiLine]) then
        Continue;
      if not TRegEx.IsMatch(Code,
           '^\s*procedure\s+' + TRegEx.Escape(GridAdapterName) + '\s*\(',
           [roIgnoreCase, roMultiLine]) then
        MethodDeclarationLines.Add('    procedure ' + GridAdapterName +
          '(const Column: TColumn; const Row: Integer);');
    end;

    if (DeclarationLines.Count = 0) and (MethodDeclarationLines.Count = 0) then
      Exit;

    if ContainsText(Code, 'Generated FMX LiveBindings from original VCL data-aware controls') and
       (MethodDeclarationLines.Count = 0) then
      Exit;

    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Lines.Text);
    InsertIdx := -1;
    ClassIdx := -1;
    PrivateIdx := -1;
    FirstVisibilityIdx := -1;
    EndClassIdx := -1;
    for i := 0 to Lines.Count - 1 do
    begin
      TrimmedLine := Trim(AnalysisLines[i]);
      if TRegEx.IsMatch(TrimmedLine, '^[A-Za-z_][A-Za-z0-9_]*\s*=\s*class\s*\(', [roIgnoreCase]) then
      begin
        ClassIdx := i;
        Continue;
      end;

      if ClassIdx = -1 then
        Continue;

      if SameText(TrimmedLine, 'private') or SameText(TrimmedLine, 'strict private') then
      begin
        if PrivateIdx = -1 then
          PrivateIdx := i;
        Continue;
      end;

      if (FirstVisibilityIdx = -1) and
         (SameText(TrimmedLine, 'protected') or
          SameText(TrimmedLine, 'strict protected') or
          SameText(TrimmedLine, 'public') or
          SameText(TrimmedLine, 'published')) then
      begin
        FirstVisibilityIdx := i;
        Continue;
      end;

      if SameText(TrimmedLine, 'end;') then
      begin
        EndClassIdx := i;
        Break;
      end;
    end;

    if PrivateIdx <> -1 then
      InsertIdx := PrivateIdx + 1
    else if FirstVisibilityIdx <> -1 then
    begin
      Lines.Insert(FirstVisibilityIdx, '  private');
      InsertIdx := FirstVisibilityIdx + 1;
    end
    else if EndClassIdx <> -1 then
    begin
      Lines.Insert(EndClassIdx, '  private');
      InsertIdx := EndClassIdx + 1;
    end;

    if InsertIdx = -1 then
      Exit;

    for i := DeclarationLines.Count - 1 downto 0 do
      Lines.Insert(InsertIdx, DeclarationLines[i]);

    MethodInsertIdx := -1;
    for i := InsertIdx + DeclarationLines.Count to Lines.Count - 1 do
    begin
      TrimmedLine := Trim(Lines[i]);
      if StartsMethodDeclaration(TrimmedLine) then
      begin
        MethodInsertIdx := i;
        Break;
      end;

      if SameText(TrimmedLine, 'protected') or
         SameText(TrimmedLine, 'strict protected') or
         SameText(TrimmedLine, 'public') or
         SameText(TrimmedLine, 'published') or
         SameText(TrimmedLine, 'end;') then
      begin
        MethodInsertIdx := i;
        Break;
      end;
    end;

    if MethodInsertIdx = -1 then
      MethodInsertIdx := InsertIdx + DeclarationLines.Count;

    for i := MethodDeclarationLines.Count - 1 downto 0 do
      Lines.Insert(MethodInsertIdx, MethodDeclarationLines[i]);

    BeginIdx := -1;
    EndIdx := -1;
    SearchIdx := 0;
    while SearchIdx < Lines.Count do
    begin
      if TRegEx.IsMatch(TrimLeft(Lines[SearchIdx]),
        '^procedure\s+[A-Za-z0-9_\.]+\.FormCreate\s*\(', [roIgnoreCase]) then
      begin
        Inc(SearchIdx);
        while SearchIdx < Lines.Count do
        begin
          if SameText(Trim(Lines[SearchIdx]), 'begin') then
          begin
            BeginIdx := SearchIdx;
            Break;
          end;
          Inc(SearchIdx);
        end;
        Break;
      end;
      Inc(SearchIdx);
    end;

    if BeginIdx <> -1 then
    begin
      if EarlySetupLines.Count > 0 then
      begin
        EarlySetupLines.Insert(0, '  // Generated FMX data field preparation');
        EarlySetupLines.Insert(1, '');
        MethodInsertIdx := BeginIdx + 1;
        if (MethodInsertIdx + 2 < Lines.Count) and
           ContainsText(Lines[MethodInsertIdx], 'if FGeneratedFormCreateRan then') and
           SameText(Trim(Lines[MethodInsertIdx + 1]), 'Exit;') and
           ContainsText(Lines[MethodInsertIdx + 2], 'FGeneratedFormCreateRan := True;') then
          Inc(MethodInsertIdx, 3);
        for i := EarlySetupLines.Count - 1 downto 0 do
          Lines.Insert(MethodInsertIdx, EarlySetupLines[i]);
        if MethodInsertIdx <= BeginIdx + 1 then
          Inc(BeginIdx, EarlySetupLines.Count);
      end;

      Depth := 1;
      SearchIdx := BeginIdx + 1;
      while SearchIdx < Lines.Count do
      begin
        CleanLine := Trim(TRegEx.Replace(Lines[SearchIdx], '//.*$', ''));
        Inc(Depth, CountKeyword(CleanLine, 'begin'));
        Inc(Depth, CountKeyword(CleanLine, 'try'));
        Inc(Depth, CountKeyword(CleanLine, 'case'));
        Inc(Depth, CountKeyword(CleanLine, 'repeat'));

        if SameText(CleanLine, 'end;') or SameText(CleanLine, 'end') then
          Dec(Depth)
        else if StartsText('until ', CleanLine) then
          Dec(Depth);

        if (Depth = 0) and SameText(CleanLine, 'end;') then
        begin
          EndIdx := SearchIdx;
          Break;
        end;
        Inc(SearchIdx);
      end;
    end;

    if EndIdx <> -1 then
    begin
      SetupLines.Insert(0, '  // Generated FMX LiveBindings from original VCL data-aware controls');
      SetupLines.Insert(1, '');
      for i := SetupLines.Count - 1 downto 0 do
        Lines.Insert(EndIdx, SetupLines[i]);
    end;

    DestroyBeginIdx := -1;
    SearchIdx := 0;
    while SearchIdx < Lines.Count do
    begin
      if TRegEx.IsMatch(TrimLeft(Lines[SearchIdx]),
        '^procedure\s+[A-Za-z0-9_\.]+\.FormDestroy\s*\(', [roIgnoreCase]) then
      begin
        Inc(SearchIdx);
        while SearchIdx < Lines.Count do
        begin
          if SameText(Trim(Lines[SearchIdx]), 'begin') then
          begin
            DestroyBeginIdx := SearchIdx;
            Break;
          end;
          Inc(SearchIdx);
        end;
        Break;
      end;
      Inc(SearchIdx);
    end;

    if DestroyBeginIdx <> -1 then
    begin
      DestroyEndIdx := -1;
      SearchIdx := DestroyBeginIdx + 1;
      Depth := 1;
      while SearchIdx < Lines.Count do
      begin
        CleanLine := Trim(TRegEx.Replace(Lines[SearchIdx], '//.*$', ''));
        if CleanLine = '' then
        begin
          Inc(SearchIdx);
          Continue;
        end;

        Inc(Depth, CountKeyword(CleanLine, 'begin'));
        Inc(Depth, CountKeyword(CleanLine, 'case'));
        Inc(Depth, CountKeyword(CleanLine, 'record'));
        Inc(Depth, CountKeyword(CleanLine, 'try'));
        Inc(Depth, CountKeyword(CleanLine, 'repeat'));

        if SameText(CleanLine, 'end;') or SameText(CleanLine, 'end') then
          Dec(Depth)
        else if StartsText('until ', CleanLine) then
          Dec(Depth);

        if (Depth = 0) and SameText(CleanLine, 'end;') then
        begin
          DestroyEndIdx := SearchIdx;
          Break;
        end;
        Inc(SearchIdx);
      end;

      if DestroyEndIdx <> -1 then
      begin
        EarlyDestroyLines.Clear;
        for i := DestroyEndIdx - 1 downto DestroyBeginIdx + 1 do
          if TRegEx.IsMatch(Trim(Lines[i]),
               '^if Assigned\(([A-Za-z_][A-Za-z0-9_]*)\) then begin \1\.Clear; FreeAndNil\(\1\); end;$',
               [roIgnoreCase]) then
          begin
            EarlyDestroyLines.Insert(0, Lines[i]);
            Lines.Delete(i);
          end;

        for i := EarlyDestroyLines.Count - 1 downto 0 do
          Lines.Insert(DestroyBeginIdx + 1, EarlyDestroyLines[i]);
      end;

      if CleanupLines.Count > 0 then
      begin
        CleanupLines.Insert(0, '  // Generated FMX cleanup for bindings, timers, and media');
        CleanupLines.Insert(1, '');
        for i := CleanupLines.Count - 1 downto 0 do
          Lines.Insert(DestroyBeginIdx + 1, CleanupLines[i]);
      end;
    end;
    if (DestroyBeginIdx = -1) and (CleanupLines.Count > 0) and (BeginIdx <> -1) then
    begin
      if (InsertIdx <> -1) and not ContainsText(Lines.Text, 'FGeneratedOriginalOnDestroy: TNotifyEvent;') then
      begin
        Lines.Insert(InsertIdx, '    FGeneratedOriginalOnDestroy: TNotifyEvent;');
        if (MethodInsertIdx <> -1) and (InsertIdx <= MethodInsertIdx) then
          Inc(MethodInsertIdx);
      end;
      if (MethodInsertIdx <> -1) and not ContainsText(Lines.Text, 'procedure GeneratedFormDestroyHandler(Sender: TObject);') then
        Lines.Insert(MethodInsertIdx, '    procedure GeneratedFormDestroyHandler(Sender: TObject);');
      MethodImplementationLines.Add('procedure __FORM_CLASS__.GeneratedFormDestroyHandler(Sender: TObject);');
      MethodImplementationLines.Add('begin');
      MethodImplementationLines.Add('  // Generated FMX cleanup for bindings, timers, and media');
      MethodImplementationLines.Add('');
      for i := 0 to CleanupLines.Count - 1 do
        MethodImplementationLines.Add(CleanupLines[i]);
      MethodImplementationLines.Add('  if Assigned(FGeneratedOriginalOnDestroy) then');
      MethodImplementationLines.Add('    FGeneratedOriginalOnDestroy(Sender);');
      MethodImplementationLines.Add('end;');
      MethodImplementationLines.Add('');

      BeginIdx := -1;
      SearchIdx := 0;
      while SearchIdx < Lines.Count do
      begin
        if TRegEx.IsMatch(TrimLeft(Lines[SearchIdx]),
          '^procedure\s+[A-Za-z0-9_\.]+\.FormCreate\s*\(', [roIgnoreCase]) then
        begin
          Inc(SearchIdx);
          while SearchIdx < Lines.Count do
          begin
            if SameText(Trim(Lines[SearchIdx]), 'begin') then
            begin
              BeginIdx := SearchIdx;
              Break;
            end;
            Inc(SearchIdx);
          end;
          Break;
        end;
        Inc(SearchIdx);
      end;
      if BeginIdx <> -1 then
      begin
        Lines.Insert(BeginIdx + 1, '  FGeneratedOriginalOnDestroy := Self.OnDestroy;');
        Lines.Insert(BeginIdx + 2, '  Self.OnDestroy := GeneratedFormDestroyHandler;');
      end;
    end;

    FormClassName := ExtractFormClassName;
    if (FormClassName <> '') and
       ((MethodImplementationLines.Count > 0) or (CalcFieldAssignments.Count > 0) or (AfterOpenLinkMap.Count > 0) or
        (ComboDataChangeSyncMap.Count > 0) or (ManualFieldNavigatorHandlerNames.Count > 0) or
        (FGridDblClickHandlers.Count > 0)) then
    begin
      for i := 0 to MethodImplementationLines.Count - 1 do
        MethodImplementationLines[i] := StringReplace(MethodImplementationLines[i],
          '__FORM_CLASS__', FormClassName, [rfReplaceAll]);

      AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Lines.Text);
      FinalInsertIdx := -1;
      for i := 0 to AnalysisLines.Count - 1 do
      begin
        TrimmedLine := Trim(AnalysisLines[i]);
        if SameText(TrimmedLine, 'initialization') or
           SameText(TrimmedLine, 'finalization') then
        begin
          FinalInsertIdx := i;
          Break;
        end;
      end;

      if FinalInsertIdx = -1 then
        for i := AnalysisLines.Count - 1 downto 0 do
          if SameText(Trim(AnalysisLines[i]), 'end.') then
          begin
            FinalInsertIdx := i;
            Break;
          end;

      if FinalInsertIdx = -1 then
        FinalInsertIdx := Lines.Count;

      for Binding in FDataAware.DataBindings do
      begin
        if not SameText(Binding.DataLinkType, 'ComboText') then
          Continue;
        if not Binding.OriginalProperties.TryGetValue('DataSetComponent', ComboDataSetComponent) then
          Continue;
        if (Binding.ComponentName = '') or (Binding.DataField = '') or
           (Trim(ComboDataSetComponent) = '') then
          Continue;

        ComboSyncMethodName := SanitizeIdentifier(Binding.ComponentName) + '_SyncFromField';
        ComboChangeMethodName := SanitizeIdentifier(Binding.ComponentName) + '_GeneratedOnChange';
        ComboPopupMethodName := SanitizeIdentifier(Binding.ComponentName) + '_GeneratedOnPopup';
        ComboClosePopupMethodName := SanitizeIdentifier(Binding.ComponentName) + '_GeneratedOnClosePopup';
        ComboGuardField := 'FUpdating_' + SanitizeIdentifier(Binding.ComponentName);
        ComboOriginalChangeField := 'FOriginal_' + SanitizeIdentifier(Binding.ComponentName) + '_OnChange';
        ComboOriginalPopupField := 'FOriginal_' + SanitizeIdentifier(Binding.ComponentName) + '_OnPopup';
        ComboOriginalClosePopupField := 'FOriginal_' + SanitizeIdentifier(Binding.ComponentName) + '_OnClosePopup';

        MethodImplementationLines.Add('');
        MethodImplementationLines.Add('procedure ' + FormClassName + '.' + ComboSyncMethodName + ';');
        MethodImplementationLines.Add('var');
        MethodImplementationLines.Add('  LValue: string;');
        MethodImplementationLines.Add('  LIndex: Integer;');
        MethodImplementationLines.Add('begin');
        MethodImplementationLines.Add('  if ' + ComboGuardField + ' > 0 then');
        MethodImplementationLines.Add('    Exit;');
        MethodImplementationLines.Add('  if not Assigned(' + Binding.ComponentName + ') then');
        MethodImplementationLines.Add('    Exit;');
        MethodImplementationLines.Add('  Inc(' + ComboGuardField + ');');
        MethodImplementationLines.Add('  try');
        MethodImplementationLines.Add('    if Assigned(' + ComboDataSetComponent + ') and ' + ComboDataSetComponent + '.Active and');
        MethodImplementationLines.Add('       (' + ComboDataSetComponent + '.FindField(''' + UnquoteValue(Binding.DataField) + ''') <> nil) then');
        MethodImplementationLines.Add('      LValue := ' + ComboDataSetComponent + '.FieldByName(''' + UnquoteValue(Binding.DataField) + ''').AsString');
        MethodImplementationLines.Add('    else');
        MethodImplementationLines.Add('      LValue := '''';');
        MethodImplementationLines.Add('    if LValue = '''' then');
        MethodImplementationLines.Add('    begin');
        MethodImplementationLines.Add('      ' + Binding.ComponentName + '.ItemIndex := -1;');
        MethodImplementationLines.Add('      Exit;');
        MethodImplementationLines.Add('    end;');
        MethodImplementationLines.Add('    LIndex := ' + Binding.ComponentName + '.Items.IndexOf(LValue);');
        MethodImplementationLines.Add('    if LIndex = -1 then');
        MethodImplementationLines.Add('    begin');
        MethodImplementationLines.Add('      ' + Binding.ComponentName + '.Items.Add(LValue);');
        MethodImplementationLines.Add('      LIndex := ' + Binding.ComponentName + '.Items.IndexOf(LValue);');
        MethodImplementationLines.Add('    end;');
        MethodImplementationLines.Add('    ' + Binding.ComponentName + '.ItemIndex := LIndex;');
        MethodImplementationLines.Add('  finally');
        MethodImplementationLines.Add('    Dec(' + ComboGuardField + ');');
        MethodImplementationLines.Add('  end;');
        MethodImplementationLines.Add('end;');

        MethodImplementationLines.Add('');
        MethodImplementationLines.Add('procedure ' + FormClassName + '.' + ComboChangeMethodName + '(Sender: TObject);');
        MethodImplementationLines.Add('var');
        MethodImplementationLines.Add('  LValue: string;');
        MethodImplementationLines.Add('begin');
        MethodImplementationLines.Add('  if ' + ComboGuardField + ' > 0 then');
        MethodImplementationLines.Add('    Exit;');
        MethodImplementationLines.Add('  if Assigned(' + ComboDataSetComponent + ') and ' + ComboDataSetComponent + '.Active and');
        MethodImplementationLines.Add('     (' + ComboDataSetComponent + '.FindField(''' + UnquoteValue(Binding.DataField) + ''') <> nil) then');
        MethodImplementationLines.Add('  begin');
        MethodImplementationLines.Add('    if ' + Binding.ComponentName + '.ItemIndex >= 0 then');
        MethodImplementationLines.Add('      LValue := Trim(' + Binding.ComponentName + '.Items[' + Binding.ComponentName + '.ItemIndex])');
        MethodImplementationLines.Add('    else');
        MethodImplementationLines.Add('      LValue := Trim(' + Binding.ComponentName + '.Text);');
        MethodImplementationLines.Add('    if not (' + ComboDataSetComponent + '.State in dsEditModes) then');
        MethodImplementationLines.Add('      ' + ComboDataSetComponent + '.Edit;');
        MethodImplementationLines.Add('    if ' + ComboDataSetComponent + '.FieldByName(''' + UnquoteValue(Binding.DataField) + ''').AsString <> LValue then');
        MethodImplementationLines.Add('      ' + ComboDataSetComponent + '.FieldByName(''' + UnquoteValue(Binding.DataField) + ''').AsString := LValue;');
        MethodImplementationLines.Add('  end;');
        MethodImplementationLines.Add('  if Assigned(' + ComboOriginalChangeField + ') then');
        MethodImplementationLines.Add('    ' + ComboOriginalChangeField + '(Sender);');
        MethodImplementationLines.Add('end;');

        MethodImplementationLines.Add('');
        MethodImplementationLines.Add('procedure ' + FormClassName + '.' + ComboPopupMethodName + '(Sender: TObject);');
        MethodImplementationLines.Add('begin');
        MethodImplementationLines.Add('  Inc(' + ComboGuardField + ');');
        MethodImplementationLines.Add('  try');
        MethodImplementationLines.Add('    if Assigned(' + ComboOriginalPopupField + ') then');
        MethodImplementationLines.Add('      ' + ComboOriginalPopupField + '(Sender);');
        MethodImplementationLines.Add('  finally');
        MethodImplementationLines.Add('    Dec(' + ComboGuardField + ');');
        MethodImplementationLines.Add('  end;');
        MethodImplementationLines.Add('  ' + ComboSyncMethodName + ';');
        MethodImplementationLines.Add('end;');

        MethodImplementationLines.Add('');
        MethodImplementationLines.Add('procedure ' + FormClassName + '.' + ComboClosePopupMethodName + '(Sender: TObject);');
        MethodImplementationLines.Add('begin');
        MethodImplementationLines.Add('  ' + ComboChangeMethodName + '(Sender);');
        MethodImplementationLines.Add('  if Assigned(' + ComboOriginalClosePopupField + ') then');
        MethodImplementationLines.Add('    ' + ComboOriginalClosePopupField + '(Sender);');
        MethodImplementationLines.Add('end;');
      end;

      AppendComboDataChangeMethodImplementations(FormClassName,
        ComboDataChangeSyncMap, ComboDataChangeHandlerNames,
        ComboOriginalDataChangeHandlers, MethodImplementationLines);

      AppendNavigatorMethodImplementations(FormClassName,
        ManualFieldNavigatorHandlerNames, NavigatorOriginalBeforeActionFields,
        ManualFieldNavigatorCommitMap, ManualFieldNavigatorSyncMap,
        MethodImplementationLines);

      for var GridPair in FGridDblClickHandlers do
      begin
        GridAdapterName := GridPair.Key;
        OriginalHandlerName := GridPair.Value;
        if not TRegEx.IsMatch(Code,
             '^\s*procedure\s+' + TRegEx.Escape(OriginalHandlerName) + '\s*\(\s*Sender\s*:\s*TObject\s*\)\s*;',
             [roIgnoreCase, roMultiLine]) and
           not TRegEx.IsMatch(Code,
             '^\s*procedure\s+[A-Za-z0-9_\.]+\.' + TRegEx.Escape(OriginalHandlerName) + '\s*\(\s*Sender\s*:\s*TObject\s*\)\s*;',
             [roIgnoreCase, roMultiLine]) then
          Continue;
        if TRegEx.IsMatch(Code,
             '^\s*procedure\s+[A-Za-z0-9_\.]+\.' + TRegEx.Escape(GridAdapterName) + '\s*\(',
             [roIgnoreCase, roMultiLine]) then
          Continue;

        MethodImplementationLines.Add('');
        MethodImplementationLines.Add('procedure ' + FormClassName + '.' + GridAdapterName +
          '(const Column: TColumn; const Row: Integer);');
        MethodImplementationLines.Add('begin');
        MethodImplementationLines.Add('  ' + OriginalHandlerName + '(Self);');
        MethodImplementationLines.Add('end;');
      end;

      AppendAfterOpenMethodImplementations(FormClassName, AfterOpenLinkMap,
        AfterOpenHandlerNames, OriginalAfterOpenHandlerFields,
        MethodImplementationLines);

      AppendCalcFieldMethodImplementations(FormClassName, CalcFieldAssignments,
        CalcMethodNames, MethodImplementationLines);

      for i := MethodImplementationLines.Count - 1 downto 0 do
        Lines.Insert(FinalInsertIdx, MethodImplementationLines[i]);
    end;

    Code := Lines.Text;
    NormalizeRuntimeColors(Code);
  finally
    ManualFieldNavigatorSyncMap.Free;
    ManualFieldNavigatorCommitMap.Free;
    NavigatorOriginalBeforeActionFields.Free;
    ManualFieldNavigatorHandlerNames.Free;
    EnterHandlerNames.Free;
    ToggleChangeHandlerNames.Free;
    ToggleClickHandlerNames.Free;
    TimerSourceOnTimerHandlers.Free;
    TimerComponentNames.Free;
    TimerHandlerNames.Free;
    MediaNotifyPlayers.Free;
    MediaNotifyHandlerPlayers.Free;
    MediaNotifyEnabledPlayers.Free;
    ComboOriginalDataChangeHandlers.Free;
    ComboDataChangeSyncMap.Free;
    ComboDataChangeHandlerNames.Free;
    AfterOpenLinkMap.Free;
    OriginalAfterOpenHandlerFields.Free;
    AfterOpenHandlerNames.Free;
    CalcFieldAssignments.Free;
    CalcMethodNames.Free;
    GeneratedDisplayFields.Free;
    GeneratedLinks.Free;
    BindSources.Free;
    MethodImplementationLines.Free;
    CleanupLines.Free;
    EarlyDestroyLines.Free;
    SetupLines.Free;
    EarlySetupLines.Free;
    MethodDeclarationLines.Free;
    DeclarationLines.Free;
    AnalysisLines.Free;
    Lines.Free;
  end;
end;

end.
