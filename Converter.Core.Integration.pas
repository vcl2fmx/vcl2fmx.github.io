{VCL2FMX ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â© 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Core.Integration;

interface

uses
  System.SysUtils,
  System.Classes,
  System.RegularExpressions,
  System.StrUtils,
  System.Generics.Collections,
  Converter.Core.Types,
  Converter.Parser.DFM,
  Converter.Parser.Pascal,
  Converter.Advanced.CriticalAreas,
  Converter.Advanced.DataAware,
  Converter.Advanced.ThirdParty,
  Converter.Advanced.WinAPI,
  Converter.Rewrite.AutoFixes,
  Converter.Rewrite.Compatibility,
  Converter.Rewrite.LiveBindings,
  Converter.Rewrite.RuntimeNormalization,
  Converter.Rewrite.UsesClause,
  Converter.Mapper.Component;

type
  TConversionOrchestrator = class
  private
    FContext: TConversionContext;
    FDfmParser: TDFMParser;
    FPascalParser: TPascalParser;
    FComponentMapper: TComponentMapper;

    // Advanced converters
    FCriticalAreas: TCriticalAreasConverter;
    FDataAware: TLiveBindingConverter;
    FThirdParty: TThirdPartyHandler;
    FWinAPI: TWinAPIConverter;
    FGraphics: TGraphicsConverter;
    FGridDblClickHandlers: TDictionary<string, string>;
    FLiveBindings: TLiveBindingInjector;
    FUsesRewriter: TUsesClauseRewriter;
    FCompatibilityInjector: TCompatibilityInjector;
    FRuntimeNormalizer: TRuntimeNormalizer;
    FAutoFixes: TAutoFixRewriter;

    procedure PrepareFormDataBindings(const PascalFileName: string);
    procedure AlignShapeFieldTypes(const PascalFileName: string; var Code: string);
    procedure RewriteFolderPickerDialogs(const PascalFileName: string; var Code: string);
    procedure RewriteRootFormDoubleClick(const PascalFileName: string; var Code: string);
    procedure EnrichBindingMetadataFromDFM(const DFMCode: string);
    procedure PromoteFullTextMemoFieldsInPascal(var Code: string);
    procedure PromoteFullTextMemoFieldsInFMX(var FMXCode: string; const SourceDFM: string);
    procedure RewriteStructuralWrapperPanels(const PascalFileName: string; var Code: string);
    procedure WrapBitmapCanvasScenes(var Code: string);
    procedure ReduceGeneratedManualCleanup(var Code: string);
    procedure ApplyAdvancedConverters(var Code: string; const FileName: string);
    procedure RewriteSimpleGridDrawHandlers(var Code: string);
    procedure ProcessMethodBodies(const FileName: string);
    procedure ProcessStructuredPascalDeclarations(const FileName: string);
    procedure ProcessSemanticResolution(const FileName: string);
    procedure NormalizeFMXResourceDirectiveSpacing(var Code: string);
    procedure EnsureFMXResourceDirective(const FileName: string; var Code: string);
    procedure FixImplementationSection(var Code: string);  // NEW

  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    procedure ConvertPascal(const FileName: string; var Code: string);
    procedure ConvertDFM(const FileName: string; var Code: string);
  end;

implementation

constructor TConversionOrchestrator.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;

  FDfmParser := TDFMParser.Create(FContext);
  FPascalParser := TPascalParser.Create(FContext);
  FComponentMapper := TComponentMapper.Create(FContext);

  // Initialize advanced converters
  FCriticalAreas := TCriticalAreasConverter.Create(FContext);
  FDataAware := TLiveBindingConverter.Create(FContext, FComponentMapper);
  FThirdParty := TThirdPartyHandler.Create(FContext);
  FWinAPI := TWinAPIConverter.Create(FContext);
  FGraphics := TGraphicsConverter.Create(FContext);
  FGridDblClickHandlers := TDictionary<string, string>.Create;
  FRuntimeNormalizer := TRuntimeNormalizer.Create(FContext);
  FAutoFixes := TAutoFixRewriter.Create(FDfmParser, FContext);
  FLiveBindings := TLiveBindingInjector.Create(FContext, FDfmParser, FDataAware,
    FGridDblClickHandlers, FRuntimeNormalizer.NormalizeColors);
  FUsesRewriter := TUsesClauseRewriter.Create(FContext);
  FCompatibilityInjector := TCompatibilityInjector.Create(FContext);
end;

destructor TConversionOrchestrator.Destroy;
begin
  FCriticalAreas.Free;
  FDataAware.Free;
  FThirdParty.Free;
  FWinAPI.Free;
  FAutoFixes.Free;
  // FLiveBindings owns a method reference to FRuntimeNormalizer.NormalizeColors.
  // Free it first so that reference cannot outlive the runtime normalizer.
  FLiveBindings.Free;
  FRuntimeNormalizer.Free;
  FCompatibilityInjector.Free;
  FUsesRewriter.Free;
  FGraphics.Free;
  FGridDblClickHandlers.Free;

  FComponentMapper.Free;
  FPascalParser.Free;
  FDfmParser.Free;
  inherited;
end;

procedure TConversionOrchestrator.RewriteStructuralWrapperPanels(
  const PascalFileName: string; var Code: string);
  var
    DFMFileName: string;
    DFMCode: string;
  StructuralPanels: TStringList;
  PanelName: string;
  EscapedName: string;

  function IsStructuralWrapperPanelComponent(
    const Component: TDFMComponent): Boolean;
  var
    SourceClass: string;
    AlignValue: string;
    CaptionValue: string;
    ShowFrameValue: string;
  begin
    Result := False;
    if Component = nil then
      Exit;

    SourceClass := Component.ComponentClass;
    if SourceClass = '' then
      SourceClass := Component.ObjectClass;

    if SameText(SourceClass, 'TGroupBox') then
    begin
      CaptionValue := Trim(Component.GetPropertyValue('Caption', ''));
      if CaptionValue <> '' then
        Exit;

      ShowFrameValue := Trim(Component.GetPropertyValue('ShowFrame', ''));
      if not SameText(ShowFrameValue, 'False') then
        Exit;

      Result := True;
      Exit;
    end;

    if not SameText(SourceClass, 'TPanel') then
      Exit;

    AlignValue := Trim(Component.GetPropertyValue('Align', ''));
    if not SameText(AlignValue, 'alClient') then
      Exit;

    if Component.HasProperty('Color') then
      Exit;

    if Component.HasProperty('ParentBackground') and
       SameText(Trim(Component.GetPropertyValue('ParentBackground', '')), 'False') then
      Exit;

    CaptionValue := Trim(Component.GetPropertyValue('Caption', ''));
    if CaptionValue <> '' then
      Exit;

    if Component.HasProperty('BevelInner') or Component.HasProperty('BevelOuter') or
       Component.HasProperty('BevelKind') or Component.HasProperty('BevelWidth') or
       Component.HasProperty('BorderStyle') then
      Exit;

    Result := True;
  end;

  procedure CollectStructuralPanels(const Items: TObjectList<TDFMComponent>;
    const Names: TStrings);
  var
    Comp: TDFMComponent;
  begin
    if Items = nil then
      Exit;

    for Comp in Items do
    begin
      if IsStructuralWrapperPanelComponent(Comp) then
        Names.Add(Comp.Name);

      if Assigned(Comp.Children) then
        CollectStructuralPanels(Comp.Children, Names);

      if Assigned(Comp.CollectionItems) then
        CollectStructuralPanels(Comp.CollectionItems, Names);
    end;
  end;

begin
  DFMFileName := ChangeFileExt(PascalFileName, '.dfm');
  if not FileExists(DFMFileName) then
    Exit;

  DFMCode := FDfmParser.LoadDFM(DFMFileName);
  if DFMCode = '' then
    Exit;

  FDfmParser.Parse(DFMCode);

  StructuralPanels := TStringList.Create;
  try
    StructuralPanels.Sorted := True;
    StructuralPanels.Duplicates := dupIgnore;
    StructuralPanels.CaseSensitive := False;
    CollectStructuralPanels(FDfmParser.Components, StructuralPanels);

    for PanelName in StructuralPanels do
    begin
      EscapedName := TRegEx.Escape(PanelName);
      Code := TRegEx.Replace(Code,
        '(^\s*' + EscapedName + '\s*:\s*)TPanel(\s*;)',
        '$1TLayout$2',
        [roIgnoreCase, roMultiLine]);
      Code := TRegEx.Replace(Code,
        '(^\s*' + EscapedName + '\s*:\s*)FMX\.StdCtrls\.TPanel(\s*;)',
        '$1TLayout$2',
        [roIgnoreCase, roMultiLine]);
      Code := TRegEx.Replace(Code,
        '(^\s*' + EscapedName + '\s*:\s*)TGroupBox(\s*;)',
        '$1TLayout$2',
        [roIgnoreCase, roMultiLine]);
      Code := TRegEx.Replace(Code,
        '(^\s*' + EscapedName + '\s*:\s*)FMX\.StdCtrls\.TGroupBox(\s*;)',
        '$1TLayout$2',
        [roIgnoreCase, roMultiLine]);
    end;

    if StructuralPanels.Count > 0 then
      FContext.AddIssue(csInfo, Format(
        'Converted %d structural wrapper containers to TLayout in %s',
        [StructuralPanels.Count, ExtractFileName(PascalFileName)]));
  finally
    StructuralPanels.Free;
  end;
end;

procedure TConversionOrchestrator.ConvertPascal(const FileName: string; var Code: string);
begin
  FContext.AddIssue(csInfo, 'Converting Pascal: ' + ExtractFileName(FileName));

  PrepareFormDataBindings(FileName);
  AlignShapeFieldTypes(FileName, Code);
  RewriteFolderPickerDialogs(FileName, Code);
  RewriteSimpleGridDrawHandlers(Code);

  // Step 1: Deep parse the Pascal code to extract methods
  FPascalParser.Parse(FileName, Code);

  // Step 2: Process method bodies and structural declarations for GDI, messages, etc.
  ProcessMethodBodies(FileName);
  ProcessStructuredPascalDeclarations(FileName);
  ProcessSemanticResolution(FileName);

  // Step 3: Apply automatic fixes before advanced converters touch the source.
  FAutoFixes.Apply(Code);

  // Step 4: Keep structural wrapper panels in sync with the DFM-side TLayout mapping.
  RewriteStructuralWrapperPanels(FileName, Code);

  // Step 5: Apply advanced converters to the code
  ApplyAdvancedConverters(Code, FileName);

  // Step 6: Run the same cleanup again only after advanced converters have
  // inserted compatibility code. Keep ApplyAutomaticFixes idempotent.
  FAutoFixes.Apply(Code);

  // Step 7: Wrap generated bitmap canvas drawing in FMX BeginScene/EndScene.
  WrapBitmapCanvasScenes(Code);

  // Step 8: Normalize stored VCL color values for FMX runtime usage.
  FRuntimeNormalizer.NormalizeColors(Code);

  // Step 9: Promote full-text memo fields so FMX grids do not render them as blobs.
  PromoteFullTextMemoFieldsInPascal(Code);

  // Step 10: Warn about uncommon unit layouts before injecting LiveBindings.
  FLiveBindings.WarnIfMultipleFormDeclarations(FileName, Code);
  FLiveBindings.Inject(Code);

  // Step 11: Reduce routine cleanup comments after generated bindings are in place.
  ReduceGeneratedManualCleanup(Code);

  // Step 12: Inject generic compatibility classes for high-value VCL controls.
  FCompatibilityInjector.InjectClasses(Code);

  // Step 13: Add runtime lifecycle fixes for schedule/media cleanup.
  FCompatibilityInjector.InjectLifecycleFixes(Code);
  // Step 14: Keep FMX resource directives isolated before structure checks.
  NormalizeFMXResourceDirectiveSpacing(Code);

  // Step 15: Fix implementation section structure
  FixImplementationSection(Code);

  // Step 16: Remove duplicate implementation uses.
  FUsesRewriter.RemoveDuplicateImplementationUses(Code);

  // Step 17: Add root-form double-click adapters after structural Pascal rewrites.
  RewriteRootFormDoubleClick(FileName, Code);

  // Step 18: Preserve VCL-style label stacking math using source text metrics.
  FRuntimeNormalizer.RewriteTextLayoutMath(FileName, Code);

  // Step 19: Re-run runtime helper injection after late rewrite passes have
  // emitted generated helper calls.
  FRuntimeNormalizer.NormalizeColors(Code);

  // Step 20: Final uses clause cleanup.
  try
    FUsesRewriter.Fix(Code);
    EnsureFMXResourceDirective(FileName, Code);
    NormalizeFMXResourceDirectiveSpacing(Code);
  except
    on E: Exception do
      FContext.AddIssue(csError,
        Format('Final uses clause cleanup failed in %s: %s',
          [ExtractFileName(FileName), E.Message]),
        'Pascal uses clause cleanup',
        '',
        'Review the interface uses clause manually. The converter kept the file conversion running after the cleanup failure.',
        -1,
        False);
  end;

  FContext.AddIssue(csInfo, 'Pascal conversion successful: ' + ExtractFileName(FileName));
end;

procedure TConversionOrchestrator.ConvertDFM(const FileName: string; var Code: string);
var
  Components: TObjectList<TDFMComponent>;
  FMXCode: string;
  LoadedCode: string;
  TrimmedFMX: string;

  procedure AnalyzeComponentsRecursive(const Items: TObjectList<TDFMComponent>);
  var
    Comp: TDFMComponent;
  begin
    if Items = nil then
      Exit;

    for Comp in Items do
    begin
      if not Assigned(Comp) then
        Continue;

      if FContext.Options.EnableThirdParty then
        FThirdParty.AnalyzeComponent(Comp.ComponentClass, Comp.Name);

      if Assigned(Comp.Children) then
        AnalyzeComponentsRecursive(Comp.Children);

      if Assigned(Comp.CollectionItems) then
        AnalyzeComponentsRecursive(Comp.CollectionItems);
    end;
  end;
begin
  FContext.AddIssue(csInfo, 'Converting DFM: ' + ExtractFileName(FileName));

  LoadedCode := FDfmParser.LoadDFM(FileName);
  if Trim(LoadedCode) = '' then
    raise EConvertError.CreateFmt('DFM input is empty or could not be loaded: %s',
      [ExtractFileName(FileName)]);
  Code := LoadedCode;

  FDfmParser.Parse(Code);
  Components := FDfmParser.Components;
  if (Components = nil) or (Components.Count = 0) then
    raise EConvertError.CreateFmt('DFM parser found no root component in %s',
      [ExtractFileName(FileName)]);
  if not Assigned(Components[0]) or (Trim(Components[0].Name) = '') or
     (Trim(Components[0].ComponentClass) = '') then
    raise EConvertError.CreateFmt('DFM parser produced an invalid root component in %s',
      [ExtractFileName(FileName)]);

  AnalyzeComponentsRecursive(Components);
  if FContext.Options.EnableDataAware then
    FDataAware.AnalyzeForm(Components)
  else
    FDataAware.DataBindings.Clear;

  FMXCode := FDfmParser.Convert(FComponentMapper);
  PromoteFullTextMemoFieldsInFMX(FMXCode, LoadedCode);
  TrimmedFMX := Trim(FMXCode);
  if (TrimmedFMX = '') or
     not (StartsText('object ', TrimmedFMX) or StartsText('inherited ', TrimmedFMX)) or
     not EndsText('end', TrimmedFMX) then
    raise EConvertError.CreateFmt('DFM generator produced invalid or empty FMX for %s',
      [ExtractFileName(FileName)]);

  Code := FMXCode;
  FContext.AddIssue(csInfo, 'DFM conversion successful: ' + ExtractFileName(FileName));
end;

procedure TConversionOrchestrator.NormalizeFMXResourceDirectiveSpacing(var Code: string);
begin
  Code := TRegEx.Replace(Code,
    '\{\$R\s+\*\.dfm\}',
    '{$R *.fmx}',
    [roIgnoreCase]);

  Code := TRegEx.Replace(Code,
    '(\{\$R\s+\*\.fmx\})\s+((?:procedure|function|constructor|destructor|var|const|type)\b)',
    '$1' + sLineBreak + sLineBreak + '$2',
    [roIgnoreCase]);
end;

procedure TConversionOrchestrator.EnsureFMXResourceDirective(const FileName: string; var Code: string);
var
  DFMFileName: string;
  Lines: TStringList;
  I: Integer;
begin
  DFMFileName := ChangeFileExt(FileName, '.dfm');
  if not FileExists(DFMFileName) then
    Exit;

  if TRegEx.IsMatch(Code, '\{\$R\s+\*\.(?:dfm|fmx)\}', [roIgnoreCase]) then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.Text := Code;
    for I := 0 to Lines.Count - 1 do
      if SameText(Trim(Lines[I]), 'implementation') then
      begin
        Lines.Insert(I + 1, '{$R *.fmx}');
        Code := Lines.Text;
        Exit;
      end;
  finally
    Lines.Free;
  end;
end;

procedure TConversionOrchestrator.FixImplementationSection(var Code: string);
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  I: Integer;
  ImplIndex: Integer;
  Trimmed: string;
  FirstCodeIndex: Integer;
begin
  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  try
    Lines.Text := Code;
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Code);
    ImplIndex := -1;

    for I := 0 to AnalysisLines.Count - 1 do
    begin
      Trimmed := Trim(AnalysisLines[I]);
      if SameText(Trimmed, 'implementation') then
      begin
        ImplIndex := I;
        Break;
      end;
    end;

    if ImplIndex = -1 then
    begin
      FContext.AddIssue(csError,
        'Pascal unit is missing an implementation section after conversion.',
        'Pascal structure safeguard',
        '',
        'Open the converted unit and restore the implementation section before compiling.',
        -1,
        True);
      Exit;
    end;

    FirstCodeIndex := -1;
    for I := ImplIndex + 1 to AnalysisLines.Count - 1 do
    begin
      Trimmed := Trim(AnalysisLines[I]);
      if (Trimmed = '') or StartsText('{$', Trimmed) then
        Continue;
      FirstCodeIndex := I;
      Break;
    end;

    if FirstCodeIndex <> -1 then
    begin
      Trimmed := Trim(AnalysisLines[FirstCodeIndex]);
      if not StartsText('uses', Trimmed) and
         not StartsText('procedure ', Trimmed) and
         not StartsText('function ', Trimmed) and
         not StartsText('constructor ', Trimmed) and
         not StartsText('destructor ', Trimmed) and
         not SameText(Trimmed, 'initialization') and
         not SameText(Trimmed, 'finalization') and
         not SameText(Trimmed, 'type') and
         not SameText(Trimmed, 'const') and
         not SameText(Trimmed, 'var') and
         not SameText(Trimmed, 'resourcestring') and
         not StartsText('class ', Trimmed) and
         not StartsText('class(', Trimmed) and
         not SameText(Trimmed, 'end.') and
         not SameText(Trimmed, 'end') then
        FContext.AddIssue(csWarning,
          'Implementation section contains an unexpected first statement after conversion.',
          'Pascal structure safeguard',
          Lines[FirstCodeIndex],
          'Review the converted unit around the implementation section before relying on the generated code.',
          FirstCodeIndex + 1,
          False);
    end;

    Code := Lines.Text;
  finally
    AnalysisLines.Free;
    Lines.Free;
  end;
end;
procedure TConversionOrchestrator.EnrichBindingMetadataFromDFM(const DFMCode: string);
var
  Binding: TDataBindingInfo;
  GridMatch: TMatch;
  ColumnsMatch: TMatch;
  ItemMatches: TMatchCollection;
  ItemMatch: TMatch;
  Match: TMatch;
  DataSourceMatch: TMatch;
  DataSetMatch: TMatch;
  FieldNameMatch: TMatch;
  ComponentPattern: string;
  DataSourcePattern: string;
  ItemText: string;
  FieldName: string;
  NormalizedFieldName: string;
  HeaderValue: string;
  WidthValue: string;
  SourceFieldName: string;
  DisplayFieldName: string;
  FieldClass: string;
  DisplayFieldClass: string;
  VisibleCount: Integer;
  DisplayCount: Integer;
  I: Integer;
  J: Integer;
  FullTextCount: Integer;
  CountValue: string;
  DblClickHandler: string;
  AdapterName: string;

  function UnquoteDFMValue(const S: string): string;
  begin
    Result := Trim(S);
    if (Length(Result) >= 2) and (Result[1] = '''') and
       (Result[Length(Result)] = '''') then
      Result := Copy(Result, 2, Length(Result) - 2);
    Result := StringReplace(Result, '''''', '''', [rfReplaceAll]);
  end;
begin
  if DFMCode = '' then
    Exit;

  for Binding in FDataAware.DataBindings do
  begin
    if not Assigned(Binding) then
      Continue;

    if Binding.DataSource <> '' then
    begin
      DataSourcePattern := Format(
        '^(\s*)object\s+%s\s*:\s*TDataSource\b(?<body>.*?)(?=^\1object\s+\w+\s*:|^\1end\s*$)',
        [TRegEx.Escape(Binding.DataSource)]);
      DataSourceMatch := TRegEx.Match(DFMCode, DataSourcePattern,
        [roIgnoreCase, roSingleLine, roMultiLine]);
      if DataSourceMatch.Success then
      begin
        DataSetMatch := TRegEx.Match(DataSourceMatch.Groups['body'].Value,
          'DataSet\s*=\s*(\w+)', [roIgnoreCase, roSingleLine]);
        if DataSetMatch.Success then
          Binding.OriginalProperties.AddOrSetValue('DataSetComponent',
            DataSetMatch.Groups[1].Value);

        Match := TRegEx.Match(DataSourceMatch.Groups['body'].Value,
          'OnDataChange\s*=\s*(\w+)', [roIgnoreCase, roSingleLine]);
        if Match.Success then
          Binding.OriginalProperties.AddOrSetValue('DataSource.OnDataChange',
            Match.Groups[1].Value);
      end;
    end;

    if SameText(Binding.DataLinkType, 'Grid') and (Binding.ComponentName <> '') then
    begin
      ComponentPattern := Format(
        '^(\s*)object\s+%s\s*:\s*TDBGrid\b(?<body>.*?)(?=^\1object\s+\w+\s*:|^\1end\s*$)',
        [TRegEx.Escape(Binding.ComponentName)]);
      GridMatch := TRegEx.Match(DFMCode, ComponentPattern,
        [roIgnoreCase, roSingleLine, roMultiLine]);
      if GridMatch.Success then
      begin
        Match := TRegEx.Match(GridMatch.Groups['body'].Value,
          'OnDblClick\s*=\s*(\w+)', [roIgnoreCase, roSingleLine]);
        if Match.Success then
        begin
          DblClickHandler := Match.Groups[1].Value;
          if (DblClickHandler <> '') and (Binding.ComponentName <> '') then
          begin
            AdapterName := Binding.ComponentName + 'CellDblClick';
            FGridDblClickHandlers.AddOrSetValue(AdapterName, DblClickHandler);
          end;
        end;

        ColumnsMatch := TRegEx.Match(GridMatch.Groups['body'].Value,
          'Columns\s*=\s*<(?<cols>.*?)>',
          [roIgnoreCase, roSingleLine]);
        if ColumnsMatch.Success then
        begin
          ItemMatches := TRegEx.Matches(ColumnsMatch.Groups['cols'].Value,
            'item\b(?<item>.*?)end',
            [roIgnoreCase, roSingleLine]);
          VisibleCount := 0;
          for ItemMatch in ItemMatches do
          begin
            ItemText := ItemMatch.Groups['item'].Value;
            if TRegEx.IsMatch(ItemText, 'Visible\s*=\s*False', [roIgnoreCase]) then
              Continue;

            Match := TRegEx.Match(ItemText, 'FieldName\s*=\s*(''.*?'')',
              [roIgnoreCase, roSingleLine]);
            if not Match.Success then
              Continue;
            FieldName := Match.Groups[1].Value;

            HeaderValue := '';
            Match := TRegEx.Match(ItemText, 'Title\.Caption\s*=\s*(''.*?'')',
              [roIgnoreCase, roSingleLine]);
            if Match.Success then
              HeaderValue := Match.Groups[1].Value;

            WidthValue := '';
            Match := TRegEx.Match(ItemText, 'Width\s*=\s*(\d+)',
              [roIgnoreCase, roSingleLine]);
            if Match.Success then
              WidthValue := Match.Groups[1].Value;

            Binding.OriginalProperties.AddOrSetValue(
              Format('GridColumn%d.FieldName', [VisibleCount]), FieldName);
            if HeaderValue <> '' then
              Binding.OriginalProperties.AddOrSetValue(
                Format('GridColumn%d.Title.Caption', [VisibleCount]), HeaderValue);
            if WidthValue <> '' then
              Binding.OriginalProperties.AddOrSetValue(
                Format('GridColumn%d.Width', [VisibleCount]), WidthValue);
            Inc(VisibleCount);
          end;
          Binding.OriginalProperties.AddOrSetValue('GridColumnCount',
            IntToStr(VisibleCount));
        end;
      end;
    end;

    I := 0;
    for Match in TRegEx.Matches(DFMCode,
      'object\s+(\w+)\s*:\s*(TWideMemoField|TMemoField)\b(?<body>.*?)DisplayValue\s*=\s*dvFullText',
      [roIgnoreCase, roSingleLine]) do
    begin
      FieldClass := Match.Groups[2].Value;
      FieldNameMatch := TRegEx.Match(Match.Groups['body'].Value,
        'FieldName\s*=\s*(''.*?'')', [roIgnoreCase, roSingleLine]);
      if not FieldNameMatch.Success then
        Continue;

      SourceFieldName := UnquoteDFMValue(FieldNameMatch.Groups[1].Value);
      DisplayFieldName := SourceFieldName + '_display';
      if SameText(FieldClass, 'TWideMemoField') then
        DisplayFieldClass := 'TWideStringField'
      else
        DisplayFieldClass := 'TStringField';

      Binding.OriginalProperties.AddOrSetValue(
        Format('FullTextField%d.ComponentName', [I]), Match.Groups[1].Value);
      Binding.OriginalProperties.AddOrSetValue(
        Format('FullTextField%d.FieldClass', [I]), FieldClass);
      Binding.OriginalProperties.AddOrSetValue(
        Format('FullTextField%d.FieldName', [I]), SourceFieldName);
      Binding.OriginalProperties.AddOrSetValue(
        Format('FullTextField%d.DisplayFieldName', [I]), DisplayFieldName);
      Binding.OriginalProperties.AddOrSetValue(
        Format('FullTextField%d.DisplayFieldClass', [I]), DisplayFieldClass);
      Inc(I);
    end;
    if I > 0 then
      Binding.OriginalProperties.AddOrSetValue('FullTextFieldCount', IntToStr(I));

      DisplayCount := 0;
    if Binding.OriginalProperties.ContainsKey('GridColumnCount') then
    begin
      VisibleCount := StrToIntDef(Binding.OriginalProperties['GridColumnCount'], 0);
      if not Binding.OriginalProperties.TryGetValue('FullTextFieldCount', CountValue) then
        CountValue := '0';
      FullTextCount := StrToIntDef(CountValue, 0);
      for J := 0 to VisibleCount - 1 do
        if Binding.OriginalProperties.TryGetValue(
             Format('GridColumn%d.FieldName', [J]), FieldName) then
        begin
          NormalizedFieldName := UnquoteDFMValue(FieldName);
          for I := 0 to FullTextCount - 1 do
            if Binding.OriginalProperties.TryGetValue(
                 Format('FullTextField%d.FieldName', [I]), SourceFieldName) and
               SameText(SourceFieldName, NormalizedFieldName) then
            begin
              DisplayFieldName := Binding.OriginalProperties[
                Format('FullTextField%d.DisplayFieldName', [I])];
              DisplayFieldClass := Binding.OriginalProperties[
                Format('FullTextField%d.DisplayFieldClass', [I])];
              Binding.OriginalProperties.AddOrSetValue(
                Format('GridColumn%d.DisplayFieldName', [J]),
                QuotedStr(DisplayFieldName));
              Binding.OriginalProperties.AddOrSetValue(
                Format('GridDisplayField%d.SourceFieldName', [DisplayCount]),
                SourceFieldName);
              Binding.OriginalProperties.AddOrSetValue(
                Format('GridDisplayField%d.DisplayFieldName', [DisplayCount]),
                DisplayFieldName);
              Binding.OriginalProperties.AddOrSetValue(
                Format('GridDisplayField%d.DisplayFieldClass', [DisplayCount]),
                DisplayFieldClass);
              Inc(DisplayCount);
              Break;
            end;
        end;
      if DisplayCount > 0 then
        Binding.OriginalProperties.AddOrSetValue('GridDisplayFieldCount',
          IntToStr(DisplayCount));
    end;
  end;
end;

procedure TConversionOrchestrator.PromoteFullTextMemoFieldsInPascal(var Code: string);
begin
  if not FContext.Options.EnableDataAware then
    Exit;

  // Keep dataset field classes intact. FMX grid display now uses generated
  // string companion fields for memo-backed columns instead.
end;

procedure TConversionOrchestrator.PromoteFullTextMemoFieldsInFMX(
  var FMXCode: string; const SourceDFM: string);
begin
  if not FContext.Options.EnableDataAware then
    Exit;

  // Keep dataset field classes intact. FMX grid display now uses generated
  // string companion fields for memo-backed columns instead.
end;

procedure TConversionOrchestrator.RewriteFolderPickerDialogs(
  const PascalFileName: string; var Code: string);
var
  DFMFileName: string;
  DFMCode: string;
  FolderDialogs: TStringList;
  Lines: TStringList;
    DialogName: string;
    IndentText: string;
    LineText: string;
    NextLineText: string;
    Match: TMatch;
  RewroteAny: Boolean;
  RewrittenCount: Integer;
    I: Integer;
    DialogMatches: TMatchCollection;
    DialogMatch: TMatch;
    DialogBody: string;
    RewrittenLine: string;

    function EnsureFolderHelperPresent: Boolean;
  const
    HelperName = 'GeneratedSelectDirectoryPath';
  var
    HelperCode: string;
  begin
    if ContainsText(Code, 'function ' + HelperName + '(') then
      Exit(True);

    HelperCode :=
      'function ' + HelperName + '(const ACurrentPath: string): string;' + sLineBreak +
      'var' + sLineBreak +
      '  RootDir: string;' + sLineBreak +
      '  SelectedDir: string;' + sLineBreak +
      'begin' + sLineBreak +
      '  Result := ACurrentPath;' + sLineBreak +
      '  RootDir := Trim(ACurrentPath);' + sLineBreak +
      '  if (RootDir <> '''') and not DirectoryExists(RootDir) then' + sLineBreak +
      '    RootDir := ExtractFileDir(RootDir);' + sLineBreak +
      '  if not DirectoryExists(RootDir) then' + sLineBreak +
      '    RootDir := GetCurrentDir;' + sLineBreak +
      '  SelectedDir := RootDir;' + sLineBreak +
      '  if SelectDirectory(''Select folder'', RootDir, SelectedDir) then' + sLineBreak +
      '    Result := SelectedDir;' + sLineBreak +
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

    function RewriteFolderAssignment(const AssignmentText, Indent: string;
      out NewLine: string): Boolean;
    var
      AssignmentMatch: TMatch;
      TargetValue: string;
      RHSValue: string;
      UpdatedRHSValue: string;
    begin
      Result := False;
      NewLine := '';

      AssignmentMatch := TRegEx.Match(Trim(AssignmentText),
        '^([A-Za-z_][A-Za-z0-9_\.]*)\s*:=\s*(.+?)\s*;\s*$',
        [roIgnoreCase]);
      if not AssignmentMatch.Success then
        Exit;

      TargetValue := AssignmentMatch.Groups[1].Value;
      RHSValue := AssignmentMatch.Groups[2].Value;
      if not TRegEx.IsMatch(RHSValue,
           '\b' + TRegEx.Escape(DialogName) + '\.FileName\b',
           [roIgnoreCase]) then
        Exit;

      UpdatedRHSValue := TRegEx.Replace(RHSValue,
        '\b' + TRegEx.Escape(DialogName) + '\.FileName\b',
        'GeneratedSelectDirectoryPath(' + TargetValue + ')',
        [roIgnoreCase]);
      if SameText(UpdatedRHSValue, RHSValue) then
        Exit;

      NewLine := Indent + TargetValue + ' := ' + UpdatedRHSValue + ';';
      Result := True;
    end;

  begin
  DFMFileName := ChangeFileExt(PascalFileName, '.dfm');
  if not FileExists(DFMFileName) then
    Exit;

  FolderDialogs := TStringList.Create;
  Lines := TStringList.Create;
  try
    FolderDialogs.CaseSensitive := False;
    FolderDialogs.Duplicates := dupIgnore;
    FolderDialogs.Sorted := False;

    DFMCode := FDfmParser.LoadDFM(DFMFileName);
    if DFMCode = '' then
      Exit;

    DialogMatches := TRegEx.Matches(DFMCode,
      '^\s*(?:object|inherited)\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*TFileOpenDialog\b(.*?)^\s*end\s*$',
      [roIgnoreCase, roMultiLine, roSingleLine]);
    for DialogMatch in DialogMatches do
    begin
      DialogBody := DialogMatch.Groups[2].Value;
      if TRegEx.IsMatch(DialogBody,
        '^\s*Options\s*=\s*\[[^\]]*\bfdoPickFolders\b[^\]]*\]',
        [roIgnoreCase, roMultiLine]) then
        FolderDialogs.Add(DialogMatch.Groups[1].Value);
    end;

    if FolderDialogs.Count = 0 then
      Exit;

    Lines.Text := Code;
    RewroteAny := False;
    RewrittenCount := 0;

    for DialogName in FolderDialogs do
    begin
      // Multi-line pattern:
      // if dlgSelectFolder.Execute then
      //   edtFolder.Text := dlgSelectFolder.FileName;
      I := 0;
        while I < Lines.Count do
        begin
          LineText := Lines[I];

          Match := TRegEx.Match(LineText,
            Format('^(\s*)%s\.Options\s*:=\s*.*\bfdoPickFolders\b.*;\s*$',
              [TRegEx.Escape(DialogName)]),
            [roIgnoreCase]);
          if Match.Success then
          begin
            Lines[I] := Match.Groups[1].Value +
              '// FMX folder-picker options handled by GeneratedSelectDirectoryPath';
            RewroteAny := True;
            Inc(RewrittenCount);
            Inc(I);
            Continue;
          end;

        Match := TRegEx.Match(LineText,
          Format('^(\s*)if\s+%s\.Execute\s+then\s*$',
            [TRegEx.Escape(DialogName)]),
          [roIgnoreCase]);
          if Match.Success and (I < Lines.Count - 1) then
          begin
            NextLineText := Lines[I + 1];
            IndentText := Match.Groups[1].Value;
            if RewriteFolderAssignment(Trim(NextLineText), IndentText, RewrittenLine) then
            begin
              Lines[I] := RewrittenLine;
              Lines.Delete(I + 1);
              RewroteAny := True;
              Inc(RewrittenCount);
              Continue;
            end;
          end;

          Match := TRegEx.Match(LineText,
            Format('^(\s*)if\s+%s\.Execute\s+then\s+(.+)$',
              [TRegEx.Escape(DialogName)]),
            [roIgnoreCase]);
          if Match.Success and
             RewriteFolderAssignment(Match.Groups[2].Value, Match.Groups[1].Value, RewrittenLine) then
          begin
            Lines[I] := RewrittenLine;
            RewroteAny := True;
            Inc(RewrittenCount);
          end;

        Inc(I);
      end;
    end;

    if not RewroteAny then
      Exit;

    Code := Lines.Text;
    if EnsureFolderHelperPresent then
      FContext.AddIssue(csInfo,
        Format('Rewrote %d folder-picker dialog assignment(s) in %s',
          [RewrittenCount, ExtractFileName(PascalFileName)]));
  finally
    Lines.Free;
    FolderDialogs.Free;
  end;
end;

procedure TConversionOrchestrator.RewriteRootFormDoubleClick(
  const PascalFileName: string; var Code: string);
var
  DFMFileName: string;
  DFMCode: string;
  RootBlockMatch: TMatch;
  Match: TMatch;
  Lines: TStringList;
  RootDblClickHandler: string;
  RootMouseUpHandler: string;
  RootMouseMoveHandler: string;
  FormClassName: string;
  AdapterMethodName: string;
  LastMouseUpTimeField: string;
  FinalInsertIdx: Integer;
  I: Integer;
  MethodImplementationLines: TStringList;

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

  function ExtractOwningClassName(const MethodName: string): string;
  var
    MethodMatch: TMatch;
  begin
    Result := '';
    MethodMatch := TRegEx.Match(Code,
      '^\s*procedure\s+([A-Za-z_][A-Za-z0-9_]*)\.' +
      TRegEx.Escape(MethodName) + '\s*\(',
      [roIgnoreCase, roMultiLine]);
    if MethodMatch.Success then
      Result := MethodMatch.Groups[1].Value;
  end;

  procedure EnsureFieldInClass(const ClassName, FieldLine: string);
  var
    ClassIdx: Integer;
    PrivateIdx: Integer;
    FirstVisibilityIdx: Integer;
    EndClassIdx: Integer;
    InsertIdx: Integer;
    J: Integer;
    TrimmedLine: string;
  begin
    if ContainsText(Lines.Text, Trim(FieldLine)) then
      Exit;

    ClassIdx := -1;
    PrivateIdx := -1;
    FirstVisibilityIdx := -1;
    EndClassIdx := -1;

    for J := 0 to Lines.Count - 1 do
    begin
      TrimmedLine := Trim(Lines[J]);

      if (ClassIdx = -1) and
         TRegEx.IsMatch(TrimmedLine,
           '^' + TRegEx.Escape(ClassName) + '\s*=\s*class\s*\(',
           [roIgnoreCase]) then
      begin
        ClassIdx := J;
        Continue;
      end;

      if ClassIdx = -1 then
        Continue;

      if (PrivateIdx = -1) and
         (SameText(TrimmedLine, 'private') or SameText(TrimmedLine, 'strict private')) then
        PrivateIdx := J;

      if (FirstVisibilityIdx = -1) and
         (SameText(TrimmedLine, 'protected') or
          SameText(TrimmedLine, 'strict protected') or
          SameText(TrimmedLine, 'public') or
          SameText(TrimmedLine, 'published')) then
        FirstVisibilityIdx := J;

      if SameText(TrimmedLine, 'end;') then
      begin
        EndClassIdx := J;
        Break;
      end;
    end;

    if ClassIdx = -1 then
      Exit;

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
    end
    else
      Exit;

    Lines.Insert(InsertIdx, FieldLine);
  end;

  procedure EnsureMethodInClass(const ClassName, MethodLine: string);
  var
    ClassIdx: Integer;
    PrivateIdx: Integer;
    FirstVisibilityIdx: Integer;
    EndClassIdx: Integer;
    InsertIdx: Integer;
    J: Integer;
    TrimmedLine: string;
  begin
    if ContainsText(Lines.Text, Trim(MethodLine)) then
      Exit;

    ClassIdx := -1;
    PrivateIdx := -1;
    FirstVisibilityIdx := -1;
    EndClassIdx := -1;

    for J := 0 to Lines.Count - 1 do
    begin
      TrimmedLine := Trim(Lines[J]);

      if (ClassIdx = -1) and
         TRegEx.IsMatch(TrimmedLine,
           '^' + TRegEx.Escape(ClassName) + '\s*=\s*class\s*\(',
           [roIgnoreCase]) then
      begin
        ClassIdx := J;
        Continue;
      end;

      if ClassIdx = -1 then
        Continue;

      if (PrivateIdx = -1) and
         (SameText(TrimmedLine, 'private') or SameText(TrimmedLine, 'strict private')) then
        PrivateIdx := J;

      if (FirstVisibilityIdx = -1) and
         (SameText(TrimmedLine, 'protected') or
          SameText(TrimmedLine, 'strict protected') or
          SameText(TrimmedLine, 'public') or
          SameText(TrimmedLine, 'published')) then
        FirstVisibilityIdx := J;

      if SameText(TrimmedLine, 'end;') then
      begin
        EndClassIdx := J;
        Break;
      end;
    end;

    if ClassIdx = -1 then
      Exit;

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
    end
    else
      Exit;

    while (InsertIdx < Lines.Count) and
          not StartsMethodDeclaration(Trim(Lines[InsertIdx])) and
          not SameText(Trim(Lines[InsertIdx]), 'protected') and
          not SameText(Trim(Lines[InsertIdx]), 'strict protected') and
          not SameText(Trim(Lines[InsertIdx]), 'public') and
          not SameText(Trim(Lines[InsertIdx]), 'published') and
          not SameText(Trim(Lines[InsertIdx]), 'end;') do
      Inc(InsertIdx);

    Lines.Insert(InsertIdx, MethodLine);
  end;

  procedure EnsureEventMethodInClass(const ClassName, MethodLine: string);
  var
    ClassIdx: Integer;
    InsertIdx: Integer;
    J: Integer;
    TrimmedLine: string;
  begin
    if ContainsText(Lines.Text, Trim(MethodLine)) then
      Exit;

    ClassIdx := -1;
    InsertIdx := -1;

    for J := 0 to Lines.Count - 1 do
    begin
      TrimmedLine := Trim(Lines[J]);

      if (ClassIdx = -1) and
         TRegEx.IsMatch(TrimmedLine,
           '^' + TRegEx.Escape(ClassName) + '\s*=\s*class\s*\(',
           [roIgnoreCase]) then
      begin
        ClassIdx := J;
        Continue;
      end;

      if ClassIdx = -1 then
        Continue;

      if SameText(TrimmedLine, 'private') or
         SameText(TrimmedLine, 'strict private') or
         SameText(TrimmedLine, 'protected') or
         SameText(TrimmedLine, 'strict protected') or
         SameText(TrimmedLine, 'public') or
         SameText(TrimmedLine, 'published') or
         SameText(TrimmedLine, 'end;') then
      begin
        InsertIdx := J;
        Break;
      end;
    end;

    if (ClassIdx = -1) or (InsertIdx = -1) then
      Exit;

    Lines.Insert(InsertIdx, MethodLine);
  end;

  procedure EnsureUsesUnit(const UnitName: string);
  begin
    if ContainsText(Code, UnitName) then
      Exit;

    if TRegEx.IsMatch(Code, '^\s*uses\s*$', [roIgnoreCase, roMultiLine]) then
      Code := TRegEx.Replace(Code,
        '^\s*uses\s*$',
        'uses' + sLineBreak + '  ' + UnitName + ',',
        [roIgnoreCase, roMultiLine])
    else
      Code := TRegEx.Replace(Code,
        '^\s*uses\s+',
        'uses ' + UnitName + ', ',
        [roIgnoreCase, roMultiLine]);
  end;

  procedure RewriteRootFormMouseMoveSignature(const HandlerName: string);
  begin
    if HandlerName = '' then
      Exit;

    Code := TRegEx.Replace(Code,
      '(\bprocedure\s+' + TRegEx.Escape(HandlerName) +
      '\s*\(\s*Sender\s*:\s*TObject\s*;\s*Shift\s*:\s*TShiftState\s*;\s*X\s*,\s*Y\s*:\s*)Integer(\s*\))',
      '$1Single$2',
      [roIgnoreCase]);

    Code := TRegEx.Replace(Code,
      '(\bprocedure\s+[A-Za-z0-9_\.]+\.' + TRegEx.Escape(HandlerName) +
      '\s*\(\s*Sender\s*:\s*TObject\s*;\s*Shift\s*:\s*TShiftState\s*;\s*X\s*,\s*Y\s*:\s*)Integer(\s*\))',
      '$1Single$2',
      [roIgnoreCase]);
  end;

begin
  DFMFileName := ChangeFileExt(PascalFileName, '.dfm');
  if not FileExists(DFMFileName) then
    Exit;

  DFMCode := FDfmParser.LoadDFM(DFMFileName);
  if DFMCode = '' then
    Exit;

  RootBlockMatch := TRegEx.Match(DFMCode,
    '^\s*object\s+\w+\s*:\s*\w+\b(?<body>.*?)(?=^\s*object\s+\w+\s*:|^end\s*$)',
    [roIgnoreCase, roSingleLine, roMultiLine]);
  if not RootBlockMatch.Success then
    Exit;

  Match := TRegEx.Match(RootBlockMatch.Groups['body'].Value,
    'OnDblClick\s*=\s*(\w+)', [roIgnoreCase, roSingleLine]);
  if Match.Success then
    RootDblClickHandler := Trim(Match.Groups[1].Value)
  else
    RootDblClickHandler := '';
  Match := TRegEx.Match(RootBlockMatch.Groups['body'].Value,
    'OnMouseUp\s*=\s*(\w+)', [roIgnoreCase, roSingleLine]);
  if Match.Success then
    RootMouseUpHandler := Trim(Match.Groups[1].Value)
  else
    RootMouseUpHandler := '';

  Match := TRegEx.Match(RootBlockMatch.Groups['body'].Value,
    'OnMouseMove\s*=\s*(\w+)', [roIgnoreCase, roSingleLine]);
  if Match.Success then
    RootMouseMoveHandler := Trim(Match.Groups[1].Value)
  else
    RootMouseMoveHandler := '';

  RewriteRootFormMouseMoveSignature(RootMouseMoveHandler);

  if RootDblClickHandler = '' then
    Exit;

  FormClassName := ExtractOwningClassName(RootDblClickHandler);
  if FormClassName = '' then
    Exit;

  Lines := TStringList.Create;
  MethodImplementationLines := TStringList.Create;
  try
    Lines.Text := Code;

    AdapterMethodName := 'GeneratedRootFormMouseUpDblClick';
    LastMouseUpTimeField := 'FGeneratedLastFormMouseUpTime';

    EnsureFieldInClass(FormClassName, '    ' + LastMouseUpTimeField + ': TDateTime;');
    EnsureEventMethodInClass(FormClassName,
      '    procedure ' + AdapterMethodName +
      '(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);');

    if not TRegEx.IsMatch(Lines.Text,
         '^\s*procedure\s+[A-Za-z0-9_\.]+\.' + TRegEx.Escape(AdapterMethodName) + '\s*\(',
         [roIgnoreCase, roMultiLine]) then
    begin
      MethodImplementationLines.Add('');
      MethodImplementationLines.Add('procedure ' + FormClassName + '.' + AdapterMethodName +
        '(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);');
      MethodImplementationLines.Add('begin');
      if RootMouseUpHandler <> '' then
        MethodImplementationLines.Add('  ' + RootMouseUpHandler +
          '(Sender, Button, Shift, Round(X), Round(Y));');
      MethodImplementationLines.Add('  if Button <> TMouseButton.mbLeft then');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  if (' + LastMouseUpTimeField + ' > 0) and');
      MethodImplementationLines.Add('     (MilliSecondsBetween(Now, ' + LastMouseUpTimeField + ') <= 500) then');
      MethodImplementationLines.Add('  begin');
      MethodImplementationLines.Add('    ' + LastMouseUpTimeField + ' := 0;');
      MethodImplementationLines.Add('    ' + RootDblClickHandler + '(Sender);');
      MethodImplementationLines.Add('    Exit;');
      MethodImplementationLines.Add('  end;');
      MethodImplementationLines.Add('  ' + LastMouseUpTimeField + ' := Now;');
      MethodImplementationLines.Add('end;');

      FinalInsertIdx := -1;
      for I := Lines.Count - 1 downto 0 do
      begin
        if SameText(Trim(Lines[I]), 'initialization') or
           SameText(Trim(Lines[I]), 'finalization') or
           SameText(Trim(Lines[I]), 'end.') then
        begin
          FinalInsertIdx := I;
          Break;
        end;
      end;

      if FinalInsertIdx = -1 then
        FinalInsertIdx := Lines.Count;

      for I := MethodImplementationLines.Count - 1 downto 0 do
        Lines.Insert(FinalInsertIdx, MethodImplementationLines[I]);
    end;

    Code := Lines.Text;
    EnsureUsesUnit('System.DateUtils');
  finally
    MethodImplementationLines.Free;
    Lines.Free;
  end;
end;

procedure TConversionOrchestrator.PrepareFormDataBindings(const PascalFileName: string);
var
  DFMFileName: string;
  DFMCode: string;
begin
  FDataAware.DataBindings.Clear;
  FGridDblClickHandlers.Clear;

  if not FContext.Options.EnableDataAware then
    Exit;

  DFMFileName := ChangeFileExt(PascalFileName, '.dfm');
  if not FileExists(DFMFileName) then
    Exit;

  try
    DFMCode := FDfmParser.LoadDFM(DFMFileName);
    if DFMCode = '' then
      Exit;

    FDfmParser.Parse(DFMCode);
    FDataAware.AnalyzeForm(FDfmParser.Components);
    EnrichBindingMetadataFromDFM(DFMCode);

    if FDataAware.DataBindings.Count > 0 then
      FContext.AddIssue(csInfo,
        Format('Prepared %d data-aware bindings for %s',
          [FDataAware.DataBindings.Count, ExtractFileName(PascalFileName)]));
  except
    on E: Exception do
    begin
      FDataAware.DataBindings.Clear;
      FGridDblClickHandlers.Clear;
      FContext.AddIssue(csWarning,
        Format('Failed to prepare data-aware bindings for %s: %s',
          [ExtractFileName(PascalFileName), E.Message]));
    end;
  end;
end;

procedure TConversionOrchestrator.AlignShapeFieldTypes(
  const PascalFileName: string; var Code: string);
var
  DFMFileName: string;
  DFMCode: string;
  LocalParser: TDFMParser;
  Lines: TStringList;
  I: Integer;
  Line: string;
  Match: TMatch;
  Component: TDFMComponent;
  TargetClass: string;

  function GetTargetShapeClass(const AComponent: TDFMComponent): string;
  var
    ShapeKind: string;
  begin
    Result := '';
    if (AComponent = nil) or not SameText(AComponent.ComponentClass, 'TShape') then
      Exit;

    ShapeKind := Trim(AComponent.GetPropertyValue('Shape', ''));
    if SameText(ShapeKind, 'stCircle') or SameText(ShapeKind, 'stEllipse') then
      Exit('TEllipse');
    if SameText(ShapeKind, 'stRoundRect') or SameText(ShapeKind, 'stRoundSquare') then
      Exit('TRoundRect');
    Exit('TRectangle');
  end;
begin
  DFMFileName := ChangeFileExt(PascalFileName, '.dfm');
  if not FileExists(DFMFileName) then
    Exit;

  LocalParser := TDFMParser.Create(FContext);
  Lines := TStringList.Create;
  try
    DFMCode := LocalParser.LoadDFM(DFMFileName);
    if DFMCode = '' then
      Exit;

    LocalParser.Parse(DFMCode);
    Lines.Text := Code;

    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];
      Match := TRegEx.Match(Line,
        '^(\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:\s*TShape\s*;\s*$',
        [roIgnoreCase]);
      if not Match.Success then
        Continue;

      Component := LocalParser.FindComponent(Match.Groups[2].Value);
      TargetClass := GetTargetShapeClass(Component);
      if TargetClass <> '' then
        Lines[I] := Match.Groups[1].Value + Match.Groups[2].Value + ': ' + TargetClass + ';';
    end;

    Code := Lines.Text;
  finally
    Lines.Free;
    LocalParser.Free;
  end;
end;

procedure TConversionOrchestrator.RewriteSimpleGridDrawHandlers(var Code: string);
var
  Lines: TStringList;
  i: Integer;

  function GetIndent(const S: string): string;
  begin
    Result := Copy(S, 1, Length(S) - Length(TrimLeft(S)));
  end;

  function FindSignatureEnd(const StartIdx: Integer): Integer;
  begin
    Result := StartIdx;
    while (Result < Lines.Count - 1) and (Pos(');', Lines[Result]) = 0) do
      Inc(Result);
  end;

  function BuildSignatureText(const StartIdx, EndIdx: Integer): string;
  var
    Idx: Integer;
  begin
    Result := '';
    for Idx := StartIdx to EndIdx do
      Result := Result + ' ' + Trim(Lines[Idx]);
    Result := Trim(Result);
  end;

  function FindMethodBegin(const StartIdx: Integer): Integer;
  begin
    Result := StartIdx;
    while Result < Lines.Count do
    begin
      if SameText(Trim(Lines[Result]), 'begin') then
        Exit;
      if StartsText('procedure ', TrimLeft(Lines[Result])) or
         StartsText('function ', TrimLeft(Lines[Result])) or
         SameText(Trim(Lines[Result]), 'implementation') then
        Exit(-1);
      Inc(Result);
    end;
    Result := -1;
  end;

  function FindMethodEnd(const BeginIdx: Integer): Integer;
  var
    Idx: Integer;
    CleanLine: string;
    Depth: Integer;
  begin
    Depth := 0;
    for Idx := BeginIdx to Lines.Count - 1 do
    begin
      CleanLine := Trim(TRegEx.Replace(Lines[Idx], '//.*$', ''));
      if CleanLine = '' then
        Continue;

      if StartsText('begin', CleanLine) or StartsText('try', CleanLine) or
         SameText(CleanLine, 'case') or StartsText('case ', CleanLine) or
         StartsText('repeat', CleanLine) then
        Inc(Depth);

      if SameText(CleanLine, 'end;') or SameText(CleanLine, 'end') or
         StartsText('until ', CleanLine) then
      begin
        Dec(Depth);
        if Depth <= 0 then
          Exit(Idx);
      end;
    end;
    Result := -1;
  end;

  function ExtractMethodName(const SignatureText: string): string;
  var
    Match: TMatch;
  begin
    Result := '';
    Match := TRegEx.Match(SignatureText,
      'procedure\s+([A-Za-z_][A-Za-z0-9_\.]*)\s*\(',
      [roIgnoreCase]);
    if Match.Success then
      Result := Match.Groups[1].Value;
  end;

  function IsLegacyGridDrawSignature(const SignatureText: string): Boolean;
  begin
    Result := ContainsText(SignatureText, 'DrawColumnCell') and
      ContainsText(SignatureText, 'Rect: TRect') and
      ContainsText(SignatureText, 'DataCol: Integer') and
      ContainsText(SignatureText, 'State: TGridDrawState');
  end;

  function TryBuildConvertedBody(const StartIdx, EndIdx: Integer; const MethodIndent: string;
    out Replacement: TStringList): Boolean;
  var
    Idx: Integer;
    Match: TMatch;
    SelectedColorExpr: string;
    NormalColorExpr: string;
    BodyText: string;
    InnerIndent: string;
    function ConvertGridColorExpr(const Expr: string): string;
    var
      RGBMatch: TMatch;
      RValue: Integer;
      GValue: Integer;
      BValue: Integer;
      ColorRef: Cardinal;
    begin
      Result := Trim(Expr);

      RGBMatch := TRegEx.Match(Result,
        '^RGB\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)$',
        [roIgnoreCase]);
      if RGBMatch.Success then
      begin
        RValue := StrToIntDef(RGBMatch.Groups[1].Value, 0);
        GValue := StrToIntDef(RGBMatch.Groups[2].Value, 0);
        BValue := StrToIntDef(RGBMatch.Groups[3].Value, 0);
        ColorRef := (Cardinal(BValue and $FF) shl 16) or
                    (Cardinal(GValue and $FF) shl 8) or
                     Cardinal(RValue and $FF);
        Exit('VCLColorToAlphaColor($' + IntToHex(ColorRef, 8) + ')');
      end;

      if TRegEx.IsMatch(Result, '^\$[0-9A-Fa-f]+$') then
        Exit('VCLColorToAlphaColor(' + Result + ')');
    end;
  begin
    Result := False;
    Replacement := nil;
    SelectedColorExpr := '';
    NormalColorExpr := '';
    BodyText := '';

    for Idx := StartIdx to EndIdx do
      BodyText := BodyText + Lines[Idx] + sLineBreak;

    if not ContainsText(BodyText, 'DefaultDrawColumnCell') then
      Exit;
    if not (ContainsText(BodyText, 'FillRect(Rect') or ContainsText(BodyText, 'FillRect (Rect')) then
      Exit;

    for Idx := StartIdx to EndIdx do
    begin
      Match := TRegEx.Match(Lines[Idx],
        '\.Brush\.Color\s*:=\s*([^;\r\n]+)',
        [roIgnoreCase]);
      if Match.Success then
      begin
        if SelectedColorExpr = '' then
          SelectedColorExpr := Trim(Match.Groups[1].Value)
        else if NormalColorExpr = '' then
          NormalColorExpr := Trim(Match.Groups[1].Value);
      end;
    end;

    if (SelectedColorExpr = '') or (NormalColorExpr = '') then
      Exit;

    SelectedColorExpr := ConvertGridColorExpr(SelectedColorExpr);
    NormalColorExpr := ConvertGridColorExpr(NormalColorExpr);
    InnerIndent := MethodIndent + '  ';
    Replacement := TStringList.Create;
    Replacement.Add(MethodIndent + 'begin');
    Replacement.Add(InnerIndent + 'Canvas.Fill.Kind := TBrushKind.Solid;');
    Replacement.Add(InnerIndent + 'if (TGridDrawState.Selected in State) or (TGridDrawState.RowSelected in State) then');
    Replacement.Add(InnerIndent + 'begin');
    Replacement.Add(InnerIndent + '  Canvas.Fill.Color := ' + SelectedColorExpr + ';');
    Replacement.Add(InnerIndent + 'end');
    Replacement.Add(InnerIndent + 'else');
    Replacement.Add(InnerIndent + 'begin');
    Replacement.Add(InnerIndent + '  Canvas.Fill.Color := ' + NormalColorExpr + ';');
    Replacement.Add(InnerIndent + 'end;');
    Replacement.Add(InnerIndent + 'Canvas.FillRect(Bounds, 0, 0, [], 1);');
    Replacement.Add(MethodIndent + 'end;');
    Result := True;
  end;

  procedure ReplaceRange(const StartIdx, EndIdx: Integer; const NewLines: TStrings);
  var
    RemoveCount: Integer;
    Idx: Integer;
  begin
    RemoveCount := EndIdx - StartIdx + 1;
    for Idx := 1 to RemoveCount do
      Lines.Delete(StartIdx);
    for Idx := NewLines.Count - 1 downto 0 do
      Lines.Insert(StartIdx, NewLines[Idx]);
  end;

var
  SigEnd: Integer;
  BeginIdx: Integer;
  EndIdx: Integer;
  SignatureText: string;
  MethodName: string;
  MethodIndent: string;
  NewSignature: TStringList;
  NewBody: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := Code;
    i := 0;
    while i < Lines.Count do
    begin
      if not StartsText('procedure ', TrimLeft(Lines[i])) then
      begin
        Inc(i);
        Continue;
      end;

      SigEnd := FindSignatureEnd(i);
      SignatureText := BuildSignatureText(i, SigEnd);
      if not IsLegacyGridDrawSignature(SignatureText) then
      begin
        Inc(i);
        Continue;
      end;

      MethodName := ExtractMethodName(SignatureText);
      if MethodName = '' then
      begin
        Inc(i);
        Continue;
      end;

      MethodIndent := GetIndent(Lines[i]);
      NewSignature := TStringList.Create;
      try
        NewSignature.Add(MethodIndent + 'procedure ' + MethodName +
          '(Sender: TObject; const Canvas: TCanvas; const Column: TColumn; const Bounds: TRectF; ' +
          'const Row: Integer; const Value: TValue; const State: TGridDrawStates);');
        ReplaceRange(i, SigEnd, NewSignature);
      finally
        NewSignature.Free;
      end;

      BeginIdx := FindMethodBegin(i + 1);
      if BeginIdx = -1 then
      begin
        Inc(i);
        Continue;
      end;

      EndIdx := FindMethodEnd(BeginIdx);
      if EndIdx = -1 then
      begin
        Inc(i);
        Continue;
      end;

      if TryBuildConvertedBody(i + 1, EndIdx, MethodIndent, NewBody) then
      begin
        try
          ReplaceRange(i + 1, EndIdx, NewBody);
        finally
          NewBody.Free;
        end;
      end;

      Inc(i);
    end;

    Code := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure TConversionOrchestrator.ProcessSemanticResolution(const FileName: string);
var
  PascalClass: TPascalClass;
  Method: TPascalMethod;
  ImplementedMethods: TStringList;
  ClassNames: TStringList;
  HandlerIndex: Integer;
  HandlerName: string;
  Key: string;

  function HasGlobalMethod(const AKey: string): Boolean;
  begin
    Result := Assigned(FContext) and
      (FContext.SemanticMethodIndex.IndexOf(AKey) >= 0);
  end;

  function HasGlobalClass(const AClassName: string): Boolean;
  begin
    Result := Assigned(FContext) and
      (FContext.SemanticClassIndex.IndexOf(AClassName) >= 0);
  end;
begin
  if not Assigned(FPascalParser.CurrentUnit) then
    Exit;

  ImplementedMethods := TStringList.Create;
  ClassNames := TStringList.Create;
  try
    ImplementedMethods.CaseSensitive := False;
    ClassNames.CaseSensitive := False;

    for PascalClass in FPascalParser.CurrentUnit.Classes do
      if Assigned(PascalClass) and (PascalClass.Name <> '') then
        ClassNames.Add(PascalClass.Name);

    for Method in FPascalParser.CurrentUnit.Methods do
      if Assigned(Method) and (Method.PascalClassName <> '') and
         (Method.Name <> '') then
        ImplementedMethods.Add(Method.PascalClassName + '.' + Method.Name);

    for PascalClass in FPascalParser.CurrentUnit.Classes do
    begin
      if not Assigned(PascalClass) then
        Continue;

      for HandlerIndex := 0 to PascalClass.MessageHandlers.Count - 1 do
      begin
        HandlerName := PascalClass.MessageHandlers.Names[HandlerIndex];
        Key := PascalClass.Name + '.' + HandlerName;
        if (ImplementedMethods.IndexOf(Key) = -1) and not HasGlobalMethod(Key) then
          FContext.AddIssue(csWarning,
            Format('Semantic resolution: message handler %s is declared but no matching implementation was found in %s.',
              [Key, ExtractFileName(FileName)]),
            'Pascal semantic resolution',
            PascalClass.MessageHandlers.ValueFromIndex[HandlerIndex],
            'Confirm that the handler implementation is present in the unit or an included file. Missing message-handler implementations can block compilation after conversion.',
            -1,
            False);
      end;
    end;

    for Method in FPascalParser.CurrentUnit.Methods do
    begin
      if not Assigned(Method) or (Method.PascalClassName = '') then
        Continue;

      if (ClassNames.IndexOf(Method.PascalClassName) = -1) and
         not HasGlobalClass(Method.PascalClassName) then
        FContext.AddIssue(csInfo,
          Format('Semantic resolution: implementation %s has no parsed class declaration in %s.',
            [Method.GetDisplayName, ExtractFileName(FileName)]),
          'Pascal semantic resolution',
          Method.FullSignature,
          'This may be valid when the class declaration is supplied by an include file. If Delphi reports an undeclared method or unknown class, review the include/declaration structure.',
          Method.StartLine,
          False);
    end;
  finally
    ClassNames.Free;
    ImplementedMethods.Free;
  end;
end;
procedure TConversionOrchestrator.ProcessStructuredPascalDeclarations(const FileName: string);
var
  PascalClass: TPascalClass;
  HandlerIndex: Integer;
  HandlerText: string;
  MessageMatch: TMatch;
  MessageName: string;
begin
  if not Assigned(FPascalParser.CurrentUnit) then
    Exit;

  for PascalClass in FPascalParser.CurrentUnit.Classes do
  begin
    if PascalClass = nil then
      Continue;

    for HandlerIndex := 0 to PascalClass.MessageHandlers.Count - 1 do
    begin
      HandlerText := PascalClass.MessageHandlers.ValueFromIndex[HandlerIndex];
      MessageMatch := TRegEx.Match(HandlerText,
        '\bmessage\s+([A-Za-z_][A-Za-z0-9_]*)', [roIgnoreCase]);
      if MessageMatch.Success then
        MessageName := MessageMatch.Groups[1].Value
      else
        MessageName := 'Windows message';

      if SameText(MessageName, 'WM_SYSCOMMAND') then
        FContext.AddManualReview(
          'Pascal structure message handler declaration',
          Format('Structured Pascal analysis found Windows system command message handler %s.%s.',
            [PascalClass.Name, PascalClass.MessageHandlers.Names[HandlerIndex]]),
          HandlerText,
          'Windows system command handling needs FMX review. SC_CLOSE may map to Close or OnCloseQuery, but minimize/restore/maximize handlers often carry lifecycle or timer side effects that need an explicit FMX design decision.',
          -1,
          False)
      else
        FContext.AddManualReview(
          'Pascal structure message handler declaration',
          Format('Structured Pascal analysis found %s message handler %s.%s.',
            [MessageName, PascalClass.Name, PascalClass.MessageHandlers.Names[HandlerIndex]]),
          HandlerText,
          'Replace the VCL message handler with FMX events, form lifecycle events, System.Messaging, or platform-specific services where needed.',
          -1,
          False);
    end;
  end;
end;
procedure TConversionOrchestrator.ProcessMethodBodies(const FileName: string);
var
  Method: TPascalMethod;
  i: Integer;
  MethodText: string;
  UnitText: string;
begin
  if not Assigned(FPascalParser.CurrentUnit) then
    Exit;

  UnitText := FPascalParser.CurrentUnit.Types.Text + sLineBreak +
    FPascalParser.CurrentUnit.Variables.Text;

  for i := 0 to FPascalParser.CurrentUnit.Methods.Count - 1 do
  begin
    Method := FPascalParser.CurrentUnit.Methods[i];
    if not Assigned(Method) then
      Continue;

    MethodText := Method.Body.Text;

    // Check for OnPaint methods
    if ContainsText(Method.Name, 'Paint') or
       ContainsText(Method.Name, 'Draw') then
    begin
      if Method.HasGDICalls and not Method.UsesFMXCanvasSignature then
      begin
        FContext.AddIssue(csInfo,
          Format('OnPaint method %s.%s will need FMX Canvas conversion',
            [FileName, Method.GetDisplayName]));
        if ContainsText(MethodText, 'BitBlt') or
           ContainsText(MethodText, 'StretchBlt') or
           ContainsText(MethodText, 'MaskBlt') or
           TRegEx.IsMatch(MethodText, '\balphablend\s*\(', [roIgnoreCase]) or
           ContainsText(MethodText, 'CreateCompatibleDC') or
           ContainsText(MethodText, 'CreateCompatibleBitmap') or
           ContainsText(MethodText, 'SetDIBits') or
           ContainsText(MethodText, 'GetDIBits') or
           ContainsText(MethodText, 'PolyBezier') then
          FContext.AddManualReview(
            'Custom paint or GDI conversion',
            Format('Custom paint/GDI code in %s.%s requires manual review before the FMX output can be trusted.',
              [FileName, Method.GetDisplayName]),
            MethodText,
            'Review this method in the IDE. Replace the remaining VCL/GDI drawing path with FMX Canvas code or keep it platform-specific.',
            -1,
            True);
      end;
    end;
  end;

end;

procedure TConversionOrchestrator.ApplyAdvancedConverters(var Code: string; const FileName: string);
var
  Lines: TStringList;
  Modified: Boolean;
  OriginalCode: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := Code;
    Modified := False;

    // Store original for comparison
    OriginalCode := Code;

    // Convert critical areas (OnPaint, message handlers, owner-draw)
    if FContext.Options.EnableCriticalAreas and
       FCriticalAreas.ConvertAllCriticalAreas(Lines) then
    begin
      Modified := True;
      FContext.AddIssue(csInfo,
        Format('Critical areas converted in %s', [ExtractFileName(FileName)]));
    end;

    // Convert Windows API calls
    Code := Lines.Text;
    if FContext.Options.EnableWinAPI then
      Code := FWinAPI.ConvertWinAPICalls(Code);

    // Always apply graphics conversion - it handles positioning and colors
    FContext.AddIssue(csInfo, 'Applying graphics conversion to ' + ExtractFileName(FileName));
    Code := FGraphics.ConvertGraphics(Code);

    // Update Lines with converted code
    Lines.Text := Code;

    // Add platform conditionals where needed
    if FContext.Options.EnableWinAPI then
      FWinAPI.AddPlatformConditionals(Lines);

    // Update the original code if modifications were made
    if Modified or (Code <> OriginalCode) then
      Code := Lines.Text;

  finally
    Lines.Free;
  end;
end;

procedure TConversionOrchestrator.ReduceGeneratedManualCleanup(var Code: string);
var
  Lines: TStringList;
  GridBindingSources: TDictionary<string, string>;
  DirectBindingTargets: TDictionary<string, string>;
  i: Integer;
  L: string;
  Trimmed: string;
  ReviewLine: string;
  IndentText: string;
  TargetName: string;
  BindSourceName: string;
  Match: TMatch;
begin
  Lines := TStringList.Create;
  GridBindingSources := TDictionary<string, string>.Create;
  DirectBindingTargets := TDictionary<string, string>.Create;
  try
    Lines.Text := Code;

    for i := 0 to Lines.Count - 1 do
    begin
      L := Lines[i];

      Match := TRegEx.Match(L,
        '^\s*Link_([A-Za-z_][A-Za-z0-9_]*)\.DataSource\s*:=\s*(BindSourceDB_[A-Za-z_][A-Za-z0-9_]*)\s*;',
        [roIgnoreCase]);
      if Match.Success then
        GridBindingSources.AddOrSetValue(Match.Groups[1].Value, Match.Groups[2].Value);

      Match := TRegEx.Match(L,
        '^\s*([A-Za-z_][A-Za-z0-9_]*)\.DataSource\s*:=\s*(BindSourceDB_[A-Za-z_][A-Za-z0-9_]*)\s*;',
        [roIgnoreCase]);
      if Match.Success and not StartsText('Link_', Match.Groups[1].Value) then
        DirectBindingTargets.AddOrSetValue(Match.Groups[1].Value, Match.Groups[2].Value);
    end;

    for i := 0 to Lines.Count - 1 do
    begin
      L := Lines[i];
      Trimmed := TrimLeft(L);
      if not StartsText('// FMX manual review:', Trimmed) then
        Continue;

      ReviewLine := Trim(Copy(Trimmed, Length('// FMX manual review:') + 1, MaxInt));
      while StartsText('// FMX manual review:', ReviewLine) do
        ReviewLine := Trim(Copy(ReviewLine, Length('// FMX manual review:') + 1, MaxInt));
      IndentText := Copy(L, 1, Length(L) - Length(TrimLeft(L)));

      Match := TRegEx.Match(ReviewLine,
        '^([A-Za-z_][A-Za-z0-9_]*)\.DataSource\s*:=\s*[A-Za-z_][A-Za-z0-9_]*\s*;$',
        [roIgnoreCase]);
      if Match.Success then
      begin
        TargetName := Match.Groups[1].Value;
        if GridBindingSources.ContainsKey(TargetName) or
           DirectBindingTargets.ContainsKey(TargetName) then
        begin
          Lines[i] := IndentText + '// FMX: binding generated automatically for ' + TargetName;
          Continue;
        end;
      end;

      Match := TRegEx.Match(ReviewLine,
        '^([A-Za-z_][A-Za-z0-9_]*)\.DataSource\.DataSet\.First\s*;\s*(//.*)?$',
        [roIgnoreCase]);
      if Match.Success then
      begin
        TargetName := Match.Groups[1].Value;
        if GridBindingSources.TryGetValue(TargetName, BindSourceName) then
        begin
          Lines[i] := IndentText +
            'if Assigned(' + BindSourceName + ') and Assigned(' + BindSourceName +
            '.DataSource) and Assigned(' + BindSourceName +
            '.DataSource.DataSet) then ' + BindSourceName + '.DataSource.DataSet.First;';
          Continue;
        end;
      end;
    end;

    Code := Lines.Text;
  finally
    DirectBindingTargets.Free;
    GridBindingSources.Free;
    Lines.Free;
  end;
end;

procedure TConversionOrchestrator.WrapBitmapCanvasScenes(var Code: string);
var
  Lines: TStringList;
  OutputLines: TStringList;
  BitmapOwners: TStringList;
  BitmapMatches: TMatchCollection;
  BitmapMatch: TMatch;
  BitmapDeclNames: TArray<string>;
  BitmapDeclName: string;
  i: Integer;
  L: string;
  CurrentExpr: string;
  NextExpr: string;
  Indent: string;

  function GetIndent(const S: string): string;
  begin
    Result := Copy(S, 1, Length(S) - Length(TrimLeft(S)));
  end;

  function ExtractBitmapCanvasExpr(const S: string): string;
  var
    Match: TMatch;
    OwnerName: string;
  begin
    Result := '';
    if StartsText('//', TrimLeft(S)) then
      Exit;

    Match := TRegEx.Match(S, '\b([A-Za-z_][A-Za-z0-9_\.]*\.Canvas)\b', [roIgnoreCase]);
    if not Match.Success then
      Exit;

    OwnerName := Match.Groups[1].Value;
    OwnerName := Copy(OwnerName, 1, Length(OwnerName) - Length('.Canvas'));

    if ContainsText(Match.Groups[1].Value, 'Bitmap') or
       (BitmapOwners.IndexOf(OwnerName) >= 0) then
      Result := Match.Groups[1].Value;
  end;

  function StatementEndsLine(const S: string): Boolean;
  var
    CleanLine: string;
  begin
    CleanLine := Trim(TRegEx.Replace(S, '//.*$', ''));
    Result := (CleanLine <> '') and CleanLine.EndsWith(';');
  end;
begin
  Lines := TStringList.Create;
  OutputLines := TStringList.Create;
  BitmapOwners := TStringList.Create;
  try
    BitmapOwners.CaseSensitive := False;
    BitmapOwners.Sorted := True;
    BitmapOwners.Duplicates := dupIgnore;
    Lines.Text := Code;

    for i := 0 to Lines.Count - 1 do
    begin
      L := Lines[i];
      if StartsText('//', TrimLeft(L)) then
        Continue;

      BitmapMatches := TRegEx.Matches(L,
        '\b([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?:FMX\.Graphics\.)?TBitmap\b',
        [roIgnoreCase]);
      for BitmapMatch in BitmapMatches do
        BitmapOwners.Add(BitmapMatch.Groups[1].Value);

      BitmapMatches := TRegEx.Matches(L,
        '\b([A-Za-z_][A-Za-z0-9_,\s]*)\s*:\s*(?:FMX\.Graphics\.)?TBitmap\b',
        [roIgnoreCase]);
      for BitmapMatch in BitmapMatches do
      begin
        BitmapDeclNames := BitmapMatch.Groups[1].Value.Split([',']);
        for BitmapDeclName in BitmapDeclNames do
          if Trim(BitmapDeclName) <> '' then
            BitmapOwners.Add(Trim(BitmapDeclName));
      end;

      BitmapMatches := TRegEx.Matches(L,
        '\b([A-Za-z_][A-Za-z0-9_]*)\s*:=\s*(?:FMX\.Graphics\.)?TBitmap\.Create\b',
        [roIgnoreCase]);
      for BitmapMatch in BitmapMatches do
        BitmapOwners.Add(BitmapMatch.Groups[1].Value);
    end;

    i := 0;
    while i < Lines.Count do
    begin
      L := Lines[i];
      CurrentExpr := ExtractBitmapCanvasExpr(L);

      if (CurrentExpr <> '') and
         not ContainsText(L, CurrentExpr + '.BeginScene') and
         not ContainsText(L, CurrentExpr + '.EndScene') then
      begin
        Indent := GetIndent(L);
        OutputLines.Add(Indent + 'if ' + CurrentExpr + '.BeginScene then');
        OutputLines.Add(Indent + 'try');

        while i < Lines.Count do
        begin
          L := Lines[i];
          OutputLines.Add(L);
          Inc(i);

          if not StatementEndsLine(L) then
            Continue;

          if i >= Lines.Count then
            Break;

          NextExpr := ExtractBitmapCanvasExpr(Lines[i]);
          if SameText(NextExpr, CurrentExpr) then
            Continue;

          Break;
        end;

        OutputLines.Add(Indent + 'finally');
        OutputLines.Add(Indent + '  ' + CurrentExpr + '.EndScene;');
        OutputLines.Add(Indent + 'end;');
        Continue;
      end;

      OutputLines.Add(L);
      Inc(i);
    end;

    Code := OutputLines.Text;
  finally
    BitmapOwners.Free;
    OutputLines.Free;
    Lines.Free;
  end;
end;

end.
