{VCL2FMX (c) 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Rewrite.RuntimeNormalization;

interface

uses
  System.SysUtils,
  System.Classes,
  System.RegularExpressions,
  System.StrUtils,
  System.Generics.Collections,
  Converter.Core.Types,
  Converter.Parser.DFM;

type
  TRuntimeNormalizer = class
  private
    FContext: TConversionContext;
  public
    constructor Create(AContext: TConversionContext);
    procedure NormalizeColors(var Code: string);
    procedure RewriteTextLayoutMath(const PascalFileName: string; var Code: string);
  end;

implementation

constructor TRuntimeNormalizer.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;
end;

procedure TRuntimeNormalizer.RewriteTextLayoutMath(
  const PascalFileName: string; var Code: string);
var
  DFMFileName: string;
  DFMCode: string;
  LocalParser: TDFMParser;
  Lines: TStringList;
  LabelHeightRatios: TDictionary<string, string>;
  RewroteAny: Boolean;
  RewrittenCount: Integer;
  I: Integer;

  function FloatLiteral(const AValue: Double): string;
  var
    FS: TFormatSettings;
  begin
    FS := TFormatSettings.Create('en-US');
    Result := FloatToStrF(AValue, ffFixed, 15, 6, FS);
  end;

  function ExtractComponentClass(const AComponent: TDFMComponent): string;
  begin
    Result := '';
    if AComponent = nil then
      Exit;
    Result := Trim(AComponent.ComponentClass);
    if Result = '' then
      Result := Trim(AComponent.ObjectClass);
  end;

  function IsAutoSizedSingleLineLabel(const AComponent: TDFMComponent): Boolean;
  begin
    Result := Assigned(AComponent) and
      SameText(ExtractComponentClass(AComponent), 'TLabel') and
      not SameText(AComponent.GetPropertyValue('AutoSize', 'True'), 'False') and
      not SameText(AComponent.GetPropertyValue('WordWrap', 'False'), 'True');
  end;

  procedure CollectLabelHeightRatios(const Items: TObjectList<TDFMComponent>;
    const AInheritedFontHeight: Integer);
  var
    Comp: TDFMComponent;
    ChildFontHeight: Integer;
    ControlHeight: Integer;
    FontHeightPixels: Integer;
    FontSizePoints: Double;
    HeightRatio: Double;
    ParentFontValue: string;
  begin
    if Items = nil then
      Exit;

    for Comp in Items do
    begin
      if not Assigned(Comp) then
        Continue;

      ChildFontHeight := AInheritedFontHeight;
      ParentFontValue := Trim(Comp.GetPropertyValue('ParentFont', 'True'));
      if SameText(ParentFontValue, 'False') then
        ChildFontHeight := 0;

      if Comp.Properties.ContainsKey('Font.Height') then
        ChildFontHeight := Abs(StrToIntDef(Comp.GetPropertyValue('Font.Height', '0'), 0));

      if IsAutoSizedSingleLineLabel(Comp) and (Trim(Comp.Name) <> '') then
      begin
        ControlHeight := StrToIntDef(Comp.GetPropertyValue('Height', '0'), 0);
        FontHeightPixels := ChildFontHeight;
        if (ControlHeight > 0) and (FontHeightPixels > 0) then
        begin
          FontSizePoints := FontHeightPixels * 72 / 96;
          if FontSizePoints > 0 then
          begin
            HeightRatio := ControlHeight / FontSizePoints;
            LabelHeightRatios.AddOrSetValue(Comp.Name, FloatLiteral(HeightRatio));
          end;
        end;
      end;

      CollectLabelHeightRatios(Comp.Children, ChildFontHeight);
      CollectLabelHeightRatios(Comp.CollectionItems, ChildFontHeight);
    end;
  end;

  function EnsureLayoutHelperPresent: Boolean;
  const
    HelperName = 'GeneratedGetVclTextLayoutHeight';
  var
    HelperCode: string;
  begin
    if ContainsText(Code, 'function ' + HelperName + '(') then
      Exit(True);

    HelperCode :=
      'function ' + HelperName + '(ATarget: TObject; const ADesignHeightRatio: Single): Single;' + sLineBreak +
      'var' + sLineBreak +
      '  LLabel: TLabel;' + sLineBreak +
      '  LTextSettings: ITextSettings;' + sLineBreak +
      '  LDesiredHeight: Single;' + sLineBreak +
      'begin' + sLineBreak +
      '  Result := 0;' + sLineBreak +
      '  if not (ATarget is TLabel) then' + sLineBreak +
      '    Exit;' + sLineBreak +
      '  LLabel := TLabel(ATarget);' + sLineBreak +
      '  Result := LLabel.Height;' + sLineBreak +
      '  if (ADesignHeightRatio <= 0) or not LLabel.AutoSize or LLabel.WordWrap then' + sLineBreak +
      '    Exit;' + sLineBreak +
      '  if Supports(LLabel, ITextSettings, LTextSettings) then' + sLineBreak +
      '  begin' + sLineBreak +
      '    LDesiredHeight := LTextSettings.TextSettings.Font.Size * ADesignHeightRatio;' + sLineBreak +
      '    if Result < LDesiredHeight then' + sLineBreak +
      '      Result := LDesiredHeight;' + sLineBreak +
      '  end;' + sLineBreak +
      'end;' + sLineBreak + sLineBreak;

    if TRegEx.IsMatch(Code, '\{\$R\s+\*\.(?:dfm|fmx)\}', [roIgnoreCase]) then
      Code := TRegEx.Replace(Code,
        '(\{\$R\s+\*\.(?:dfm|fmx)\}\s*)',
        '$1' + sLineBreak + HelperCode,
        [roIgnoreCase])
    else
      Code := TRegEx.Replace(Code,
        '(\bimplementation\b\s*)',
        '$1' + sLineBreak + HelperCode,
        [roIgnoreCase]);

    Result := ContainsText(Code, 'function ' + HelperName + '(');
  end;

  function IsVerticalLayoutAssignment(const S: string): Boolean;
  var
    AssignPos: Integer;
    LHS: string;
  begin
    Result := False;
    AssignPos := Pos(':=', S);
    if AssignPos <= 0 then
      Exit;
    LHS := Trim(Copy(S, 1, AssignPos - 1));
    Result := EndsText('.Position.Y', LHS) or EndsText('.Top', LHS);
  end;

  function RewriteLineHeightReferences(const S: string; var AChanged: Boolean): string;
  var
    Pair: TPair<string, string>;
    Pattern: string;
  begin
    Result := S;
    AChanged := False;
    for Pair in LabelHeightRatios do
    begin
      Pattern := '\b' + TRegEx.Escape(Pair.Key) + '\.Height\b';
      if TRegEx.IsMatch(Result, Pattern, [roIgnoreCase]) then
      begin
        Result := TRegEx.Replace(Result, Pattern,
          'GeneratedGetVclTextLayoutHeight(' + Pair.Key + ', ' + Pair.Value + ')',
          [roIgnoreCase]);
        AChanged := True;
      end;
    end;
  end;

var
  LineChanged: Boolean;
begin
  DFMFileName := ChangeFileExt(PascalFileName, '.dfm');
  if not FileExists(DFMFileName) then
    Exit;

  LocalParser := TDFMParser.Create(FContext);
  Lines := TStringList.Create;
  LabelHeightRatios := TDictionary<string, string>.Create;
  try
    DFMCode := LocalParser.LoadDFM(DFMFileName);
    if DFMCode = '' then
      Exit;

    LocalParser.Parse(DFMCode);
    CollectLabelHeightRatios(LocalParser.Components, 0);
    if LabelHeightRatios.Count = 0 then
      Exit;

    Lines.Text := Code;
    RewroteAny := False;
    RewrittenCount := 0;

    for I := 0 to Lines.Count - 1 do
    begin
      if not IsVerticalLayoutAssignment(Lines[I]) then
        Continue;
      Lines[I] := RewriteLineHeightReferences(Lines[I], LineChanged);
      if LineChanged then
      begin
        RewroteAny := True;
        Inc(RewrittenCount);
      end;
    end;

    if not RewroteAny then
      Exit;

    Code := Lines.Text;
    if EnsureLayoutHelperPresent then
      FContext.AddIssue(csInfo,
        Format('Rewrote %d VCL-style text layout height reference(s) in %s',
          [RewrittenCount, ExtractFileName(PascalFileName)]));
  finally
    LabelHeightRatios.Free;
    Lines.Free;
    LocalParser.Free;
  end;
end;

procedure TRuntimeNormalizer.NormalizeColors(var Code: string);
const
  BaseRuntimeColorHelperCode =
    'function VCLColorToAlphaColor(Color: Cardinal): TAlphaColor;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := TAlphaColor($FF000000 or ((Color and $000000FF) shl 16) or' + sLineBreak +
    '    (Color and $0000FF00) or ((Color and $00FF0000) shr 16));' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function AlphaColorToVCLColor(Color: TAlphaColor): Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := Integer(((Color and $00FF0000) shr 16) or (Color and $0000FF00) or' + sLineBreak +
    '    ((Color and $000000FF) shl 16));' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  StatusBarHelperCode =
    'function FindNamedChild(const Root: TFmxObject; const AName: string): TFmxObject;' + sLineBreak +
    'var' + sLineBreak +
    '  I: Integer;' + sLineBreak +
    '  Child: TFmxObject;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := nil;' + sLineBreak +
    '  if Root = nil then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if SameText(Root.Name, AName) then' + sLineBreak +
    '    Exit(Root);' + sLineBreak +
    '  for I := 0 to Root.ChildrenCount - 1 do' + sLineBreak +
    '  begin' + sLineBreak +
    '    Child := FindNamedChild(Root.Children[I], AName);' + sLineBreak +
    '    if Child <> nil then' + sLineBreak +
    '      Exit(Child);' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure SetStatusBarPanelText(const AStatusBar: TStatusBar; const AIndex: Integer; const AText: string);' + sLineBreak +
    'var' + sLineBreak +
    '  Obj: TFmxObject;' + sLineBreak +
    'begin' + sLineBreak +
    '  if AStatusBar = nil then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  Obj := FindNamedChild(AStatusBar, AStatusBar.Name + ''Panel'' + IntToStr(AIndex));' + sLineBreak +
    '  if Obj is TLabel then' + sLineBreak +
    '    TLabel(Obj).Text := AText;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GetStatusBarPanelText(const AStatusBar: TStatusBar; const AIndex: Integer): string;' + sLineBreak +
    'var' + sLineBreak +
    '  Obj: TFmxObject;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := '''';' + sLineBreak +
    '  if AStatusBar = nil then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  Obj := FindNamedChild(AStatusBar, AStatusBar.Name + ''Panel'' + IntToStr(AIndex));' + sLineBreak +
    '  if Obj is TLabel then' + sLineBreak +
    '    Result := TLabel(Obj).Text;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  AlphaBlendHelperCode =
    'function GeneratedAlphaBlendValueToOpacity(const AValue: Integer): Single;' + sLineBreak +
    'begin' + sLineBreak +
    '  if AValue <= 0 then' + sLineBreak +
    '    Result := 0' + sLineBreak +
    '  else if AValue >= 255 then' + sLineBreak +
    '    Result := 1' + sLineBreak +
    '  else' + sLineBreak +
    '    Result := AValue / 255;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedSetAlphaBlendValue(const ATarget: TObject; const AValue: Integer);' + sLineBreak +
    'var' + sLineBreak +
    '  LForm: TCustomForm;' + sLineBreak +
    '  LControl: TControl;' + sLineBreak +
    '  LAlpha: Integer;' + sLineBreak +
    '  LBaseColor: TAlphaColor;' + sLineBreak +
    'begin' + sLineBreak +
    '  if AValue <= 0 then' + sLineBreak +
    '    LAlpha := 0' + sLineBreak +
    '  else if AValue >= 255 then' + sLineBreak +
    '    LAlpha := 255' + sLineBreak +
    '  else' + sLineBreak +
    '    LAlpha := AValue;' + sLineBreak +
    '  if ATarget is TCustomForm then' + sLineBreak +
    '  begin' + sLineBreak +
    '    LForm := TCustomForm(ATarget);' + sLineBreak +
    '    LForm.Transparency := True;' + sLineBreak +
    '    LForm.Fill.Kind := TBrushKind.Solid;' + sLineBreak +
    '    LBaseColor := TAlphaColor(Cardinal(LForm.Fill.Color) and $00FFFFFF);' + sLineBreak +
    '    LForm.Fill.Color := TAlphaColor((Cardinal(LAlpha) shl 24) or (Cardinal(LBaseColor) and $00FFFFFF));' + sLineBreak +
    '  end' + sLineBreak +
    '  else if ATarget is TControl then' + sLineBreak +
    '  begin' + sLineBreak +
    '    LControl := TControl(ATarget);' + sLineBreak +
    '    LControl.Opacity := GeneratedAlphaBlendValueToOpacity(LAlpha);' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  StyledBackgroundHelperCode =
    'procedure ApplyStyledBackgroundColor(const Target: TFmxObject; const Color: TAlphaColor; const SuppressBackground: Boolean = False);' + sLineBreak +
    'var' + sLineBreak +
    '  Styled: TStyledControl;' + sLineBreak +
    '  StyleObj: TFmxObject;' + sLineBreak +
    '  procedure ApplyBackgroundToStyleTree(const Node: TFmxObject);' + sLineBreak +
    '  var' + sLineBreak +
    '    J: Integer;' + sLineBreak +
    '    TintObj: ITintedObject;' + sLineBreak +
    '  begin' + sLineBreak +
    '    if Node = nil then' + sLineBreak +
    '      Exit;' + sLineBreak +
    '    if Supports(Node, ITintedObject, TintObj) then' + sLineBreak +
    '      TintObj.TintColor := Color;' + sLineBreak +
    '    if Node is TShape then' + sLineBreak +
    '      TShape(Node).Fill.Color := Color;' + sLineBreak +
    '    for J := 0 to Node.ChildrenCount - 1 do' + sLineBreak +
    '      ApplyBackgroundToStyleTree(Node.Children[J]);' + sLineBreak +
    '  end;' + sLineBreak +
    'begin' + sLineBreak +
    '  if Target = nil then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if not (Target is TStyledControl) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if not ((Target is TPanel) or (Target is TGroupBox) or (Target is TStatusBar) or (Target is TToolBar)) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  Styled := TStyledControl(Target);' + sLineBreak +
    '  Styled.ApplyStyleLookup;' + sLineBreak +
    '  Styled.StylesData[''background.Visible''] := TValue.From<Boolean>(not SuppressBackground);' + sLineBreak +
    '  Styled.StylesData[''background.Fill.Color''] := TValue.From<TAlphaColor>(Color);' + sLineBreak +
    '  Styled.StylesData[''background.Stroke.Color''] := TValue.From<TAlphaColor>(Color);' + sLineBreak +
    '  StyleObj := nil;' + sLineBreak +
    '  if Styled.FindStyleResource<TFmxObject>(''background'', StyleObj) then' + sLineBreak +
    '    ApplyBackgroundToStyleTree(StyleObj);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure ApplyContainerBackgroundColor(const Root: TFmxObject; const Color: TAlphaColor);' + sLineBreak +
    'var' + sLineBreak +
    '  I: Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  if Root = nil then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if (Root is TPanel) and (TPanel(Root).Align = TAlignLayout.Client) then' + sLineBreak +
    '    ApplyStyledBackgroundColor(Root, Color, True)' + sLineBreak +
    '  else' + sLineBreak +
    '    ApplyStyledBackgroundColor(Root, Color, False);' + sLineBreak +
    '  for I := 0 to Root.ChildrenCount - 1 do' + sLineBreak +
    '    ApplyContainerBackgroundColor(Root.Children[I], Color);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  GridSelectionHelperCode =
    'procedure ApplyGridSelectionColor(const AGrid: TFmxObject; const Color: TAlphaColor);' + sLineBreak +
    'var' + sLineBreak +
    '  Styled: TStyledControl;' + sLineBreak +
    '  StyleObj: TFmxObject;' + sLineBreak +
    '  procedure ApplySelectionToStyleTree(const Node: TFmxObject);' + sLineBreak +
    '  var' + sLineBreak +
    '    J: Integer;' + sLineBreak +
    '    TintObj: ITintedObject;' + sLineBreak +
    '  begin' + sLineBreak +
    '    if Node = nil then' + sLineBreak +
    '      Exit;' + sLineBreak +
    '    if Supports(Node, ITintedObject, TintObj) then' + sLineBreak +
    '      TintObj.TintColor := Color;' + sLineBreak +
    '    if Node is TShape then' + sLineBreak +
    '    begin' + sLineBreak +
    '      TShape(Node).Fill.Color := Color;' + sLineBreak +
    '      TShape(Node).Stroke.Color := Color;' + sLineBreak +
    '    end;' + sLineBreak +
    '    for J := 0 to Node.ChildrenCount - 1 do' + sLineBreak +
    '      ApplySelectionToStyleTree(Node.Children[J]);' + sLineBreak +
    '  end;' + sLineBreak +
    'begin' + sLineBreak +
    '  if not (AGrid is TStyledControl) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  Styled := TStyledControl(AGrid);' + sLineBreak +
    '  Styled.ApplyStyleLookup;' + sLineBreak +
    '  Styled.StylesData[''selection.Fill.Color''] := TValue.From<TAlphaColor>(Color);' + sLineBreak +
    '  Styled.StylesData[''selection.Stroke.Color''] := TValue.From<TAlphaColor>(Color);' + sLineBreak +
    '  Styled.StylesData[''focus.Fill.Color''] := TValue.From<TAlphaColor>(Color);' + sLineBreak +
    '  Styled.StylesData[''focus.Stroke.Color''] := TValue.From<TAlphaColor>(Color);' + sLineBreak +
    '  StyleObj := nil;' + sLineBreak +
    '  if Styled.FindStyleResource<TFmxObject>(''selection'', StyleObj) then' + sLineBreak +
    '    ApplySelectionToStyleTree(StyleObj);' + sLineBreak +
    '  StyleObj := nil;' + sLineBreak +
    '  if Styled.FindStyleResource<TFmxObject>(''focus'', StyleObj) then' + sLineBreak +
    '    ApplySelectionToStyleTree(StyleObj);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;
  ManualFieldHelperCode =
    'type' + sLineBreak +
    '  TGeneratedManualFieldBinding = class' + sLineBreak +
    '  public' + sLineBreak +
    '    Control: TCustomEdit;' + sLineBreak +
    '    Owner: TComponent;' + sLineBreak +
    '    DataSet: TDataSet;' + sLineBreak +
    '    FieldName: string;' + sLineBreak +
    '    OriginalChangeTracking: TNotifyEvent;' + sLineBreak +
    '    OriginalExit: TNotifyEvent;' + sLineBreak +
    '    OriginalKeyDown: TKeyEvent;' + sLineBreak +
    '    Guard: Integer;' + sLineBreak +
    '  end;' + sLineBreak + sLineBreak +
    '  TGeneratedManualFieldBindingHandler = class' + sLineBreak +
    '  public' + sLineBreak +
    '    procedure GeneratedManualFieldChangeTracking(Sender: TObject);' + sLineBreak +
    '    procedure GeneratedManualFieldExit(Sender: TObject);' + sLineBreak +
    '    procedure GeneratedManualFieldKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);' + sLineBreak +
    '  end;' + sLineBreak + sLineBreak +
    'var' + sLineBreak +
    '  GeneratedManualFieldBindingList: TObjectList<TGeneratedManualFieldBinding>;' + sLineBreak +
    '  GeneratedManualFieldBindingMap: TObjectDictionary<TObject, TGeneratedManualFieldBinding>;' + sLineBreak +
    '  GeneratedManualFieldBindingHandler: TGeneratedManualFieldBindingHandler;' + sLineBreak + sLineBreak +
    'procedure GeneratedEnsureManualFieldBindingInfra;' + sLineBreak +
    'begin' + sLineBreak +
    '  if GeneratedManualFieldBindingList = nil then' + sLineBreak +
    '    GeneratedManualFieldBindingList := TObjectList<TGeneratedManualFieldBinding>.Create(True);' + sLineBreak +
    '  if GeneratedManualFieldBindingMap = nil then' + sLineBreak +
    '    GeneratedManualFieldBindingMap := TObjectDictionary<TObject, TGeneratedManualFieldBinding>.Create;' + sLineBreak +
    '  if GeneratedManualFieldBindingHandler = nil then' + sLineBreak +
    '    GeneratedManualFieldBindingHandler := TGeneratedManualFieldBindingHandler.Create;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GeneratedFindManualFieldBinding(const AControl: TObject): TGeneratedManualFieldBinding;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := nil;' + sLineBreak +
    '  if (GeneratedManualFieldBindingMap <> nil) and (AControl <> nil) then' + sLineBreak +
    '    GeneratedManualFieldBindingMap.TryGetValue(AControl, Result);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GeneratedGetManualFieldDisplayText(AControl: TCustomEdit): string;' + sLineBreak +
    'var' + sLineBreak +
    '  Binding: TGeneratedManualFieldBinding;' + sLineBreak +
    '  LField: TField;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := '''';' + sLineBreak +
    '  if AControl = nil then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  Result := AControl.Text;' + sLineBreak +
    '  Binding := GeneratedFindManualFieldBinding(AControl);' + sLineBreak +
    '  if (Binding = nil) or not Assigned(Binding.DataSet) or not Binding.DataSet.Active or Binding.DataSet.IsEmpty then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  LField := Binding.DataSet.FindField(Binding.FieldName);' + sLineBreak +
    '  if LField <> nil then' + sLineBreak +
    '    Result := LField.DisplayText;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GeneratedTryParseBoundDate(const AInput: string; out AValue: TDateTime): Boolean;' + sLineBreak +
    'var' + sLineBreak +
    '  LText: string;' + sLineBreak +
    '  FS: TFormatSettings;' + sLineBreak +
    '  Parts: TArray<string>;' + sLineBreak +
    '  A, B, C: Integer;' + sLineBreak +
    '  Y, M, D: Word;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := False;' + sLineBreak +
    '  AValue := 0;' + sLineBreak +
    '  LText := Trim(AInput);' + sLineBreak +
    '  if LText = '''' then' + sLineBreak +
    '    Exit(False);' + sLineBreak +
    '  FS := TFormatSettings.Create;' + sLineBreak +
    '  if TryStrToDate(LText, AValue, FS) or TryStrToDateTime(LText, AValue, FS) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    AValue := Trunc(AValue);' + sLineBreak +
    '    Exit(True);' + sLineBreak +
    '  end;' + sLineBreak +
    '  LText := StringReplace(LText, ''-'', ''/'', [rfReplaceAll]);' + sLineBreak +
    '  LText := StringReplace(LText, ''.'', ''/'', [rfReplaceAll]);' + sLineBreak +
    '  Parts := LText.Split([''/'']);' + sLineBreak +
    '  if Length(Parts) <> 3 then' + sLineBreak +
    '    Exit(False);' + sLineBreak +
    '  if not TryStrToInt(Trim(Parts[0]), A) then' + sLineBreak +
    '    Exit(False);' + sLineBreak +
    '  if not TryStrToInt(Trim(Parts[1]), B) then' + sLineBreak +
    '    Exit(False);' + sLineBreak +
    '  if not TryStrToInt(Trim(Parts[2]), C) then' + sLineBreak +
    '    Exit(False);' + sLineBreak +
    '  if Length(Trim(Parts[0])) = 4 then' + sLineBreak +
    '  begin' + sLineBreak +
    '    Y := A; M := B; D := C;' + sLineBreak +
    '  end' + sLineBreak +
    '  else' + sLineBreak +
    '  begin' + sLineBreak +
    '    Y := C;' + sLineBreak +
    '    if Y < 100 then' + sLineBreak +
    '      if Y < 50 then Inc(Y, 2000) else Inc(Y, 1900);' + sLineBreak +
    '    if A > 12 then' + sLineBreak +
    '    begin' + sLineBreak +
    '      D := A; M := B;' + sLineBreak +
    '    end' + sLineBreak +
    '    else if B > 12 then' + sLineBreak +
    '    begin' + sLineBreak +
    '      M := A; D := B;' + sLineBreak +
    '    end' + sLineBreak +
    '    else' + sLineBreak +
    '    begin' + sLineBreak +
    '      M := A; D := B;' + sLineBreak +
    '    end;' + sLineBreak +
    '  end;' + sLineBreak +
    '  try' + sLineBreak +
    '    AValue := EncodeDate(Y, M, D);' + sLineBreak +
    '    Result := True;' + sLineBreak +
    '  except' + sLineBreak +
    '    Result := False;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GeneratedTryParseBoundTime(const AInput: string; out AValue: TDateTime): Boolean;' + sLineBreak +
    'var' + sLineBreak +
    '  LText: string;' + sLineBreak +
    '  FS: TFormatSettings;' + sLineBreak +
    '  Hours: Integer;' + sLineBreak +
    '  Minutes: Integer;' + sLineBreak +
    '  Seconds: Integer;' + sLineBreak +
    '  Parts: TArray<string>;' + sLineBreak +
    '  Suffix: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := False;' + sLineBreak +
    '  AValue := 0;' + sLineBreak +
    '  LText := UpperCase(Trim(AInput));' + sLineBreak +
    '  if LText = '''' then' + sLineBreak +
    '    Exit(False);' + sLineBreak +
    '  FS := TFormatSettings.Create;' + sLineBreak +
    '  if TryStrToTime(LText, AValue, FS) or TryStrToDateTime(LText, AValue, FS) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    AValue := Frac(AValue);' + sLineBreak +
    '    Exit(True);' + sLineBreak +
    '  end;' + sLineBreak +
    '  LText := StringReplace(LText, ''.'', '':'', [rfReplaceAll]);' + sLineBreak +
    '  while Pos(''  '', LText) > 0 do' + sLineBreak +
    '    LText := StringReplace(LText, ''  '', '' '', [rfReplaceAll]);' + sLineBreak +
    '  Suffix := '''';' + sLineBreak +
    '  if Length(LText) >= 2 then' + sLineBreak +
    '  begin' + sLineBreak +
    '    if SameText(Copy(LText, Length(LText) - 1, 2), ''AM'') or' + sLineBreak +
    '       SameText(Copy(LText, Length(LText) - 1, 2), ''PM'') then' + sLineBreak +
    '    begin' + sLineBreak +
    '      Suffix := Copy(LText, Length(LText) - 1, 2);' + sLineBreak +
    '      Delete(LText, Length(LText) - 1, 2);' + sLineBreak +
    '      LText := Trim(LText);' + sLineBreak +
    '    end;' + sLineBreak +
    '  end;' + sLineBreak +
    '  Hours := 0;' + sLineBreak +
    '  Minutes := 0;' + sLineBreak +
    '  Seconds := 0;' + sLineBreak +
    '  if Pos('':'', LText) = 0 then' + sLineBreak +
    '  begin' + sLineBreak +
    '    if (Suffix = '''') and (Length(LText) in [3, 4]) then' + sLineBreak +
    '    begin' + sLineBreak +
    '      if not TryStrToInt(Copy(LText, 1, Length(LText) - 2), Hours) then' + sLineBreak +
    '        Exit(False);' + sLineBreak +
    '      if not TryStrToInt(Copy(LText, Length(LText) - 1, 2), Minutes) then' + sLineBreak +
    '        Exit(False);' + sLineBreak +
    '    end' + sLineBreak +
    '    else' + sLineBreak +
    '    begin' + sLineBreak +
    '      if not TryStrToInt(LText, Hours) then' + sLineBreak +
    '        Exit(False);' + sLineBreak +
    '    end;' + sLineBreak +
    '  end' + sLineBreak +
    '  else' + sLineBreak +
    '  begin' + sLineBreak +
    '    Parts := LText.Split(['':'']);' + sLineBreak +
    '    if (Length(Parts) < 2) or (Length(Parts) > 3) then' + sLineBreak +
    '      Exit(False);' + sLineBreak +
    '    if not TryStrToInt(Trim(Parts[0]), Hours) then' + sLineBreak +
    '      Exit(False);' + sLineBreak +
    '    if not TryStrToInt(Trim(Parts[1]), Minutes) then' + sLineBreak +
    '      Exit(False);' + sLineBreak +
    '    if Length(Parts) = 3 then' + sLineBreak +
    '      if not TryStrToInt(Trim(Parts[2]), Seconds) then' + sLineBreak +
    '        Exit(False);' + sLineBreak +
    '  end;' + sLineBreak +
    '  if (Minutes < 0) or (Minutes > 59) or (Seconds < 0) or (Seconds > 59) then' + sLineBreak +
    '    Exit(False);' + sLineBreak +
    '  if Suffix = ''AM'' then' + sLineBreak +
    '  begin' + sLineBreak +
    '    if (Hours < 1) or (Hours > 12) then' + sLineBreak +
    '      Exit(False);' + sLineBreak +
    '    if Hours = 12 then' + sLineBreak +
    '      Hours := 0;' + sLineBreak +
    '  end' + sLineBreak +
    '  else if Suffix = ''PM'' then' + sLineBreak +
    '  begin' + sLineBreak +
    '    if (Hours < 1) or (Hours > 12) then' + sLineBreak +
    '      Exit(False);' + sLineBreak +
    '    if Hours < 12 then' + sLineBreak +
    '      Inc(Hours, 12);' + sLineBreak +
    '  end' + sLineBreak +
    '  else if (Hours < 0) or (Hours > 23) then' + sLineBreak +
    '    Exit(False);' + sLineBreak +
    '  try' + sLineBreak +
    '    AValue := EncodeTime(Hours, Minutes, Seconds, 0);' + sLineBreak +
    '    Result := True;' + sLineBreak +
    '  except' + sLineBreak +
    '    Result := False;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'function GeneratedAssignBoundFieldValue(AField: TField; const AInput: string; out ANormalized: string; out AError: string): Boolean;' + sLineBreak +
    'var' + sLineBreak +
    '  LValue: string;' + sLineBreak +
    '  LDateTime: TDateTime;' + sLineBreak +
    '  LFieldName: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := False;' + sLineBreak +
    '  ANormalized := '''';' + sLineBreak +
    '  AError := '''';' + sLineBreak +
    '  if AField = nil then' + sLineBreak +
    '    Exit(False);' + sLineBreak +
    '  LValue := Trim(AInput);' + sLineBreak +
    '  if LValue = '''' then' + sLineBreak +
    '  begin' + sLineBreak +
    '    AField.Clear;' + sLineBreak +
    '    ANormalized := '''';' + sLineBreak +
    '    Exit(True);' + sLineBreak +
    '  end;' + sLineBreak +
    '  if Assigned(AField.OnSetText) or Assigned(AField.OnGetText) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    try' + sLineBreak +
    '      AField.Text := LValue;' + sLineBreak +
    '      ANormalized := AField.DisplayText;' + sLineBreak +
    '      Exit(True);' + sLineBreak +
    '    except' + sLineBreak +
    '      on E: Exception do' + sLineBreak +
    '      begin' + sLineBreak +
    '        AError := E.Message;' + sLineBreak +
    '        Exit(False);' + sLineBreak +
    '      end;' + sLineBreak +
    '    end;' + sLineBreak +
    '  end;' + sLineBreak +
    '  LFieldName := UpperCase(AField.FieldName);' + sLineBreak +
    '  if (AField.DataType = ftTime) or' + sLineBreak +
    '     (((AField.DataType in [ftUnknown, ftString, ftWideString, ftMemo, ftWideMemo, ftFmtMemo, ftFixedChar, ftFixedWideChar]) and' + sLineBreak +
    '       ((Pos(''_TIME'', LFieldName) > 0) or (Pos(''TIME_'', LFieldName) > 0) or (Pos(''PLAY_TIME'', LFieldName) > 0) or (Pos(''SCHEDULED_TIME'', LFieldName) > 0))) and' + sLineBreak +
    '      (Pos(''DATE'', LFieldName) = 0)) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    if not GeneratedTryParseBoundTime(LValue, LDateTime) then' + sLineBreak +
    '    begin' + sLineBreak +
    '      AError := ''"'' + AInput + ''" is not a valid time.'';' + sLineBreak +
    '      Exit(False);' + sLineBreak +
    '    end;' + sLineBreak +
    '    AField.AsDateTime := LDateTime;' + sLineBreak +
    '    ANormalized := AField.DisplayText;' + sLineBreak +
    '    Exit(True);' + sLineBreak +
    '  end;' + sLineBreak +
    '  if (AField.DataType in [ftDate, ftDateTime, ftTimeStamp]) or' + sLineBreak +
    '     ((AField.DataType in [ftUnknown, ftString, ftWideString, ftMemo, ftWideMemo, ftFmtMemo, ftFixedChar, ftFixedWideChar]) and' + sLineBreak +
    '      (Pos(''DATE'', LFieldName) > 0)) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    if not GeneratedTryParseBoundDate(LValue, LDateTime) then' + sLineBreak +
    '    begin' + sLineBreak +
    '      AError := ''"'' + AInput + ''" is not a valid date.'';' + sLineBreak +
    '      Exit(False);' + sLineBreak +
    '    end;' + sLineBreak +
    '    AField.AsDateTime := LDateTime;' + sLineBreak +
    '    ANormalized := AField.DisplayText;' + sLineBreak +
    '    Exit(True);' + sLineBreak +
    '  end;' + sLineBreak +
    '  try' + sLineBreak +
    '    AField.Text := LValue;' + sLineBreak +
    '    ANormalized := AField.DisplayText;' + sLineBreak +
    '    Result := True;' + sLineBreak +
    '  except' + sLineBreak +
    '    on E: Exception do' + sLineBreak +
    '    begin' + sLineBreak +
    '      AError := E.Message;' + sLineBreak +
    '      Result := False;' + sLineBreak +
    '    end;' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedSyncManualFieldBinding(const ABinding: TGeneratedManualFieldBinding);' + sLineBreak +
    'var' + sLineBreak +
    '  LField: TField;' + sLineBreak +
    '  LText: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  if (ABinding = nil) or (ABinding.Control = nil) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if ABinding.Guard > 0 then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if (ABinding.Owner <> nil) and (csDestroying in ABinding.Owner.ComponentState) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if csDestroying in ABinding.Control.ComponentState then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if ABinding.Control.IsFocused then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  LText := '''';' + sLineBreak +
    '  if Assigned(ABinding.DataSet) and ABinding.DataSet.Active and (not ABinding.DataSet.IsEmpty) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    LField := ABinding.DataSet.FindField(ABinding.FieldName);' + sLineBreak +
    '    if LField <> nil then' + sLineBreak +
    '      LText := LField.DisplayText;' + sLineBreak +
    '  end;' + sLineBreak +
    '  Inc(ABinding.Guard);' + sLineBreak +
    '  try' + sLineBreak +
    '    if ABinding.Control.Text <> LText then' + sLineBreak +
    '      ABinding.Control.Text := LText;' + sLineBreak +
    '  finally' + sLineBreak +
    '    Dec(ABinding.Guard);' + sLineBreak +
    '  end;' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedSyncManualFieldBindingsForDataSet(const ADataSet: TDataSet);' + sLineBreak +
    'var' + sLineBreak +
    '  Binding: TGeneratedManualFieldBinding;' + sLineBreak +
    'begin' + sLineBreak +
    '  if (ADataSet = nil) or (GeneratedManualFieldBindingList = nil) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  for Binding in GeneratedManualFieldBindingList do' + sLineBreak +
    '    if Binding.DataSet = ADataSet then' + sLineBreak +
    '      GeneratedSyncManualFieldBinding(Binding);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TGeneratedManualFieldBindingHandler.GeneratedManualFieldChangeTracking(Sender: TObject);' + sLineBreak +
    'var' + sLineBreak +
    '  Binding: TGeneratedManualFieldBinding;' + sLineBreak +
    'begin' + sLineBreak +
    '  Binding := GeneratedFindManualFieldBinding(Sender);' + sLineBreak +
    '  if (Binding = nil) or (Binding.Guard > 0) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if (Binding.Owner <> nil) and (csDestroying in Binding.Owner.ComponentState) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if (Binding.Control <> nil) and (csDestroying in Binding.Control.ComponentState) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if not Assigned(Binding.DataSet) or not Binding.DataSet.Active or Binding.DataSet.IsEmpty then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if not (Binding.DataSet.State in dsEditModes) then' + sLineBreak +
    '    Binding.DataSet.Edit;' + sLineBreak +
    '  if Assigned(Binding.OriginalChangeTracking) then' + sLineBreak +
    '    Binding.OriginalChangeTracking(Sender);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TGeneratedManualFieldBindingHandler.GeneratedManualFieldExit(Sender: TObject);' + sLineBreak +
    'var' + sLineBreak +
    '  Binding: TGeneratedManualFieldBinding;' + sLineBreak +
    '  LField: TField;' + sLineBreak +
    '  LNormalized: string;' + sLineBreak +
    '  LError: string;' + sLineBreak +
    'begin' + sLineBreak +
    '  Binding := GeneratedFindManualFieldBinding(Sender);' + sLineBreak +
    '  if (Binding = nil) or (Binding.Control = nil) or (Binding.Guard > 0) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if (Binding.Owner <> nil) and (csDestroying in Binding.Owner.ComponentState) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if csDestroying in Binding.Control.ComponentState then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if not Assigned(Binding.DataSet) or not Binding.DataSet.Active or Binding.DataSet.IsEmpty then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  LField := Binding.DataSet.FindField(Binding.FieldName);' + sLineBreak +
    '  if LField = nil then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  if not (Binding.DataSet.State in dsEditModes) then' + sLineBreak +
    '    Binding.DataSet.Edit;' + sLineBreak +
    '  if not GeneratedAssignBoundFieldValue(LField, Binding.Control.Text, LNormalized, LError) then' + sLineBreak +
    '  begin' + sLineBreak +
    '    Inc(Binding.Guard);' + sLineBreak +
    '    try' + sLineBreak +
    '      if LError <> '''' then' + sLineBreak +
    '        ShowMessage(LError);' + sLineBreak +
    '      GeneratedSyncManualFieldBinding(Binding);' + sLineBreak +
    '    finally' + sLineBreak +
    '      Dec(Binding.Guard);' + sLineBreak +
    '    end;' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  end;' + sLineBreak +
    '  Inc(Binding.Guard);' + sLineBreak +
    '  try' + sLineBreak +
    '    if Binding.Control.Text <> LNormalized then' + sLineBreak +
    '      Binding.Control.Text := LNormalized;' + sLineBreak +
    '  finally' + sLineBreak +
    '    Dec(Binding.Guard);' + sLineBreak +
    '  end;' + sLineBreak +
    '  if Assigned(Binding.OriginalExit) then' + sLineBreak +
    '    Binding.OriginalExit(Sender);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure TGeneratedManualFieldBindingHandler.GeneratedManualFieldKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);' + sLineBreak +
    'var' + sLineBreak +
    '  Binding: TGeneratedManualFieldBinding;' + sLineBreak +
    'begin' + sLineBreak +
    '  Binding := GeneratedFindManualFieldBinding(Sender);' + sLineBreak +
    '  if Key = vkReturn then' + sLineBreak +
    '  begin' + sLineBreak +
    '    GeneratedManualFieldBindingHandler.GeneratedManualFieldExit(Sender);' + sLineBreak +
    '    Key := 0;' + sLineBreak +
    '    KeyChar := #0;' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  end;' + sLineBreak +
    '  if (Binding <> nil) and Assigned(Binding.OriginalKeyDown) then' + sLineBreak +
    '    Binding.OriginalKeyDown(Sender, Key, KeyChar, Shift);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedCommitManualFieldBindingsForDataSet(const ADataSet: TDataSet);' + sLineBreak +
    'var' + sLineBreak +
    '  Binding: TGeneratedManualFieldBinding;' + sLineBreak +
    'begin' + sLineBreak +
    '  if (ADataSet = nil) or (GeneratedManualFieldBindingList = nil) then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  for Binding in GeneratedManualFieldBindingList do' + sLineBreak +
    '    if (Binding.DataSet = ADataSet) and (Binding.Control <> nil) then' + sLineBreak +
    '      GeneratedManualFieldBindingHandler.GeneratedManualFieldExit(Binding.Control);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedRegisterManualFieldBinding(AControl: TCustomEdit; ADataSet: TDataSet; const AFieldName: string);' + sLineBreak +
    'var' + sLineBreak +
    '  Binding: TGeneratedManualFieldBinding;' + sLineBreak +
    'begin' + sLineBreak +
    '  if (AControl = nil) or (ADataSet = nil) or (Trim(AFieldName) = '''') then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  GeneratedEnsureManualFieldBindingInfra;' + sLineBreak +
    '  Binding := GeneratedFindManualFieldBinding(AControl);' + sLineBreak +
    '  if Binding <> nil then' + sLineBreak +
    '    Exit;' + sLineBreak +
    '  Binding := TGeneratedManualFieldBinding.Create;' + sLineBreak +
    '  Binding.Control := AControl;' + sLineBreak +
    '  Binding.Owner := AControl.Owner;' + sLineBreak +
    '  Binding.DataSet := ADataSet;' + sLineBreak +
    '  Binding.FieldName := AFieldName;' + sLineBreak +
    '  Binding.OriginalChangeTracking := AControl.OnChangeTracking;' + sLineBreak +
    '  Binding.OriginalExit := AControl.OnExit;' + sLineBreak +
    '  Binding.OriginalKeyDown := AControl.OnKeyDown;' + sLineBreak +
    '  Binding.Guard := 0;' + sLineBreak +
    '  GeneratedManualFieldBindingList.Add(Binding);' + sLineBreak +
    '  GeneratedManualFieldBindingMap.Add(AControl, Binding);' + sLineBreak +
    '  AControl.OnChangeTracking := GeneratedManualFieldBindingHandler.GeneratedManualFieldChangeTracking;' + sLineBreak +
    '  AControl.OnExit := GeneratedManualFieldBindingHandler.GeneratedManualFieldExit;' + sLineBreak +
    '  AControl.OnKeyDown := GeneratedManualFieldBindingHandler.GeneratedManualFieldKeyDown;' + sLineBreak +
    '  GeneratedSyncManualFieldBinding(Binding);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak +
    'procedure GeneratedCleanupManualFieldBindingsForOwner(const AOwner: TComponent);' + sLineBreak +
    'var' + sLineBreak +
    '  I: Integer;' + sLineBreak +
    '  Binding: TGeneratedManualFieldBinding;' + sLineBreak +
    'begin' + sLineBreak +
    '  if GeneratedManualFieldBindingList <> nil then' + sLineBreak +
    '    for I := GeneratedManualFieldBindingList.Count - 1 downto 0 do' + sLineBreak +
    '    begin' + sLineBreak +
    '      Binding := GeneratedManualFieldBindingList[I];' + sLineBreak +
    '      if Binding <> nil then' + sLineBreak +
    '      begin' + sLineBreak +
    '        if Binding.Control <> nil then' + sLineBreak +
    '        begin' + sLineBreak +
    '          Binding.Control.OnChangeTracking := nil;' + sLineBreak +
    '          Binding.Control.OnExit := nil;' + sLineBreak +
    '          Binding.Control.OnKeyDown := nil;' + sLineBreak +
    '          if GeneratedManualFieldBindingMap <> nil then' + sLineBreak +
    '            GeneratedManualFieldBindingMap.Remove(Binding.Control);' + sLineBreak +
    '        end;' + sLineBreak +
    '        Binding.Control := nil;' + sLineBreak +
    '        Binding.Owner := nil;' + sLineBreak +
    '        Binding.DataSet := nil;' + sLineBreak +
    '        Binding.OriginalChangeTracking := nil;' + sLineBreak +
    '        Binding.OriginalExit := nil;' + sLineBreak +
    '        Binding.OriginalKeyDown := nil;' + sLineBreak +
    '        GeneratedManualFieldBindingList.Delete(I);' + sLineBreak +
    '      end;' + sLineBreak +
    '    end;' + sLineBreak +
    '  if GeneratedManualFieldBindingMap <> nil then' + sLineBreak +
    '    FreeAndNil(GeneratedManualFieldBindingMap);' + sLineBreak +
    '  if GeneratedManualFieldBindingHandler <> nil then' + sLineBreak +
    '    FreeAndNil(GeneratedManualFieldBindingHandler);' + sLineBreak +
    '  if GeneratedManualFieldBindingList <> nil then' + sLineBreak +
    '    FreeAndNil(GeneratedManualFieldBindingList);' + sLineBreak +
    'end;' + sLineBreak + sLineBreak;

  procedure ReportUnknownVclColorConstants;
  var
    Lines: TStringList;
    Reported: TDictionary<string, Boolean>;
    Matches: TMatchCollection;
    Match: TMatch;
    LineText: string;
    SymbolName: string;
    I: Integer;
    CommentPos: Integer;
    MatchPos: Integer;

    function IsKnownVclColor(const AName: string): Boolean;
    begin
      Result :=
        SameText(AName, 'clBlack') or SameText(AName, 'clMaroon') or
        SameText(AName, 'clGreen') or SameText(AName, 'clOlive') or
        SameText(AName, 'clNavy') or SameText(AName, 'clPurple') or
        SameText(AName, 'clTeal') or SameText(AName, 'clGray') or
        SameText(AName, 'clSilver') or SameText(AName, 'clRed') or
        SameText(AName, 'clLime') or SameText(AName, 'clYellow') or
        SameText(AName, 'clBlue') or SameText(AName, 'clFuchsia') or
        SameText(AName, 'clAqua') or SameText(AName, 'clLtGray') or
        SameText(AName, 'clDkGray') or SameText(AName, 'clWhite') or
        SameText(AName, 'clMoneyGreen') or SameText(AName, 'clSkyBlue') or
        SameText(AName, 'clCream') or SameText(AName, 'clMedGray') or
        SameText(AName, 'clNone') or SameText(AName, 'clDefault') or
        SameText(AName, 'clScrollBar') or SameText(AName, 'clBackground') or
        SameText(AName, 'clActiveCaption') or SameText(AName, 'clInactiveCaption') or
        SameText(AName, 'clMenu') or SameText(AName, 'clWindow') or
        SameText(AName, 'clWindowFrame') or SameText(AName, 'clMenuText') or
        SameText(AName, 'clWindowText') or SameText(AName, 'clCaptionText') or
        SameText(AName, 'clActiveBorder') or SameText(AName, 'clInactiveBorder') or
        SameText(AName, 'clAppWorkSpace') or SameText(AName, 'clHighlight') or
        SameText(AName, 'clHighlightText') or SameText(AName, 'clBtnFace') or
        SameText(AName, 'clBtnShadow') or SameText(AName, 'clGrayText') or
        SameText(AName, 'clBtnText') or SameText(AName, 'clInactiveCaptionText') or
        SameText(AName, 'clBtnHighlight') or SameText(AName, 'cl3DDkShadow') or
        SameText(AName, 'cl3DLight') or SameText(AName, 'clInfoText') or
        SameText(AName, 'clInfoBk') or SameText(AName, 'clHotLight') or
        SameText(AName, 'clGradientActiveCaption') or
        SameText(AName, 'clGradientInactiveCaption') or
        SameText(AName, 'clMenuHighlight') or SameText(AName, 'clMenuBar');
    end;

  begin
    Lines := TStringList.Create;
    Reported := TDictionary<string, Boolean>.Create;
    try
      Lines.Text := Code;
      for I := 0 to Lines.Count - 1 do
      begin
        LineText := Lines[I];
        Matches := TRegEx.Matches(LineText, '\bcl[A-Z][A-Za-z0-9_]*\b');
        for Match in Matches do
        begin
          SymbolName := Match.Value;
          if IsKnownVclColor(SymbolName) or Reported.ContainsKey(SymbolName) then
            Continue;

          MatchPos := Match.Index + 1;
          CommentPos := Pos('//', LineText);
          if (CommentPos > 0) and (CommentPos < MatchPos) then
            Continue;

          Reported.Add(SymbolName, True);
          FContext.AddIssue(csManualReview,
            'Unknown VCL color constant preserved for manual review: ' + SymbolName);
        end;
      end;
    finally
      Reported.Free;
      Lines.Free;
    end;
  end;

  procedure InsertGeneratedHelperBlock(const HelperCode: string);
  var
    Lines: TStringList;
    I: Integer;
    J: Integer;
    ImplIdx: Integer;
    UsesIdx: Integer;
    InsertIdx: Integer;
    Inserted: Boolean;
  begin
    if Trim(HelperCode) = '' then
      Exit;

    Lines := TStringList.Create;
    try
      Lines.Text := Code;
      Inserted := False;

      ImplIdx := -1;
      for I := 0 to Lines.Count - 1 do
        if SameText(Trim(Lines[I]), 'implementation') then
        begin
          ImplIdx := I;
          Break;
        end;

      if ImplIdx <> -1 then
      begin
        UsesIdx := -1;
        for I := ImplIdx + 1 to Lines.Count - 1 do
        begin
          if Trim(Lines[I]) = '' then
            Continue;

          if TRegEx.IsMatch(Lines[I], '^\s*\{\$R\s+\*\.(?:dfm|fmx)\}\s*$',
            [roIgnoreCase]) then
            Continue;

          if SameText(Trim(Lines[I]), 'uses') or
             StartsText('uses ', TrimLeft(Lines[I])) then
          begin
            UsesIdx := I;
            Break;
          end;

          Break;
        end;

        if UsesIdx <> -1 then
        begin
          J := UsesIdx;
          while J < Lines.Count do
          begin
            if Pos(';', Lines[J]) > 0 then
            begin
              InsertIdx := J + 1;
              while (InsertIdx < Lines.Count) and
                    TRegEx.IsMatch(Lines[InsertIdx],
                      '^\s*\{\$R\s+\*\.(?:dfm|fmx)\}\s*$',
                      [roIgnoreCase]) do
                Inc(InsertIdx);
              Lines.Insert(InsertIdx, HelperCode);
              Inserted := True;
              Break;
            end;
            Inc(J);
          end;
        end;
      end;

      if not Inserted then
        for I := Lines.Count - 1 downto 0 do
          if TRegEx.IsMatch(Lines[I], '^\s*\{\$R\s+\*\.(?:dfm|fmx)\}\s*$',
            [roIgnoreCase]) then
          begin
            Lines.Insert(I + 1, HelperCode);
            Inserted := True;
            Break;
          end;

      if not Inserted and (ImplIdx <> -1) then
      begin
          Lines.Insert(ImplIdx + 1, HelperCode);
          Inserted := True;
      end;

      if Inserted then
        Code := Lines.Text;
    finally
      Lines.Free;
    end;
  end;
begin
  Code := TRegEx.Replace(Code,
    '(\b[A-Za-z_][A-Za-z0-9_]*(?:BGColor|FontColor|BG|FG)\b\s*:=\s*)(\$[0-9A-Fa-f]{1,8}|[A-Za-z_][A-Za-z0-9_\.]*\.FieldByName\([^\r\n;]+\)\.AsInteger)\s*;',
    '$1VCLColorToAlphaColor($2);',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '(\b[A-Za-z_][A-Za-z0-9_]*\b\s*:=\s*)([A-Za-z_][A-Za-z0-9_\.]*\.FieldByName\(\s*''form_(?:bgcolor|fontcolor)''\s*\)\.AsInteger)\s*;',
    '$1VCLColorToAlphaColor($2);',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '((?:\.Fill\.Color|\.TextSettings\.FontColor|\.Stroke\.Color)\s*:=\s*)(\$[0-9A-Fa-f]{1,8})\s*;',
    '$1VCLColorToAlphaColor($2);',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '((?:\.Fill\.Color|\.TextSettings\.FontColor|\.Stroke\.Color)\s*:=\s*)VCLColorToAlphaColor\((\$[0-9A-Fa-f]{8})\)\s*;',
    '$1TAlphaColor($2);',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '(\.ParamByName\([^\r\n;]+\)\.AsInteger\s*:=\s*)([A-Za-z_][A-Za-z0-9_]*(?:BGColor|FontColor|BG|FG))\s*;',
    '$1AlphaColorToVCLColor($2);',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*)Self\.Fill\.Color\s*:=\s*([^;\r\n]+);',
    '$1Self.Fill.Kind := TBrushKind.Solid;' + sLineBreak +
    '$1Self.Fill.Color := $2;' + sLineBreak +
    '$1ApplyContainerBackgroundColor(Self, $2);',
    [roIgnoreCase, roMultiLine]);

  Code := TRegEx.Replace(Code,
    '(^[ \t]*)AForm\.Fill\.Color\s*:=\s*([^;\r\n]+);',
    '$1AForm.Fill.Kind := TBrushKind.Solid;' + sLineBreak +
    '$1AForm.Fill.Color := $2;',
    [roIgnoreCase, roMultiLine]);

  if (ContainsText(Code, 'GeneratedRegisterManualFieldBinding(') or
      ContainsText(Code, 'GeneratedSyncManualFieldBindingsForDataSet(') or
      ContainsText(Code, 'GeneratedCommitManualFieldBindingsForDataSet(')) and
     not ContainsText(Code, 'procedure GeneratedRegisterManualFieldBinding(') then
    InsertGeneratedHelperBlock(ManualFieldHelperCode);

  if (ContainsText(Code, 'VCLColorToAlphaColor(') or
      ContainsText(Code, 'AlphaColorToVCLColor(')) and
     not ContainsText(Code, 'function VCLColorToAlphaColor(') then
    InsertGeneratedHelperBlock(BaseRuntimeColorHelperCode);

  if (ContainsText(Code, 'SetStatusBarPanelText(') or
      ContainsText(Code, 'GetStatusBarPanelText(')) and
     not ContainsText(Code, 'function FindNamedChild(') then
    InsertGeneratedHelperBlock(StatusBarHelperCode);

  if (ContainsText(Code, 'GeneratedAlphaBlendValueToOpacity(') or
      ContainsText(Code, 'GeneratedSetAlphaBlendValue(')) and
     not ContainsText(Code, 'function GeneratedAlphaBlendValueToOpacity(') then
    InsertGeneratedHelperBlock(AlphaBlendHelperCode);

  if (ContainsText(Code, 'ApplyStyledBackgroundColor(') or
      ContainsText(Code, 'ApplyContainerBackgroundColor(')) and
     not ContainsText(Code, 'procedure ApplyStyledBackgroundColor(') then
    InsertGeneratedHelperBlock(StyledBackgroundHelperCode);

  if ContainsText(Code, 'ApplyGridSelectionColor(') and
     not ContainsText(Code, 'procedure ApplyGridSelectionColor(') then
    InsertGeneratedHelperBlock(GridSelectionHelperCode);

  ReportUnknownVclColorConstants;
end;

end.
