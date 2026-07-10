{VCL2FMX (c) 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Rewrite.AutoFixes;

interface

uses
  System.SysUtils,
  System.Classes,
  System.RegularExpressions,
  System.StrUtils,
  System.Generics.Collections,
  Converter.Parser.DFM,
  Converter.Core.Types;

type
  TAutoFixRewriter = class
  private
    FDfmParser: TDFMParser;
    FContext: TConversionContext;
    function StartsRoutine(const S: string): Boolean;
    function GetDeclaredControlType(
      AControlTypes: TDictionary<string, string>; const Identifier: string): string;
    function SupportsPositionRewrite(const DeclaredType: string): Boolean;
    function UsesTextInsteadOfCaption(const DeclaredType: string): Boolean;
    function UsesCaptionInsteadOfText(const DeclaredType: string): Boolean;
    procedure DiscoverDeclaredTypeMaps(ALines: TStrings;
      AControlTypes, AGenericListFields: TDictionary<string, string>);
    function RewriteTypedMemberAccess(const S: string;
      AControlTypes: TDictionary<string, string>): string;
    function SignatureEndsDeclaration(const S: string): Boolean;
    function IsLegacyGridDrawSignature(const S, NextS: string): Boolean;
    function IsUnsupportedMessageHandlerSignature(const S, NextS: string): Boolean;
    function IsPascalStructuralBoundary(const S: string;
      IncludeSectionKeywords: Boolean): Boolean;
    function StripManualReviewPrefix(const S: string): string;
    function AddManualReviewPrefix(const S: string): string;
    procedure MarkLineForManualReview(var Line: string; ALineNumber: Integer;
      const AProblemType, AMessage, ASuggestedFix: string);
    procedure FixMalformedFieldEndings(ALines: TStringList);
    procedure MarkUnsupportedPascalRoutinesForReview(ALines: TStringList);
    function HandleTrayStartupRewrite(ALines: TStringList; const LineIndex: Integer;
      AControlTypes: TDictionary<string, string>; var Line: string;
      var PendingTrayHideSuppress: Boolean): Boolean;
    procedure SplitTrailingBlockComment(var ALine: string; out ASuffix: string);
    procedure ApplyBasicTypeAndPropertyRewrites(var Line: string;
      const AnalysisLine: string; AControlTypes: TDictionary<string, string>);
    procedure RewriteCanvasGeometryLine(var Line: string;
      var InEllipseFill, InPolygonFill: Boolean);
    procedure RestoreNonUnsupportedManualReviewSignatures(ALines: TStringList);
    procedure RewriteWindowsMessageHelperCalls(var Code: string);
    procedure InsertWindowsMessageHelperBlock(var Code: string);
    procedure FixNumericMath(var Line: string);
  public
    constructor Create(ADfmParser: TDFMParser; AContext: TConversionContext);
    procedure Apply(var Code: string);
  end;

implementation

constructor TAutoFixRewriter.Create(ADfmParser: TDFMParser;
  AContext: TConversionContext);
begin
  inherited Create;
  FDfmParser := ADfmParser;
  FContext := AContext;
end;

function TAutoFixRewriter.StartsRoutine(const S: string): Boolean;
var
  Trimmed: string;
begin
  Trimmed := TrimLeft(S);
  Result := StartsText('procedure ', Trimmed) or
            StartsText('function ', Trimmed) or
            StartsText('constructor ', Trimmed) or
            StartsText('destructor ', Trimmed);
end;

function TAutoFixRewriter.GetDeclaredControlType(
  AControlTypes: TDictionary<string, string>; const Identifier: string): string;
begin
  Result := '';
  if not Assigned(AControlTypes) or (Trim(Identifier) = '') then
    Exit;

  AControlTypes.TryGetValue(Identifier, Result);
end;

function TAutoFixRewriter.SupportsPositionRewrite(
  const DeclaredType: string): Boolean;
begin
  Result := DeclaredType <> '';
  if not Result then
    Exit;

  if SameText(DeclaredType, 'TBitmap') or
     SameText(DeclaredType, 'TPngImage') or
     SameText(DeclaredType, 'TStringList') or
     SameText(DeclaredType, 'TStrings') or
     SameText(DeclaredType, 'TMemoryStream') or
     SameText(DeclaredType, 'TStringStream') or
     SameText(DeclaredType, 'TFont') or
     SameText(DeclaredType, 'TFontDialog') or
     SameText(DeclaredType, 'TColorDialog') or
     SameText(DeclaredType, 'TOpenDialog') or
     SameText(DeclaredType, 'TSaveDialog') or
     SameText(DeclaredType, 'TTimer') or
     SameText(DeclaredType, 'TAction') or
     SameText(DeclaredType, 'TDataSource') or
     StartsText('TFD', DeclaredType) or
     EndsText('Field', DeclaredType) or
     SameText(DeclaredType, 'TForm') or
     StartsText('Tfm', DeclaredType) or
     StartsText('Tfrm', DeclaredType) or
     StartsText('Tdm', DeclaredType) or
       ContainsText(DeclaredType, 'DataModule') then
    Exit(False);
end;

function TAutoFixRewriter.UsesTextInsteadOfCaption(
  const DeclaredType: string): Boolean;
begin
  Result := DeclaredType <> '';
  if not Result then
    Exit;

  if UsesCaptionInsteadOfText(DeclaredType) then
    Exit(False);

  Result :=
    SameText(DeclaredType, 'TLabel') or
    SameText(DeclaredType, 'TButton') or
    SameText(DeclaredType, 'TBitBtn') or
    SameText(DeclaredType, 'TSpeedButton') or
    SameText(DeclaredType, 'TCheckBox') or
    SameText(DeclaredType, 'TRadioButton') or
    SameText(DeclaredType, 'TGroupBox') or
    SameText(DeclaredType, 'TTabSheet') or
    SameText(DeclaredType, 'TMenuItem') or
    SameText(DeclaredType, 'TAction') or
    EndsText('Button', DeclaredType) or
    EndsText('Label', DeclaredType) or
    EndsText('CheckBox', DeclaredType) or
    EndsText('RadioButton', DeclaredType) or
    EndsText('GroupBox', DeclaredType) or
    EndsText('TabSheet', DeclaredType) or
    EndsText('MenuItem', DeclaredType);
end;

function TAutoFixRewriter.UsesCaptionInsteadOfText(
  const DeclaredType: string): Boolean;
begin
  Result := DeclaredType <> '';
  if not Result then
    Exit;

  Result :=
    SameText(DeclaredType, 'TForm') or
    SameText(DeclaredType, 'TCustomForm') or
    SameText(DeclaredType, 'TCommonCustomForm') or
    StartsText('Tfm', DeclaredType) or
    StartsText('Tfrm', DeclaredType) or
    EndsText('Form', DeclaredType) or
    EndsText('Frm', DeclaredType);
end;

procedure TAutoFixRewriter.DiscoverDeclaredTypeMaps(ALines: TStrings;
  AControlTypes, AGenericListFields: TDictionary<string, string>);
var
  DeclIndex: Integer;
  DeclMatch: TMatch;
  NameParts: TStringList;
  NamePart: string;
  DeclType: string;
begin
  if not Assigned(ALines) or not Assigned(AControlTypes) or
     not Assigned(AGenericListFields) then
    Exit;

  NameParts := TStringList.Create;
  try
    NameParts.StrictDelimiter := True;
    NameParts.Delimiter := ',';

    for DeclIndex := 0 to ALines.Count - 1 do
    begin
      if SameText(Trim(ALines[DeclIndex]), 'implementation') then
        Break;

      if StartsRoutine(ALines[DeclIndex]) then
        Continue;

      DeclMatch := TRegEx.Match(ALines[DeclIndex],
        '^\s*([A-Za-z_][A-Za-z0-9_,\s]*)\s*:\s*(T[A-Za-z_][A-Za-z0-9_\.]*)\s*;\s*$');
      if DeclMatch.Success then
      begin
        DeclType := DeclMatch.Groups[2].Value;
        NameParts.DelimitedText := DeclMatch.Groups[1].Value;
        for NamePart in NameParts do
          if Trim(NamePart) <> '' then
            AControlTypes.AddOrSetValue(Trim(NamePart), DeclType);
      end;

      DeclMatch := TRegEx.Match(ALines[DeclIndex],
        '^\s*([A-Za-z_][A-Za-z0-9_,\s]*)\s*:\s*(T(?:Object)?List<.+>)\s*;\s*$');
      if not DeclMatch.Success then
        Continue;

      DeclType := Trim(DeclMatch.Groups[2].Value);
      NameParts.DelimitedText := DeclMatch.Groups[1].Value;
      for NamePart in NameParts do
        if Trim(NamePart) <> '' then
          AGenericListFields.AddOrSetValue(Trim(NamePart), DeclType);
    end;
  finally
    NameParts.Free;
  end;
end;

function TAutoFixRewriter.RewriteTypedMemberAccess(const S: string;
  AControlTypes: TDictionary<string, string>): string;
var
  Matches: TMatchCollection;
  Match: TMatch;
  Pair: TPair<string, string>;
  DeclaredType: string;
  Identifier: string;
  PropName: string;
  OldText: string;
  NewText: string;
begin
  Result := S;
  if not Assigned(AControlTypes) then
    Exit;

  for Pair in AControlTypes do
  begin
    Identifier := Pair.Key;
    DeclaredType := Pair.Value;

    if SameText(DeclaredType, 'TMemo') then
      Result := TRegEx.Replace(Result,
        '\b' + TRegEx.Escape(Identifier) + '\.Clear\s*;',
        Identifier + '.Lines.Clear;', [roIgnoreCase]);

    if SameText(DeclaredType, 'TBitmap') or
       SameText(DeclaredType, 'TPngImage') or
       SameText(DeclaredType, 'FMX.Graphics.TBitmap') then
    begin
      Result := TRegEx.Replace(Result,
        '\b' + TRegEx.Escape(Identifier) + '\.Empty\b',
        Identifier + '.IsEmpty', [roIgnoreCase]);
    end;

    if SupportsPositionRewrite(DeclaredType) then
    begin
      Result := TRegEx.Replace(Result,
        '\b' + TRegEx.Escape(Identifier) + '\.Left(?=\s*:=)',
        Identifier + '.Position.X', [roIgnoreCase]);
      Result := TRegEx.Replace(Result,
        '\b' + TRegEx.Escape(Identifier) + '\.Top(?=\s*:=)',
        Identifier + '.Position.Y', [roIgnoreCase]);
      Result := TRegEx.Replace(Result,
        '\b' + TRegEx.Escape(Identifier) + '\.Left\b',
        'Round(' + Identifier + '.Position.X)', [roIgnoreCase]);
      Result := TRegEx.Replace(Result,
        '\b' + TRegEx.Escape(Identifier) + '\.Top\b',
        'Round(' + Identifier + '.Position.Y)', [roIgnoreCase]);
    end;

    if SameText(DeclaredType, 'TTrackBar') or
       SameText(DeclaredType, 'TProgressBar') or
       SameText(DeclaredType, 'TUpDown') or
       SameText(DeclaredType, 'TSpinEdit') or
       SameText(DeclaredType, 'TSpinBox') then
    begin
      Result := TRegEx.Replace(Result,
        '\b' + TRegEx.Escape(Identifier) + '\.Position(?=\s*:=)',
        Identifier + '.Value', [roIgnoreCase]);
      Result := TRegEx.Replace(Result,
        '\b' + TRegEx.Escape(Identifier) + '\.Position\b',
        'Round(' + Identifier + '.Value)', [roIgnoreCase]);
    end;

    if UsesTextInsteadOfCaption(DeclaredType) then
      Result := TRegEx.Replace(Result,
        '\b' + TRegEx.Escape(Identifier) + '\.Caption\b',
        Identifier + '.Text', [roIgnoreCase]);

    if UsesCaptionInsteadOfText(DeclaredType) then
      Result := TRegEx.Replace(Result,
        '\b' + TRegEx.Escape(Identifier) + '\.Text\b',
        Identifier + '.Caption', [roIgnoreCase]);
  end;

  Matches := TRegEx.Matches(Result,
    '\b([A-Za-z_][A-Za-z0-9_]*)\.(Position|MinValue|MaxValue|Decimal)\b',
    [roIgnoreCase]);
  for Match in Matches do
  begin
    Identifier := Match.Groups[1].Value;
    PropName := Match.Groups[2].Value;
    DeclaredType := GetDeclaredControlType(AControlTypes, Identifier);
    OldText := Match.Value;
    NewText := OldText;

    if SameText(PropName, 'MinValue') and
            (SameText(DeclaredType, 'TSpinEdit') or
             SameText(DeclaredType, 'TSpinBox') or
             SameText(DeclaredType, 'TNumberBox')) then
      NewText := Identifier + '.Min'
    else if SameText(PropName, 'MaxValue') and
            (SameText(DeclaredType, 'TSpinEdit') or
             SameText(DeclaredType, 'TSpinBox') or
             SameText(DeclaredType, 'TNumberBox')) then
      NewText := Identifier + '.Max'
    else if SameText(PropName, 'Decimal') and SameText(DeclaredType, 'TNumberBox') then
      NewText := Identifier + '.DecimalDigits';

    if NewText <> OldText then
      Result := StringReplace(Result, OldText, NewText, [rfReplaceAll]);
  end;

  Matches := TRegEx.Matches(Result,
    '\b([A-Za-z_][A-Za-z0-9_]*)\.Font\.(Name|Height)\b',
    [roIgnoreCase]);
  for Match in Matches do
  begin
    Identifier := Match.Groups[1].Value;
    PropName := Match.Groups[2].Value;
    DeclaredType := GetDeclaredControlType(AControlTypes, Identifier);
    OldText := Match.Value;
    NewText := OldText;

    if SameText(DeclaredType, 'TFontDialog') then
    begin
      if SameText(PropName, 'Name') then
        NewText := Identifier + '.Font.Family'
      else if SameText(PropName, 'Height') then
        NewText := Identifier + '.Font.Size';
    end;

    if NewText <> OldText then
      Result := StringReplace(Result, OldText, NewText, [rfReplaceAll]);
  end;
end;

function TAutoFixRewriter.SignatureEndsDeclaration(const S: string): Boolean;
var
  Trimmed: string;
  OpenParenCount: Integer;
  CloseParenCount: Integer;
begin
  Trimmed := TrimRight(StripManualReviewPrefix(S));
  OpenParenCount := Length(Trimmed) -
    Length(StringReplace(Trimmed, '(', '', [rfReplaceAll]));
  CloseParenCount := Length(Trimmed) -
    Length(StringReplace(Trimmed, ')', '', [rfReplaceAll]));

  Result := (OpenParenCount <= CloseParenCount) and
    TRegEx.IsMatch(Trimmed,
      '\)\s*;\s*((message\s+[A-Za-z_][A-Za-z0-9_]*\s*;|' +
      '(override|virtual|dynamic|reintroduce|abstract|overload|stdcall|cdecl|safecall|register)\s*;)\s*)*(//.*)?$',
      [roIgnoreCase]);
end;

function TAutoFixRewriter.IsPascalStructuralBoundary(const S: string;
  IncludeSectionKeywords: Boolean): Boolean;
var
  PlainLine: string;
begin
  PlainLine := Trim(StripManualReviewPrefix(S));

  Result :=
    SameText(PlainLine, 'implementation') or
    SameText(PlainLine, 'initialization') or
    SameText(PlainLine, 'finalization') or
    SameText(PlainLine, 'end.') or
    StartsRoutine(PlainLine);

  if not Result and IncludeSectionKeywords then
    Result :=
      SameText(PlainLine, 'private') or
      SameText(PlainLine, 'protected') or
      SameText(PlainLine, 'public') or
      SameText(PlainLine, 'published') or
      SameText(PlainLine, 'strict private') or
      SameText(PlainLine, 'strict protected') or
      SameText(PlainLine, 'var') or
      SameText(PlainLine, 'const') or
      SameText(PlainLine, 'type');
end;

function TAutoFixRewriter.IsLegacyGridDrawSignature(const S, NextS: string): Boolean;
var
  Combined: string;
  TrimmedS: string;
  TrimmedNext: string;
  OpenParenCount: Integer;
  CloseParenCount: Integer;
begin
  TrimmedS := Trim(StripManualReviewPrefix(S));
  TrimmedNext := Trim(StripManualReviewPrefix(NextS));
  Combined := TrimmedS;
  OpenParenCount := Length(TrimmedS) -
    Length(StringReplace(TrimmedS, '(', '', [rfReplaceAll]));
  CloseParenCount := Length(TrimmedS) -
    Length(StringReplace(TrimmedS, ')', '', [rfReplaceAll]));
  if (TrimmedNext <> '') and (OpenParenCount > CloseParenCount) and
     not StartsRoutine(TrimmedNext) and
     not SameText(TrimmedNext, 'implementation') then
    Combined := Combined + ' ' + TrimmedNext;
  Result := TRegEx.IsMatch(Combined, '\bDrawColumnCell\b', [roIgnoreCase]) and
    (TRegEx.IsMatch(Combined, '\bRect\s*:\s*TRect\b', [roIgnoreCase]) or
     TRegEx.IsMatch(Combined, '\bDataCol\s*:\s*Integer\b', [roIgnoreCase]) or
     TRegEx.IsMatch(Combined, '\bState\s*:\s*TGridDrawState\b', [roIgnoreCase]));
end;

function TAutoFixRewriter.IsUnsupportedMessageHandlerSignature(
  const S, NextS: string): Boolean;
var
  Combined: string;
  TrimmedS: string;
  TrimmedNext: string;
  OpenParenCount: Integer;
  CloseParenCount: Integer;
begin
  TrimmedS := Trim(StripManualReviewPrefix(S));
  TrimmedNext := Trim(StripManualReviewPrefix(NextS));
  Combined := TrimmedS;
  OpenParenCount := Length(TrimmedS) -
    Length(StringReplace(TrimmedS, '(', '', [rfReplaceAll]));
  CloseParenCount := Length(TrimmedS) -
    Length(StringReplace(TrimmedS, ')', '', [rfReplaceAll]));
  if (TrimmedNext <> '') and
     (((OpenParenCount > CloseParenCount) and
       not StartsRoutine(TrimmedNext) and
       not SameText(TrimmedNext, 'implementation')) or
      StartsText('message ', TrimmedNext)) then
    Combined := Combined + ' ' + TrimmedNext;
  Result := TRegEx.IsMatch(Combined, '(^|[;\s])message\s+[A-Za-z_][A-Za-z0-9_]*', [roIgnoreCase]) or
    TRegEx.IsMatch(Combined, '\bTWM[A-Za-z0-9_]*\b', [roIgnoreCase]) or
    TRegEx.IsMatch(Combined, '\bTCM[A-Za-z0-9_]*\b', [roIgnoreCase]);
end;

function TAutoFixRewriter.StripManualReviewPrefix(const S: string): string;
var
  Trimmed: string;
begin
  Trimmed := TrimLeft(S);
  while StartsText('// FMX manual review:', Trimmed) do
    Trimmed := Trim(Copy(Trimmed, Length('// FMX manual review:') + 1, MaxInt));
  Result := Trimmed;
end;

function TAutoFixRewriter.AddManualReviewPrefix(const S: string): string;
begin
  if StartsText('// FMX manual review:', TrimLeft(S)) then
    Result := S
  else
    Result := '  // FMX manual review: ' + TrimLeft(S);
end;

procedure TAutoFixRewriter.MarkLineForManualReview(var Line: string;
  ALineNumber: Integer; const AProblemType, AMessage, ASuggestedFix: string);
var
  OriginalLine: string;
begin
  OriginalLine := Line;
  Line := AddManualReviewPrefix(Line);

  if Assigned(FContext) and
     not StartsText('// FMX manual review:', TrimLeft(OriginalLine)) then
    FContext.AddManualReview(AProblemType, AMessage, Trim(OriginalLine),
      ASuggestedFix, ALineNumber, False);
end;

procedure TAutoFixRewriter.FixMalformedFieldEndings(ALines: TStringList);
var
  i: Integer;
  L: string;
  FieldIndent: string;
  EndIndent: string;
begin
  if not Assigned(ALines) then
    Exit;

  i := 0;
  while i < ALines.Count do
  begin
    L := ALines[i];
    if TRegEx.IsMatch(L,
      '^(\s*[A-Za-z_][A-Za-z0-9_,\s]*:\s*[A-Za-z_][A-Za-z0-9_\.<>]*)\s+end;$') then
    begin
      FieldIndent := Copy(L, 1, Length(L) - Length(TrimLeft(L)));
      if Length(FieldIndent) >= 2 then
        EndIndent := Copy(FieldIndent, 1, Length(FieldIndent) - 2)
      else
        EndIndent := '';

      ALines[i] := TRegEx.Replace(L,
        '^(\s*[A-Za-z_][A-Za-z0-9_,\s]*:\s*[A-Za-z_][A-Za-z0-9_\.<>]*)\s+end;$',
        '$1;');
      ALines.Insert(i + 1, EndIndent + 'end;');
      Inc(i);
    end;
    Inc(i);
  end;
end;

procedure TAutoFixRewriter.MarkUnsupportedPascalRoutinesForReview(
  ALines: TStringList);
var
  AnalysisLines: TStringList;
  i: Integer;
  L: string;
  AnalysisLine: string;
  NextLine: string;
  NextAnalysisLine: string;
  ReviewLine: string;
  InImplementationSection: Boolean;
  InUnsupportedGridHandler: Boolean;
  InUnsupportedMessageHandler: Boolean;
  InUnsupportedSignature: Boolean;
  PendingUnsupportedGridHandler: Boolean;
  PendingUnsupportedMessageHandler: Boolean;
  UnsupportedRoutineDepth: Integer;
  procedure UpdateUnsupportedRoutineDepth(const S: string);
  var
    PlainLine: string;
  begin
    PlainLine := Trim(StripManualReviewPrefix(S));
    if (PlainLine = '') or StartsText('//', PlainLine) then
      Exit;

    if TRegEx.IsMatch(PlainLine, '^(begin|case\b|try\b|repeat\b)', [roIgnoreCase]) then
      Inc(UnsupportedRoutineDepth);
    if TRegEx.IsMatch(PlainLine, '^(end\b|until\b)', [roIgnoreCase]) then
      Dec(UnsupportedRoutineDepth);
  end;

begin
  if not Assigned(ALines) then
    Exit;

  AnalysisLines := TStringList.Create;
  try
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(ALines.Text);
    InImplementationSection := False;
    InUnsupportedGridHandler := False;
    InUnsupportedMessageHandler := False;
    InUnsupportedSignature := False;
    PendingUnsupportedGridHandler := False;
    PendingUnsupportedMessageHandler := False;
    UnsupportedRoutineDepth := 0;

    for i := 0 to ALines.Count - 1 do
    begin
      L := ALines[i];
      if i < AnalysisLines.Count then
        AnalysisLine := AnalysisLines[i]
      else
        AnalysisLine := L;

      if SameText(Trim(AnalysisLine), 'implementation') then
        InImplementationSection := True;

      if InUnsupportedSignature then
      begin
        if IsPascalStructuralBoundary(AnalysisLine, True) then
        begin
          InUnsupportedSignature := False;
          PendingUnsupportedGridHandler := False;
          PendingUnsupportedMessageHandler := False;
        end;
        if InUnsupportedSignature then
        begin
          MarkLineForManualReview(L, i + 1, 'Unsupported routine signature',
            'Routine signature needs FMX manual review.',
            'Review the signature and replace unsupported VCL-only parameters or message declarations with an FMX event-based equivalent.');
          ALines[i] := L;
          if SignatureEndsDeclaration(StripManualReviewPrefix(AnalysisLine)) then
          begin
            InUnsupportedSignature := False;
            if InImplementationSection then
            begin
              InUnsupportedGridHandler := PendingUnsupportedGridHandler;
              InUnsupportedMessageHandler := PendingUnsupportedMessageHandler;
              UnsupportedRoutineDepth := 0;
            end;
            PendingUnsupportedGridHandler := False;
            PendingUnsupportedMessageHandler := False;
          end;
          Continue;
        end;
      end;

      if InUnsupportedGridHandler then
      begin
        if IsPascalStructuralBoundary(AnalysisLine, False) then
        begin
          InUnsupportedGridHandler := False;
          UnsupportedRoutineDepth := 0;
        end
        else
        begin
          MarkLineForManualReview(L, i + 1, 'Grid owner-draw handler',
            'Legacy VCL grid drawing code needs FMX manual review.',
            'Replace VCL grid drawing logic with FMX grid styling, cell presentation, or a custom FMX drawing approach.');
          ALines[i] := L;
          UpdateUnsupportedRoutineDepth(AnalysisLine);
          if (UnsupportedRoutineDepth <= 0) and SameText(Trim(StripManualReviewPrefix(AnalysisLine)), 'end;') then
            InUnsupportedGridHandler := False;
          Continue;
        end;
      end;

      if InUnsupportedMessageHandler then
      begin
        if IsPascalStructuralBoundary(AnalysisLine, False) then
        begin
          InUnsupportedMessageHandler := False;
          UnsupportedRoutineDepth := 0;
        end
        else
        begin
          MarkLineForManualReview(L, i + 1, 'Windows messages or message handlers',
            'Windows message-based behavior needs FMX manual review.',
            'Replace the VCL message handler with FMX events, form lifecycle events, or platform-specific services where needed.');
          ALines[i] := L;
          UpdateUnsupportedRoutineDepth(AnalysisLine);
          if (UnsupportedRoutineDepth <= 0) and SameText(Trim(StripManualReviewPrefix(AnalysisLine)), 'end;') then
            InUnsupportedMessageHandler := False;
          Continue;
        end;
      end;


      NextLine := '';
      NextAnalysisLine := '';
      if i < ALines.Count - 1 then
        NextLine := ALines[i + 1];
      if i < AnalysisLines.Count - 1 then
        NextAnalysisLine := AnalysisLines[i + 1]
      else
        NextAnalysisLine := NextLine;

      if StartsText('//', TrimLeft(L)) then
      begin
        ReviewLine := StripManualReviewPrefix(L);
        if StartsRoutine(ReviewLine) and
           IsLegacyGridDrawSignature(ReviewLine, NextAnalysisLine) then
        begin
          PendingUnsupportedGridHandler := True;
          PendingUnsupportedMessageHandler := False;
          if SignatureEndsDeclaration(ReviewLine) then
          begin
            if InImplementationSection then
            begin
              InUnsupportedGridHandler := True;
              UnsupportedRoutineDepth := 0;
            end;
          end
          else
            InUnsupportedSignature := True;
        end
        else if StartsRoutine(ReviewLine) and
                IsUnsupportedMessageHandlerSignature(ReviewLine, NextAnalysisLine) then
        begin
          PendingUnsupportedGridHandler := False;
          PendingUnsupportedMessageHandler := True;
          if SignatureEndsDeclaration(ReviewLine) then
          begin
            if InImplementationSection then
            begin
              InUnsupportedMessageHandler := True;
              UnsupportedRoutineDepth := 0;
            end;
          end
          else
            InUnsupportedSignature := True;
        end;
        Continue;
      end;

      if Trim(AnalysisLine) = '' then
        Continue;

      if StartsRoutine(AnalysisLine) and
         IsLegacyGridDrawSignature(AnalysisLine, NextAnalysisLine) then
      begin
        MarkLineForManualReview(L, i + 1, 'Grid owner-draw handler',
          'Legacy VCL grid drawing code needs FMX manual review.',
          'Replace VCL grid drawing logic with FMX grid styling, cell presentation, or a custom FMX drawing approach.');
        ALines[i] := L;
        PendingUnsupportedGridHandler := True;
        PendingUnsupportedMessageHandler := False;
        if SignatureEndsDeclaration(AnalysisLine) then
        begin
          if InImplementationSection then
          begin
            InUnsupportedGridHandler := True;
            UnsupportedRoutineDepth := 0;
          end;
        end
        else
          InUnsupportedSignature := True;
        Continue;
      end;

      if StartsRoutine(AnalysisLine) and
         IsUnsupportedMessageHandlerSignature(AnalysisLine, NextAnalysisLine) then
      begin
        MarkLineForManualReview(L, i + 1, 'Windows messages or message handlers',
          'Windows message-based behavior needs FMX manual review.',
          'Replace the VCL message handler with FMX events, form lifecycle events, or platform-specific services where needed.');
        ALines[i] := L;
        PendingUnsupportedGridHandler := False;
        PendingUnsupportedMessageHandler := True;
        if SignatureEndsDeclaration(AnalysisLine) then
        begin
          if InImplementationSection then
          begin
            InUnsupportedMessageHandler := True;
            UnsupportedRoutineDepth := 0;
          end;
        end
        else
          InUnsupportedSignature := True;
        Continue;
      end;
    end;
  finally
    AnalysisLines.Free;
  end;
end;

function TAutoFixRewriter.HandleTrayStartupRewrite(ALines: TStringList;
  const LineIndex: Integer; AControlTypes: TDictionary<string, string>;
  var Line: string; var PendingTrayHideSuppress: Boolean): Boolean;
var
  TrayUsageMatch: TMatch;
begin
  Result := False;

  if TRegEx.IsMatch(Line,
       '^\s*[A-Za-z_][A-Za-z0-9_,\s]*\s*:\s*TTrayIcon\s*;\s*$',
       [roIgnoreCase]) then
  begin
    Line := '';
    ALines[LineIndex] := Line;
    Exit(True);
  end;

  if TRegEx.IsMatch(Line, '\bApplication\.ShowMainForm\s*:=\s*(True|False)\s*;', [roIgnoreCase]) then
  begin
    Line := '';
    ALines[LineIndex] := Line;
    Exit(True);
  end;

  TrayUsageMatch := TRegEx.Match(Line,
    '\b([A-Za-z_][A-Za-z0-9_]*)\.(Visible|PopupMenu|Icon|Hint)\b',
    [roIgnoreCase]);
  if TrayUsageMatch.Success and
     SameText(GetDeclaredControlType(AControlTypes, TrayUsageMatch.Groups[1].Value), 'TTrayIcon') then
  begin
    PendingTrayHideSuppress := TRegEx.IsMatch(Line, '\.Visible\s*:=\s*True\s*;', [roIgnoreCase]);
    Line := '';
    ALines[LineIndex] := Line;
    Exit(True);
  end;

  if PendingTrayHideSuppress then
  begin
    if SameText(Trim(Line), 'Hide;') then
    begin
      Line := Copy(Line, 1, Length(Line) - Length(TrimLeft(Line))) +
        'WindowState := TWindowState.wsMinimized;';
      PendingTrayHideSuppress := False;
      ALines[LineIndex] := Line;
      Exit(True);
    end;

    if (Trim(Line) <> '') and not StartsText('//', TrimLeft(Line)) then
      PendingTrayHideSuppress := False;
  end;
end;

procedure TAutoFixRewriter.SplitTrailingBlockComment(var ALine: string; out ASuffix: string);
var
  P: Integer;
  InString: Boolean;
begin
  ASuffix := '';
  InString := False;
  P := 1;
  while P <= Length(ALine) do
  begin
    if ALine[P] = '''' then
    begin
      if not InString then
        InString := True
      else if (P < Length(ALine)) and (ALine[P + 1] = '''') then
      begin
        Inc(P, 2);
        Continue;
      end
      else
        InString := False;
    end
    else if not InString then
    begin
      if ((ALine[P] = '{') and not ((P < Length(ALine)) and (ALine[P + 1] = '$'))) or
         ((P < Length(ALine)) and (ALine[P] = '(') and (ALine[P + 1] = '*')) then
      begin
        ASuffix := Copy(ALine, P, MaxInt);
        ALine := Copy(ALine, 1, P - 1);
        Exit;
      end;
    end;
    Inc(P);
  end;
end;

procedure TAutoFixRewriter.ApplyBasicTypeAndPropertyRewrites(var Line: string;
  const AnalysisLine: string; AControlTypes: TDictionary<string, string>);
const
  RewriteTokens: array[0..39] of string = (
    'Self.Caption', '{$R *.dfm}', 'FireDAC.VCLUI.Wait', 'AForm.Position.X',
    'AForm.Position.Y', 'TBitmap', 'TColor', 'TPanel', 'TGroupBox',
    'TPageControl', 'TTabSheet', 'TMainMenu', 'TDBGrid', 'TDBNavigator',
    'TNavigateBtn', 'TNavButtonSet', 'TBitBtn', 'TDBEdit', 'TDBCheckBox',
    'TDBComboBox', 'TDateTimePicker', 'TSpinEdit', 'TUpDown', 'TColorBox',
    '.OnCloseUp', 'TFileOpenDialog', '.Duration', 'CellClick', 'TColumn',
    '.SelStart', '.SelLength', '.TextSettings', '.Canvas', '.Picture',
    '.Stretch', '.Proportional', '.Caption', '.Left', '.Top', '.Position');
var
  Token: string;
  ShouldRewrite: Boolean;
begin
  ShouldRewrite := False;
  for Token in RewriteTokens do
    if ContainsText(AnalysisLine, Token) then
    begin
      ShouldRewrite := True;
      Break;
    end;

  if not ShouldRewrite then
    Exit;

  Line := TRegEx.Replace(Line, '\bSelf\.Caption\b',
    '__VCL2FMX_SELF_CAPTION__', [roIgnoreCase]);
  Line := StringReplace(Line, '{$R *.dfm}', '{$R *.fmx}', [rfIgnoreCase]);
  Line := StringReplace(Line, 'FireDAC.VCLUI.Wait', 'FireDAC.FMXUI.Wait', [rfReplaceAll]);
  Line := StringReplace(Line, 'AForm.Position.X', 'AForm.Left', [rfReplaceAll]);
  Line := StringReplace(Line, 'AForm.Position.Y', 'AForm.Top', [rfReplaceAll]);
  Line := TRegEx.Replace(Line, '(:\s*)TBitmap(\s*[;=,\)])', '$1FMX.Graphics.TBitmap$2', [roIgnoreCase]);
  Line := TRegEx.Replace(Line, '(?<!\.)\bTBitmap\.Create\b', 'FMX.Graphics.TBitmap.Create', [roIgnoreCase]);
  Line := TRegEx.Replace(Line, '\bTColor\b', 'TAlphaColor', [roIgnoreCase]);
  Line := TRegEx.Replace(Line, '\bTPanel\b', 'TPanel');
  Line := TRegEx.Replace(Line, '\bTGroupBox\b', 'TGroupBox');
  Line := TRegEx.Replace(Line, '\bTPageControl\b', 'TTabControl');
  Line := TRegEx.Replace(Line, '\bTTabSheet\b', 'TTabItem');
  Line := TRegEx.Replace(Line, '\bTMainMenu\b', 'TMenuBar');
  Line := TRegEx.Replace(Line, '\bTDBGrid\b', 'TStringGrid');
  Line := TRegEx.Replace(Line, '\bTDBNavigator\b', 'TBindNavigator');
  Line := TRegEx.Replace(Line, '\bTNavigateBtn\b', 'TBindNavigateBtn');
  Line := TRegEx.Replace(Line, '\bTNavButtonSet\b', 'TBindNavButtonSet');
  Line := TRegEx.Replace(Line, '\bTBitBtn\b', 'TButton', [roIgnoreCase]);
  Line := TRegEx.Replace(Line, '\bTDBEdit\b', 'TEdit');
  Line := TRegEx.Replace(Line, '\bTDBCheckBox\b', 'TCheckBox');
  Line := TRegEx.Replace(Line, '\bTDBComboBox\b', 'TComboEdit');
  Line := TRegEx.Replace(Line, '\bTDateTimePicker\b', 'TDateEdit');
  Line := TRegEx.Replace(Line, '\bTSpinEdit\b', 'TSpinBox');
  Line := TRegEx.Replace(Line, '\bTUpDown\b', 'TSpinBox');
  Line := TRegEx.Replace(Line, '\bTColorBox\b', 'TColorComboBox');
  Line := TRegEx.Replace(Line, '\.OnCloseUp\b', '.OnClosePicker', [roIgnoreCase]);
  Line := TRegEx.Replace(Line, '\bTFileOpenDialog\b', 'TOpenDialog');
  Line := TRegEx.Replace(Line,
    '(\b[A-Za-z_][A-Za-z0-9_]*\s*:=\s*)([A-Za-z_][A-Za-z0-9_\.]*)\.Duration\s*;',
    '$1Round(($2.Duration / MediaTimeScale) * 1000);',
    [roIgnoreCase]);
  Line := TRegEx.Replace(Line,
    '(procedure\s+[\w\.]+CellClick)\(Column:\s*TColumn\);',
    '$1(const Column: TColumn; const Row: Integer);',
    [roIgnoreCase]);
  Line := RewriteTypedMemberAccess(Line, AControlTypes);
end;

procedure TAutoFixRewriter.RewriteCanvasGeometryLine(var Line: string;
  var InEllipseFill, InPolygonFill: Boolean);
begin
  if InEllipseFill then
  begin
    if Pos(');', Line) > 0 then
    begin
      Line := StringReplace(Line, ');', '), 1);', [rfReplaceAll]);
      InEllipseFill := False;
    end;
  end;

  if ContainsText(Line, '.Ellipse(') and
     not ContainsText(Line, '.DrawEllipse(') and
     not ContainsText(Line, '.FillEllipse(') and
     not ContainsText(Line, 'RectF(') then
  begin
    Line := StringReplace(Line, '.Ellipse(', '.FillEllipse(RectF(', [rfReplaceAll]);
    if Pos(');', Line) > 0 then
      Line := StringReplace(Line, ');', '), 1);', [rfReplaceAll])
    else
      InEllipseFill := True;
  end;

  if ContainsText(Line, '.DrawEllipse(') and not ContainsText(Line, 'RectF(') then
  begin
    Line := StringReplace(Line, '.DrawEllipse(', '.FillEllipse(RectF(', [rfReplaceAll]);
    if Pos(');', Line) > 0 then
      Line := StringReplace(Line, ');', '), 1);', [rfReplaceAll])
    else
      InEllipseFill := True;
  end;

  Line := TRegEx.Replace(Line,
    '(\b[A-Za-z_][A-Za-z0-9_\.]*)\.Ellipse\s*\((.+)\)\s*;',
    '$1.FillEllipse(RectF($2), 1);', [roIgnoreCase]);

  Line := TRegEx.Replace(Line,
    '(\b[A-Za-z_][A-Za-z0-9_\.]*)\.DrawEllipse\s*\((.+)\)\s*;',
    '$1.FillEllipse(RectF($2), 1);', [roIgnoreCase]);

  if InPolygonFill or ContainsText(Line, 'Canvas.Polygon([') or ContainsText(Line, 'Canvas.FillPolygon([') then
  begin
    Line := StringReplace(Line, 'Canvas.Polygon([', 'Canvas.FillPolygon([', [rfReplaceAll]);
    Line := StringReplace(Line, 'Point(', 'PointF(', [rfReplaceAll]);
    if ContainsText(Line, 'FillPolygon([') then
      InPolygonFill := True;
    if InPolygonFill and (Pos(']);', Line) > 0) then
    begin
      Line := StringReplace(Line, ']);', '], 1);', [rfReplaceAll]);
      InPolygonFill := False;
    end;
  end;
end;

procedure TAutoFixRewriter.RestoreNonUnsupportedManualReviewSignatures(
  ALines: TStringList);
var
  i: Integer;
  ReviewLine: string;
  NextLine: string;
begin
  if not Assigned(ALines) then
    Exit;

  for i := 0 to ALines.Count - 1 do
  begin
    if SameText(Trim(ALines[i]), 'implementation') then
      Break;

    if SameText(Trim(ALines[i]), 'interface') then
      Continue;

    if StartsText('// FMX manual review:', TrimLeft(ALines[i])) then
    begin
      NextLine := '';
      if i < ALines.Count - 1 then
        NextLine := StripManualReviewPrefix(ALines[i + 1]);
      ReviewLine := StripManualReviewPrefix(ALines[i]);
      if StartsRoutine(ReviewLine) and
         not (IsUnsupportedMessageHandlerSignature(ReviewLine, NextLine) or
              IsLegacyGridDrawSignature(ReviewLine, NextLine)) then
        ALines[i] := '    ' + ReviewLine;
    end;
  end;
end;

procedure TAutoFixRewriter.InsertWindowsMessageHelperBlock(var Code: string);
var
  Lines: TStringList;
  HelperLines: TStringList;
  InsertIdx: Integer;
  I: Integer;
  Trimmed: string;
begin
  if not (ContainsText(Code, 'GeneratedFMXMemoLineScroll(') or
          ContainsText(Code, 'GeneratedFMXMemoLineFromChar(') or
          ContainsText(Code, 'GeneratedFMXListBoxSelectString(') or
          ContainsText(Code, 'GeneratedFMXMemoVScroll(')) then
    Exit;

  if ContainsText(Code, 'function GeneratedFMXMemoLineFromChar(') then
    Exit;

  Lines := TStringList.Create;
  HelperLines := TStringList.Create;
  try
    Lines.Text := Code;
    InsertIdx := -1;

    for I := 0 to Lines.Count - 1 do
      if SameText(Trim(Lines[I]), 'implementation') then
      begin
        InsertIdx := I + 1;
        Break;
      end;

    if InsertIdx = -1 then
      Exit;

    while (InsertIdx < Lines.Count) and (Trim(Lines[InsertIdx]) = '') do
      Inc(InsertIdx);

    if (InsertIdx < Lines.Count) and StartsText('uses', Trim(Lines[InsertIdx])) then
    begin
      while (InsertIdx < Lines.Count) and (Pos(';', Lines[InsertIdx]) = 0) do
        Inc(InsertIdx);
      if InsertIdx < Lines.Count then
        Inc(InsertIdx);
    end;

    while InsertIdx < Lines.Count do
    begin
      Trimmed := Trim(Lines[InsertIdx]);
      if (Trimmed = '') or StartsText('{$R ', Trimmed) then
        Inc(InsertIdx)
      else
        Break;
    end;

    HelperLines.Add('');
    HelperLines.Add('{ Generated Windows-message compatibility helpers.');
    HelperLines.Add('  These replace common VCL Perform/SendMessage patterns with compile-safe FMX code. }');
    HelperLines.Add('function GeneratedFMXMemoLineScroll(const AMemo: TMemo; const ADelta: Integer): NativeInt;');
    HelperLines.Add('begin');
    HelperLines.Add('  Result := 0;');
    HelperLines.Add('  if AMemo = nil then');
    HelperLines.Add('    Exit;');
    HelperLines.Add('  if ADelta > 0 then');
    HelperLines.Add('    AMemo.GoToTextEnd;');
    HelperLines.Add('end;');
    HelperLines.Add('');
    HelperLines.Add('function GeneratedFMXMemoLineFromChar(const AMemo: TMemo; const ACharIndex: Integer): Integer;');
    HelperLines.Add('var');
    HelperLines.Add('  I: Integer;');
    HelperLines.Add('  Limit: Integer;');
    HelperLines.Add('  S: string;');
    HelperLines.Add('begin');
    HelperLines.Add('  Result := 0;');
    HelperLines.Add('  if AMemo = nil then');
    HelperLines.Add('    Exit;');
    HelperLines.Add('  S := AMemo.Text;');
    HelperLines.Add('  Limit := ACharIndex;');
    HelperLines.Add('  if Limit < 0 then');
    HelperLines.Add('    Exit;');
    HelperLines.Add('  if Limit > Length(S) then');
    HelperLines.Add('    Limit := Length(S);');
    HelperLines.Add('  for I := 1 to Limit do');
    HelperLines.Add('    if S[I] = #10 then');
    HelperLines.Add('      Inc(Result);');
    HelperLines.Add('end;');
    HelperLines.Add('');
    HelperLines.Add('function GeneratedFMXMemoVScroll(const AMemo: TMemo; const AScrollCode: string; const APos: NativeInt): NativeInt;');
    HelperLines.Add('var');
    HelperLines.Add('  Code: string;');
    HelperLines.Add('begin');
    HelperLines.Add('  Result := 0;');
    HelperLines.Add('  if AMemo = nil then');
    HelperLines.Add('    Exit;');
    HelperLines.Add('  Code := UpperCase(AScrollCode);');
    HelperLines.Add('  if Code = ''SB_TOP'' then');
    HelperLines.Add('    AMemo.SelStart := 0');
    HelperLines.Add('  else if Code = ''SB_BOTTOM'' then');
    HelperLines.Add('    AMemo.GoToTextEnd');
    HelperLines.Add('  else if Code = ''SB_LINEDOWN'' then');
    HelperLines.Add('    GeneratedFMXMemoLineScroll(AMemo, 1)');
    HelperLines.Add('  else if Code = ''SB_LINEUP'' then');
    HelperLines.Add('    GeneratedFMXMemoLineScroll(AMemo, -1);');
    HelperLines.Add('end;');
    HelperLines.Add('');
    HelperLines.Add('function GeneratedFMXListBoxSelectString(const AListBox: TListBox; const AText: string): Integer;');
    HelperLines.Add('var');
    HelperLines.Add('  I: Integer;');
    HelperLines.Add('  SearchText: string;');
    HelperLines.Add('  ItemText: string;');
    HelperLines.Add('begin');
    HelperLines.Add('  Result := -1;');
    HelperLines.Add('  if AListBox = nil then');
    HelperLines.Add('    Exit;');
    HelperLines.Add('  SearchText := UpperCase(AText);');
    HelperLines.Add('  for I := 0 to AListBox.Items.Count - 1 do');
    HelperLines.Add('  begin');
    HelperLines.Add('    ItemText := AListBox.Items[I];');
    HelperLines.Add('    if Copy(UpperCase(ItemText), 1, Length(SearchText)) = SearchText then');
    HelperLines.Add('    begin');
    HelperLines.Add('      AListBox.ItemIndex := I;');
    HelperLines.Add('      Result := I;');
    HelperLines.Add('      Exit;');
    HelperLines.Add('    end;');
    HelperLines.Add('  end;');
    HelperLines.Add('end;');
    HelperLines.Add('');

    for I := HelperLines.Count - 1 downto 0 do
      Lines.Insert(InsertIdx, HelperLines[I]);

    Code := Lines.Text;
  finally
    HelperLines.Free;
    Lines.Free;
  end;
end;

procedure TAutoFixRewriter.RewriteWindowsMessageHelperCalls(var Code: string);
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  I: Integer;
  J: Integer;
  EndIdx: Integer;
  Original: string;
  Analysis: string;
  Rewritten: string;
  Changed: Boolean;
  AnyChanged: Boolean;

  function RewriteSnippet(const SourceSnippet, AnalysisSnippet: string; out ARewritten: string): Boolean;
  begin
    ARewritten := SourceSnippet;

    ARewritten := TRegEx.Replace(ARewritten,
      '(\([^\r\n;]*?\bAs\s+TMemo\)|[A-Za-z_][A-Za-z0-9_\.]*)\.Perform\s*\(\s*EM_LINEFROMCHAR\s*,\s*(.*?)\s*,\s*0\s*\)',
      'GeneratedFMXMemoLineFromChar($1, $2)',
      [roIgnoreCase, roSingleLine]);

    ARewritten := TRegEx.Replace(ARewritten,
      '(\([^\r\n;]*?\bAs\s+TMemo\)|[A-Za-z_][A-Za-z0-9_\.]*)\.Perform\s*\(\s*EM_LINESCROLL\s*,\s*0\s*,\s*(.*?)\s*\)',
      'GeneratedFMXMemoLineScroll($1, $2)',
      [roIgnoreCase, roSingleLine]);

    ARewritten := TRegEx.Replace(ARewritten,
      '([A-Za-z_][A-Za-z0-9_]*)\.Perform\s*\(\s*LB_SELECTSTRING\s*,\s*(?:WPARAM\s*\(\s*)?-?1\s*\)?\s*,\s*(?:LongInt|Integer|NativeInt|LPARAM)?\s*\(\s*@?([A-Za-z_][A-Za-z0-9_]*)\s*\)\s*\)',
      'GeneratedFMXListBoxSelectString($1, $2)',
      [roIgnoreCase, roSingleLine]);

    ARewritten := TRegEx.Replace(ARewritten,
      'SendMessage\s*\(\s*(\([^\r\n;]*?\bAs\s+TMemo\)|[A-Za-z_][A-Za-z0-9_\.]*)\.Handle\s*,\s*WM_VSCROLL\s*,\s*(SB_[A-Za-z0-9_]+)\s*,\s*([^\)]+?)\s*\)',
      'GeneratedFMXMemoVScroll($1, ''$2'', $3)',
      [roIgnoreCase, roSingleLine]);

    Result := ARewritten <> SourceSnippet;
  end;
begin
  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  try
    Lines.Text := Code;
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Code);
    AnyChanged := False;
    I := 0;

    while I < Lines.Count do
    begin
      if (I >= AnalysisLines.Count) or (Trim(AnalysisLines[I]) = '') then
      begin
        Inc(I);
        Continue;
      end;

      Analysis := AnalysisLines[I];
      Original := Lines[I];
      EndIdx := I;

      if TRegEx.IsMatch(Analysis, '\b(Perform|SendMessage|PostMessage)\s*\(', [roIgnoreCase]) then
      begin
        // Analysis is extended inside the loop; the condition re-checks the grown string each pass.
        while (EndIdx < Lines.Count - 1) and
              (EndIdx < I + 5) and
              (not TRegEx.IsMatch(Analysis, '\)\s*;\s*$', [roIgnoreCase])) do
        begin
          Inc(EndIdx);
          Original := Original + ' ' + Trim(Lines[EndIdx]);
          if EndIdx < AnalysisLines.Count then
            Analysis := Analysis + ' ' + Trim(AnalysisLines[EndIdx]);
        end;

        Changed := RewriteSnippet(Original, Analysis, Rewritten);
        if Changed then
        begin
          Lines[I] := Rewritten;
          for J := I + 1 to EndIdx do
            Lines[J] := '';
          AnyChanged := True;

          if Assigned(FContext) then
            FContext.AddIssue(csInfo,
              'Windows message Perform/SendMessage pattern converted to generated FMX helper.',
              'Windows messaging',
              Trim(Original),
              'Review the generated helper if exact scroll, caret, or list-search behavior is critical.',
              -1,
              False);

          I := EndIdx + 1;
          Continue;
        end;
      end;

      Inc(I);
    end;

    if AnyChanged then
    begin
      Code := Lines.Text;
      InsertWindowsMessageHelperBlock(Code);
    end;
  finally
    AnalysisLines.Free;
    Lines.Free;
  end;
end;
procedure TAutoFixRewriter.Apply(var Code: string);
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  ControlTypes: TDictionary<string, string>;
  GenericListFields: TDictionary<string, string>;
  i: Integer;
  L: string;
  AnalysisLine: string;
  NextLine: string;
  ReviewLine: string;
  TrailingComment: string;
  InPolygonFill: Boolean;
  InEllipseFill: Boolean;
  PendingTrayHideSuppress: Boolean;
  CenterMatch: TMatch;
  ParentName: string;
  ChildName: string;
  IndentText: string;
  FreeMatch: TMatch;
  RootCreateHandler: string;
  RootShowHandler: string;
  function GetRootEventHandler(const EventName: string): string;
  begin
    Result := '';
    if Assigned(FDfmParser) and Assigned(FDfmParser.Components) and
       (FDfmParser.Components.Count > 0) and Assigned(FDfmParser.Components[0]) then
      FDfmParser.Components[0].Events.TryGetValue(EventName, Result);
    Result := Trim(Result);
  end;

  function ExtractOwningClassName(const MethodName: string): string;
  var
    Match: TMatch;
  begin
    Result := '';
    if Trim(MethodName) = '' then
      Exit;
    Match := TRegEx.Match(Lines.Text,
      '^\s*(?:procedure|function)\s+([A-Za-z_][A-Za-z0-9_]*)\.' +
      TRegEx.Escape(MethodName) + '\s*\(',
      [roIgnoreCase, roMultiLine]);
    if Match.Success then
      Result := Match.Groups[1].Value;
  end;

  function FindMethodBeginLine(const MethodName: string; out MethodIdx,
    BeginIdx: Integer): Boolean;
  var
    SearchIdx: Integer;
  begin
    Result := False;
    MethodIdx := -1;
    BeginIdx := -1;
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
        BeginIdx := SearchIdx;
        Result := True;
        Exit;
      end;
  end;

  procedure EnsureFieldInClass(const ClassName, FieldLine: string);
  var
    J: Integer;
    ClassIdx: Integer;
    PrivateIdx: Integer;
    FirstVisibilityIdx: Integer;
    EndClassIdx: Integer;
    InsertIdx: Integer;
    TrimmedLine: string;
  begin
    if (Trim(ClassName) = '') or (Trim(FieldLine) = '') then
      Exit;

    for J := 0 to Lines.Count - 1 do
      if SameText(Trim(Lines[J]), Trim(FieldLine)) then
        Exit;

    ClassIdx := -1;
    PrivateIdx := -1;
    FirstVisibilityIdx := -1;
    EndClassIdx := -1;

    for J := 0 to Lines.Count - 1 do
    begin
      TrimmedLine := Trim(Lines[J]);
      if TRegEx.IsMatch(TrimmedLine,
           '^' + TRegEx.Escape(ClassName) + '\s*=\s*class\b',
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

  procedure EnsureFormCreateRunsBeforeFormShow;
  var
    FormClassName: string;
    MethodIdx: Integer;
    BeginIdx: Integer;
    AlreadyInserted: Boolean;
    CheckIdx: Integer;
    CheckEndIdx: Integer;
  begin
    RootCreateHandler := GetRootEventHandler('OnCreate');
    RootShowHandler := GetRootEventHandler('OnShow');
    if (RootCreateHandler = '') or (RootShowHandler = '') then
      Exit;

    FormClassName := ExtractOwningClassName(RootCreateHandler);
    if FormClassName = '' then
      FormClassName := ExtractOwningClassName(RootShowHandler);
    if FormClassName = '' then
      Exit;

    EnsureFieldInClass(FormClassName, '    FGeneratedFormCreateRan: Boolean;');

    if FindMethodBeginLine(RootCreateHandler, MethodIdx, BeginIdx) then
      if not ((BeginIdx + 1 < Lines.Count) and ContainsText(Lines[BeginIdx + 1], 'FGeneratedFormCreateRan')) then
      begin
        Lines.Insert(BeginIdx + 1, '  if FGeneratedFormCreateRan then');
        Lines.Insert(BeginIdx + 2, '    Exit;');
        Lines.Insert(BeginIdx + 3, '  FGeneratedFormCreateRan := True;');
      end;

    if FindMethodBeginLine(RootShowHandler, MethodIdx, BeginIdx) then
    begin
      AlreadyInserted := False;
      CheckEndIdx := BeginIdx + 4;
      if CheckEndIdx > Lines.Count - 1 then
        CheckEndIdx := Lines.Count - 1;
      for CheckIdx := BeginIdx + 1 to CheckEndIdx do
        if ContainsText(Lines[CheckIdx], RootCreateHandler + '(Self);') then
        begin
          AlreadyInserted := True;
          Break;
        end;
      if not AlreadyInserted then
      begin
        Lines.Insert(BeginIdx + 1, '  if not FGeneratedFormCreateRan then');
        Lines.Insert(BeginIdx + 2, '    ' + RootCreateHandler + '(Self);');
      end;
    end;
  end;


  procedure MarkMultilineWindowsMessageCallsForReview;
  var
    J: Integer;
    K: Integer;
    ParenDepth: Integer;
    BlockText: string;
    ScanLine: string;
    Started: Boolean;
    EndIdx: Integer;
  begin
    J := 0;
    while J < Lines.Count do
    begin
      ScanLine := AnalysisLines[J];
      if StartsText('//', TrimLeft(Lines[J])) or
         not TRegEx.IsMatch(ScanLine, '\b(SendMessage|PostMessage)\s*\(', [roIgnoreCase]) then
      begin
        Inc(J);
        Continue;
      end;

      BlockText := '';
      ParenDepth := 0;
      Started := False;
      K := J;
      while K < Lines.Count do
      begin
        ScanLine := AnalysisLines[K];
        BlockText := BlockText + ' ' + Trim(ScanLine);
        Started := Started or TRegEx.IsMatch(ScanLine, '\b(SendMessage|PostMessage)\s*\(', [roIgnoreCase]);
        Inc(ParenDepth, TRegEx.Matches(ScanLine, '\(').Count);
        Dec(ParenDepth, TRegEx.Matches(ScanLine, '\)').Count);
        if Started and (ParenDepth <= 0) then
          Break;
        Inc(K);
      end;

      EndIdx := K;
      if (EndIdx > J) and TRegEx.IsMatch(BlockText, '\b(WM_|CM_|CN_|EM_|LB_|CB_|LVM_|TVM_|TCM_|WM_USER)\w*', [roIgnoreCase]) then
      begin
        for K := J to EndIdx do
        begin
          if (K < Lines.Count) and not StartsText('// FMX manual review:', TrimLeft(Lines[K])) then
          begin
            L := Lines[K];
            MarkLineForManualReview(L, K + 1, 'Windows messaging',
              'Windows multiline message API call needs FMX manual review.',
              'Replace the Windows message API call with an FMX event, direct control API, System.Messaging, or platform-specific service.');
            Lines[K] := L;
          end;
        end;
        AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Lines.Text);
        J := EndIdx + 1;
      end
      else
        Inc(J);
    end;
  end;
begin
  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  ControlTypes := TDictionary<string, string>.Create;
  GenericListFields := TDictionary<string, string>.Create;
  try
    Lines.Text := Code;
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Code);
    DiscoverDeclaredTypeMaps(AnalysisLines, ControlTypes, GenericListFields);
    FixMalformedFieldEndings(Lines);
    MarkUnsupportedPascalRoutinesForReview(Lines);
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Lines.Text);
    MarkMultilineWindowsMessageCallsForReview;
    InPolygonFill := False;
    InEllipseFill := False;
    PendingTrayHideSuppress := False;

    for i := 0 to Lines.Count - 1 do
    begin
      L := Lines[i];
      if i < AnalysisLines.Count then
        AnalysisLine := AnalysisLines[i]
      else
        AnalysisLine := L;

      if StartsText('//', TrimLeft(L)) then
        Continue;
      if Trim(AnalysisLine) = '' then
        Continue;

      NextLine := '';
      if i < Lines.Count - 1 then
        NextLine := Lines[i + 1];
      SplitTrailingBlockComment(L, TrailingComment);
      ApplyBasicTypeAndPropertyRewrites(L, AnalysisLine, ControlTypes);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])FindFirst\s*\(', '$1System.SysUtils.FindFirst(', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])FindNext\s*\(', '$1System.SysUtils.FindNext(', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])FindClose\s*\(', '$1System.SysUtils.FindClose(', [roIgnoreCase]);
      L := StringReplace(L, 'Self.Color :=', 'Self.Fill.Color :=', [rfReplaceAll]);
      L := StringReplace(L, 'AForm.Color :=', 'AForm.Fill.Color :=', [rfReplaceAll]);
      L := TRegEx.Replace(L, '\.Checked\b', '.IsChecked', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\.BorderStyle\s*:=\s*bsNone\b', '.BorderStyle := TFmxFormBorderStyle.None', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\.BorderStyle\s*:=\s*bsSingle\b', '.BorderStyle := TFmxFormBorderStyle.Single', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\.BorderStyle\s*:=\s*bsSizeable\b', '.BorderStyle := TFmxFormBorderStyle.Sizeable', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\.BorderStyle\s*:=\s*bsToolWindow\b', '.BorderStyle := TFmxFormBorderStyle.ToolWindow', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\.BorderStyle\s*:=\s*bsSizeToolWin\b', '.BorderStyle := TFmxFormBorderStyle.SizeToolWin', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^\s*)BorderStyle\s*:=\s*bsNone\b', '$1BorderStyle := TFmxFormBorderStyle.None', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^\s*)BorderStyle\s*:=\s*bsSingle\b', '$1BorderStyle := TFmxFormBorderStyle.Single', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^\s*)BorderStyle\s*:=\s*bsSizeable\b', '$1BorderStyle := TFmxFormBorderStyle.Sizeable', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^\s*)BorderStyle\s*:=\s*bsToolWindow\b', '$1BorderStyle := TFmxFormBorderStyle.ToolWindow', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^\s*)BorderStyle\s*:=\s*bsSizeToolWin\b', '$1BorderStyle := TFmxFormBorderStyle.SizeToolWin', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\.FormStyle\s*:=\s*fsStayOnTop\b', '.FormStyle := TFormStyle.StayOnTop', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\.FormStyle\s*:=\s*fsNormal\b', '.FormStyle := TFormStyle.Normal', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bfsModal\b', 'TFmxFormState.Modal', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\.WindowState\s*:=\s*wsMaximized\b', '.WindowState := TWindowState.wsMaximized', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\.WindowState\s*:=\s*wsMinimized\b', '.WindowState := TWindowState.wsMinimized', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\.WindowState\s*:=\s*wsNormal\b', '.WindowState := TWindowState.wsNormal', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^\s*)WindowState\s*:=\s*wsMaximized\b', '$1WindowState := TWindowState.wsMaximized', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^\s*)WindowState\s*:=\s*wsMinimized\b', '$1WindowState := TWindowState.wsMinimized', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^\s*)WindowState\s*:=\s*wsNormal\b', '$1WindowState := TWindowState.wsNormal', [roIgnoreCase]);
      L := TRegEx.Replace(L,
        '(^|[^A-Za-z0-9_\.])DeleteFile\s*\(\s*(?!PChar\b|PWideChar\b)([^)]+)\)',
        '$1System.SysUtils.DeleteFile($2)',
        [roIgnoreCase]);
      L := TRegEx.Replace(L, '\.AlphaBlend(\s*:=)', '.Transparency$1', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bApplication\.BringToFront\s*;', 'BringToFront;', [roIgnoreCase]);
      L := TRegEx.Replace(L,
        '(^\s*)Color\s*:=\s*((?:cla|cl)[A-Za-z0-9_]+|\$[0-9A-Fa-f]+)\s*;',
        '$1Self.Fill.Color := $2;',
        [roIgnoreCase]);
      L := StringReplace(L, '__VCL2FMX_SELF_CAPTION__', 'Self.Caption', [rfReplaceAll]);
      L := TRegEx.Replace(L, '\bSystem\.UITypes\.(mt[A-Za-z0-9_]+)\b', '$1', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bSystem\.UITypes\.(mb[A-Za-z0-9_]+)\b', '$1', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bSystem\.UITypes\.(mr[A-Za-z0-9_]+)\b', '$1', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mtConfirmation\b', '$1TMsgDlgType.mtConfirmation', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mtWarning\b', '$1TMsgDlgType.mtWarning', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mtError\b', '$1TMsgDlgType.mtError', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mtInformation\b', '$1TMsgDlgType.mtInformation', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mtCustom\b', '$1TMsgDlgType.mtCustom', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\[\s*mbYes\s*,\s*mbNo\s*\]', 'mbYesNo', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\[\s*mbYes\s*,\s*mbNo\s*,\s*mbCancel\s*\]', 'mbYesNoCancel', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\[\s*mbOK\s*,\s*mbCancel\s*\]', 'mbOKCancel', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\[\s*mbAbort\s*,\s*mbRetry\s*,\s*mbIgnore\s*\]', 'mbAbortRetryIgnore', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\[\s*mbAbort\s*,\s*mbIgnore\s*\]', 'mbAbortIgnore', [roIgnoreCase]);
      L := TRegEx.Replace(L,
        '\[\s*mbYes\s*,\s*mbYesToAll\s*,\s*mbNo\s*,\s*mbNoToAll\s*,\s*mbCancel\s*\]',
        'mbYesAllNoAllCancel', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbOK\b', '$1TMsgDlgBtn.mbOK', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbCancel\b', '$1TMsgDlgBtn.mbCancel', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbAbort\b', '$1TMsgDlgBtn.mbAbort', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbRetry\b', '$1TMsgDlgBtn.mbRetry', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbIgnore\b', '$1TMsgDlgBtn.mbIgnore', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbYes\b', '$1TMsgDlgBtn.mbYes', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbNo\b', '$1TMsgDlgBtn.mbNo', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbHelp\b', '$1TMsgDlgBtn.mbHelp', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbClose\b', '$1TMsgDlgBtn.mbClose', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbAll\b', '$1TMsgDlgBtn.mbAll', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbNoToAll\b', '$1TMsgDlgBtn.mbNoToAll', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbYesToAll\b', '$1TMsgDlgBtn.mbYesToAll', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbTryAgain\b', '$1TMsgDlgBtn.mbTryAgain', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbContinue\b', '$1TMsgDlgBtn.mbContinue', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])mbNone\b', '$1TMsgDlgBtn.mbNone', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*Edit\w*)\.Clear\s*;', '$1.Text := '''';', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bTThread\.Queue\s*\(\s*nil\s*,', 'TThread.Queue(nil, ', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bTThread\.Synchronize\s*\(\s*nil\s*,', 'TThread.Synchronize(nil, ', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bTThread\.CurrentThread\.Queue\s*\(', 'TThread.Queue(nil, ', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bTThread\.CurrentThread\.Synchronize\s*\(', 'TThread.Synchronize(nil, ', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bTThread\.Queue\s*\(\s*(?=procedure\b)', 'TThread.Queue(nil, ', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bTThread\.Synchronize\s*\(\s*(?=procedure\b)', 'TThread.Synchronize(nil, ', [roIgnoreCase]);
      L := TRegEx.Replace(L, 'TMenuItem\(Sender\)\.Parent\b(?!MenuItem)', 'TMenuItem(Sender).ParentMenuItem', [roIgnoreCase]);
      L := StringReplace(L, 'ParentMenu.Count', 'ParentMenu.ItemsCount', [rfReplaceAll]);
      L := StringReplace(L, '.PasswordChar := #0', '.Password := False', [rfReplaceAll]);
      L := StringReplace(L, '.PasswordChar := ''*''', '.Password := True', [rfReplaceAll]);
      L := TRegEx.Replace(L, '\.PasswordChar\s*:=\s*[^;]+;', '.Password := True;', [roIgnoreCase]);
      L := StringReplace(L, '.Font.Color', '.TextSettings.FontColor', [rfReplaceAll]);
      L := StringReplace(L, '.Picture.Bitmap', '.Bitmap', [rfReplaceAll]);
      L := StringReplace(L, '.Picture.Width', '.Bitmap.Width', [rfReplaceAll]);
      L := StringReplace(L, '.Picture.Height', '.Bitmap.Height', [rfReplaceAll]);
      L := StringReplace(L, '.Picture.Graphic', '.Bitmap', [rfReplaceAll]);
      L := TRegEx.Replace(L, '\b(\w*Image\w*)\.Picture\.(LoadFromFile|LoadFromStream|SaveToFile|SaveToStream|Assign)\s*\(', '$1.Bitmap.$2(', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*Image\w*)\.Picture\s*:=\s*nil\s*;', '$1.Bitmap.SetSize(0, 0);', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*Image\w*)\.Picture\b', '$1.Bitmap', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*Image\w*)\.Canvas\b', '$1.Bitmap.Canvas', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*Image\w*)\.Stretch\s*:=\s*True\s*;', '$1.WrapMode := TImageWrapMode.Stretch;', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*Image\w*)\.Stretch\s*:=\s*False\s*;', '$1.WrapMode := TImageWrapMode.Original;', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*Image\w*)\.Proportional\s*:=\s*True\s*;', '$1.WrapMode := TImageWrapMode.Fit;', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*Image\w*)\.Proportional\s*:=\s*False\s*;', '$1.WrapMode := TImageWrapMode.Original;', [roIgnoreCase]);
      L := TRegEx.Replace(L, 'Assigned\((\w+)\.Field\)', 'Assigned($1)', [roIgnoreCase]);
      L := TRegEx.Replace(L,
        '(\b[A-Za-z_][A-Za-z0-9_]*)\.Text\s*:=\s*\1\.Field\.DisplayText\s*;',
        '$1.Text := GeneratedGetManualFieldDisplayText($1);',
        [roIgnoreCase]);
      L := TRegEx.Replace(L,
        'SelectDirectory\s*\(\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*\[[^\]]+\]\s*\)',
        'SelectDirectory($1, $2, $3)', [roIgnoreCase]);
      if ContainsText(AnalysisLine, 'SelectDirectory(') and (i < Lines.Count - 1) then
      begin
        NextLine := Lines[i + 1];
        if TRegEx.IsMatch(NextLine, '^\s*\[[^\]]+\]\)\s*(.*)$') then
        begin
          ReviewLine := TRegEx.Replace(NextLine, '^\s*\[[^\]]+\]\)\s*(.*)$', '$1');
          L := TRegEx.Replace(L, ',\s*$', ')');
          if Trim(ReviewLine) <> '' then
            L := TrimRight(L) + ' ' + Trim(ReviewLine);
          Lines[i + 1] := '';
        end;
      end;
      L := TRegEx.Replace(L,
        '(\b[A-Za-z_][A-Za-z0-9_\.]*\.Canvas)\.Draw\s*\(\s*0\s*,\s*0\s*,\s*([A-Za-z_][A-Za-z0-9_\.]+)\s*\)\s*;',
        '$1.DrawBitmap($2, RectF(0, 0, $2.Width, $2.Height), RectF(0, 0, $2.Width, $2.Height), 1);',
        [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*MediaPlayer\w*)\.Mode\b', '$1.State', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*MediaPlayer\w*)\.Length\b', '$1.Duration', [roIgnoreCase]);
      L := TRegEx.Replace(L,
        '(\b[A-Za-z_][A-Za-z0-9_]*\s*:=\s*)([A-Za-z_][A-Za-z0-9_\.]*)\.Duration\s*div\s*1000\s*;',
        '$1Round($2.Duration / MediaTimeScale);',
        [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*MediaPlayer\w*)\.Close\b', '$1.Clear', [roIgnoreCase]);
      L := StringReplace(L, 'mpPlaying', 'TMediaState.Playing', [rfReplaceAll]);
      L := StringReplace(L, 'mpStopped', 'TMediaState.Stopped', [rfReplaceAll]);
      L := StringReplace(L, 'mpPaused', 'TMediaState.Stopped', [rfReplaceAll]);
      L := TRegEx.Replace(L, '\b(\w*MediaPlayer\w*)\.Pause\b', '$1.Stop', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(\w*MediaPlayer\w*)\.Resume\b', '$1.Play', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bGetScreenScale\b', '1', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b(resWidth|resHeight|ScreenWidth|ScreenHeight)\s*:=\s*Screen\.(Width|Height)\s*;',
        '$1 := Round(Screen.$2);', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(\b[A-Za-z_][A-Za-z0-9_\.]*\.(?:Width|Height))\s+div\s+([0-9]+)',
        '$1 / $2', [roIgnoreCase]);
      L := TRegEx.Replace(L,
        '\(\(([^()]+)\)\.((?:Width|Height|Left|Top))\s+div\s+([^)]+)\)',
        '(Trunc(($1).$2 / $3))', [roIgnoreCase]);
      L := TRegEx.Replace(L,
        '\b([A-Za-z_][A-Za-z0-9_\.]*\.(?:Width|Height|Left|Top|ItemHeight|ClientWidth|ClientHeight))\s+div\s+((?:[A-Za-z_][A-Za-z0-9_\.]*\([^)]*\))|(?:[A-Za-z_][A-Za-z0-9_\.]*\.(?:Width|Height|Left|Top|ItemHeight|ClientWidth|ClientHeight))|(?:[A-Za-z_][A-Za-z0-9_]*)|(?:[0-9]+))',
        'Trunc($1 / $2)', [roIgnoreCase]);
      CenterMatch := TRegEx.Match(L,
        '^(\s*)([A-Za-z_][A-Za-z0-9_]*)\.Position\.X\s*:=\s*\(Screen\.Width\s*-\s*([A-Za-z_][A-Za-z0-9_]*)\.Width\)\s*/\s*2\s*;$',
        [roIgnoreCase]);
      if CenterMatch.Success then
      begin
        IndentText := CenterMatch.Groups[1].Value;
        ParentName := CenterMatch.Groups[2].Value;
        ChildName := CenterMatch.Groups[3].Value;
        if not SameText(ParentName, ChildName) then
          L := IndentText + '__FMX_CENTER_LABEL_CONTAINER__(' + ParentName + ', ' + ChildName + ');';
      end;
      L := TRegEx.Replace(L,
        '(^|[^A-Za-z0-9_\.])(of(ReadOnly|OverwritePrompt|HideReadOnly|NoChangeDir|ShowHelp|NoValidate|AllowMultiSelect|ExtensionDifferent|PathMustExist|FileMustExist|CreatePrompt|ShareAware|NoReadOnlyReturn|NoTestFileCreate|NoNetworkButton|NoLongNames|OldStyleDialog|NoDereferenceLinks|EnableIncludeNotify|EnableSizing|DontAddToRecent|ForceShowHidden|ViewDetail|AutoPreview|NoValidateNoWarning|EnablePreview))\b',
        '$1TOpenOption.$2', [roIgnoreCase]);
      L := TRegEx.Replace(L,
        '(^|[^A-Za-z0-9_\.])(ofExNoPlacesBar)\b',
        '$1TOpenOptionEx.$2', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\bclBlack\b', 'claBlack', [roIgnoreCase]);
      L := StringReplace(L, '.Pen.Color', '.Stroke.Color', [rfReplaceAll]);
      L := StringReplace(L, '.Pen.Width', '.Stroke.Thickness', [rfReplaceAll]);
      L := StringReplace(L, '.Brush.Color', '.Fill.Color', [rfReplaceAll]);
      RewriteCanvasGeometryLine(L, InEllipseFill, InPolygonFill);

      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])RectF\(', '$1System.Types.RectF(', [roIgnoreCase]);
      L := TRegEx.Replace(L, '(^|[^A-Za-z0-9_\.])PointF\(', '$1System.Types.PointF(', [roIgnoreCase]);


      if ContainsText(AnalysisLine, 'DoubleBuffered') or ContainsText(AnalysisLine, '.RecreateWnd') then
        MarkLineForManualReview(L, i + 1, 'VCL window buffering',
          'VCL window-buffering behavior needs FMX manual review.',
          'Remove the VCL window-buffering call or replace it with FMX repaint/layout logic if needed.');

      FreeMatch := TRegEx.Match(L,
        '^(\s*)([A-Za-z_][A-Za-z0-9_]*)\.Free\s*;\s*$',
        [roIgnoreCase]);
      if FreeMatch.Success and GenericListFields.ContainsKey(FreeMatch.Groups[2].Value) then
      begin
        L := FreeMatch.Groups[1].Value + 'if Assigned(' + FreeMatch.Groups[2].Value +
          ') then begin ' + FreeMatch.Groups[2].Value + '.Clear; FreeAndNil(' +
          FreeMatch.Groups[2].Value + '); end;';
        Lines[i] := L;
        Continue;
      end;

      if HandleTrayStartupRewrite(Lines, i, ControlTypes, L,
           PendingTrayHideSuppress) then
        Continue;
      L := TRegEx.Replace(L,
        '(^\s*)([A-Za-z_][A-Za-z0-9_]*)\.Panels\[(\d+)\]\.Text\s*:=\s*(.+);$',
        '$1SetStatusBarPanelText($2, $3, $4);',
        [roIgnoreCase]);

      if ContainsText(AnalysisLine, '.Panels[2].Text :=') and (i < Lines.Count - 1) then
      begin
        L := TRegEx.Replace(L + ' ' + Trim(Lines[i + 1]),
          '(^\s*)([A-Za-z_][A-Za-z0-9_]*)\.Panels\[(\d+)\]\.Text\s*:=\s*(.+);$',
          '$1SetStatusBarPanelText($2, $3, $4);',
          [roIgnoreCase]);
        if ContainsText(L, 'SetStatusBarPanelText(') then
        begin
          Lines[i] := L;
          // Do not delete inside the fixed-range for-loop; blank the consumed line instead.
          Lines[i + 1] := '';
          Continue;
        end;
      end;

      L := TRegEx.Replace(L,
        '([A-Za-z_][A-Za-z0-9_\.]*)\.Panels\[(\d+)\]\.Text\b',
        'GetStatusBarPanelText($1, $2)',
        [roIgnoreCase]);

      if ContainsText(AnalysisLine, '.Panels[') then
        MarkLineForManualReview(L, i + 1, 'Status bar panel access',
          'VCL status-bar panel access needs FMX manual review.',
          'Use the generated status-bar helper when possible, or replace panel-specific behavior with an FMX layout/control structure.');

      if ContainsText(AnalysisLine, '.OnNotify') then
        MarkLineForManualReview(L, i + 1, 'Notification event',
          'VCL notification event wiring needs FMX manual review.',
          'Replace the VCL notification callback with the nearest FMX event or explicit application notification flow.');

      if ContainsText(AnalysisLine, '.AlphaBlendValue') then
      begin
        ReviewLine := TRegEx.Replace(L,
          '(^\s*)([A-Za-z_][A-Za-z0-9_\.]*)\.AlphaBlendValue\s*:=\s*([^;\r\n]+);$',
          '$1GeneratedSetAlphaBlendValue($2, $3);',
          [roIgnoreCase]);
        if ReviewLine <> L then
          L := ReviewLine
        else
          MarkLineForManualReview(L, i + 1, 'AlphaBlendValue',
            'VCL AlphaBlendValue usage needs FMX manual review.',
            'Use FMX Opacity or the generated alpha-blend helper where appropriate.');
      end;

      if TRegEx.IsMatch(AnalysisLine, '\b\w*MediaPlayer\w*\.Notify\s*:=', [roIgnoreCase]) then
        MarkLineForManualReview(L, i + 1, 'MediaPlayer notification',
          'VCL media-player notification wiring needs FMX manual review.',
          'Replace Notify assignment with FMX media events or an explicit playback-state notification flow.');

      if TRegEx.IsMatch(AnalysisLine, '\.\w*(DataSource|DataField|ListSource|ListField|KeyField)\s*:=', [roIgnoreCase]) and
         not TRegEx.IsMatch(AnalysisLine, '\bTDataSource\b', [roIgnoreCase]) then
        MarkLineForManualReview(L, i + 1, 'Data-aware property assignment',
          'Runtime VCL data-aware property assignment needs FMX manual review.',
          'Replace VCL data-aware property wiring with LiveBindings or explicit dataset/control synchronization.');

      if ContainsText(AnalysisLine, '.DataSource.DataSet.') then
        MarkLineForManualReview(L, i + 1, 'DataSource DataSet access',
          'Nested VCL DataSource.DataSet access needs FMX manual review.',
          'Review the dataset access and replace control-bound assumptions with LiveBindings or direct dataset logic.');

      L := TRegEx.Replace(L, '\b\w+\.SelectedRows\.Count\b', '0', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b\w+\.SelectedRows\.Items\[[^\]]+\]', 'Default(TBookmark)', [roIgnoreCase]);
      L := TRegEx.Replace(L, '\b\w+\.SelectedRows\.IndexOf\s*\([^\)]*\)', '-1', [roIgnoreCase]);

      if ContainsText(AnalysisLine, '.SelectedRows.Clear') then
        MarkLineForManualReview(L, i + 1, 'DBGrid selected rows',
          'VCL grid selected-row behavior needs FMX manual review.',
          'Replace VCL DBGrid selected-row logic with FMX grid selection logic or explicit dataset bookmarking.');

      if ContainsText(AnalysisLine, 'is TLayout then') and
         (i < Lines.Count - 1) and (i < AnalysisLines.Count - 1) and
         ContainsText(AnalysisLines[i + 1], 'TLayout(') and ContainsText(AnalysisLines[i + 1], '.TextSettings.') then
      begin
        L := Copy(L, 1, Length(L) - Length(TrimLeft(L))) +
          'TLayout has no TextSettings';
        MarkLineForManualReview(L, i + 1, 'TLayout TextSettings',
          'TLayout has no TextSettings property in FMX.',
          'Move text styling to the actual text control inside the layout.');
        Lines[i] := L;
        L := Lines[i + 1];
        MarkLineForManualReview(L, i + 2, 'TLayout TextSettings',
          'TLayout TextSettings access needs FMX manual review.',
          'Move text styling to the actual text control inside the layout.');
        Lines[i + 1] := L;
        Continue;
      end;

      if ContainsText(AnalysisLine, 'TLayout(') and ContainsText(AnalysisLine, '.TextSettings.') then
      begin
        MarkLineForManualReview(L, i + 1, 'TLayout TextSettings',
          'TLayout TextSettings access needs FMX manual review.',
          'Move text styling to the actual text control inside the layout.');
      end;

      if TRegEx.IsMatch(AnalysisLine, '\b\w*MediaPlayer\w*\.Open\s*;', [roIgnoreCase]) then
        L := '';

      if TRegEx.IsMatch(AnalysisLine,
           '\b([A-Za-z_][A-Za-z0-9_]*)\.Perform\s*\(\s*EM_SCROLLCARET\s*,\s*0\s*,\s*0\s*\)\s*;',
           [roIgnoreCase]) then
        L := TRegEx.Replace(L,
          '\b([A-Za-z_][A-Za-z0-9_]*)\.Perform\s*\(\s*EM_SCROLLCARET\s*,\s*0\s*,\s*0\s*\)\s*;',
          '$1.GoToTextEnd;', [roIgnoreCase]);

      if TRegEx.IsMatch(AnalysisLine,
           '\b([A-Za-z_][A-Za-z0-9_]*)\.Perform\s*\(\s*EM_LINESCROLL\s*,\s*0\s*,\s*\1\.Lines\.Count\s*\)\s*;',
           [roIgnoreCase]) then
        L := TRegEx.Replace(L,
          '\b([A-Za-z_][A-Za-z0-9_]*)\.Perform\s*\(\s*EM_LINESCROLL\s*,\s*0\s*,\s*\1\.Lines\.Count\s*\)\s*;',
          '$1.GoToTextEnd;', [roIgnoreCase]);

      if TRegEx.IsMatch(AnalysisLine,
           '\b[A-Za-z_][A-Za-z0-9_]*\.Perform\s*\(\s*WM_VSCROLL\s*,\s*SB_BOTTOM\s*,\s*0\s*\)\s*;',
           [roIgnoreCase]) then
        L := '';

      L := TRegEx.Replace(L,
        '\b([A-Za-z_][A-Za-z0-9_]*)\.Invalidate\s*;',
        '$1.Repaint;', [roIgnoreCase]);

      if TRegEx.IsMatch(AnalysisLine,
           '\b([A-Za-z_][A-Za-z0-9_]*)\.Shape\s*:=\s*st(Circle|Ellipse)\s*;',
           [roIgnoreCase]) then
        L := TRegEx.Replace(L,
          '\b([A-Za-z_][A-Za-z0-9_]*)\.Shape\s*:=\s*st(Circle|Ellipse)\s*;',
          '// FMX: redundant VCL Shape assignment omitted; $1 is generated as TEllipse.',
          [roIgnoreCase])
      else if TRegEx.IsMatch(AnalysisLine,
           '\b([A-Za-z_][A-Za-z0-9_]*)\.Shape\s*:=\s*st(Rectangle|Square|RoundRect|RoundSquare)\s*;',
           [roIgnoreCase]) then
        MarkLineForManualReview(L, i + 1, 'TShape property assignment',
          'VCL Shape property assignment has no direct FMX equivalent; the shape is handled in the generated .fmx file.',
          'Verify the generated .fmx file contains the correct FMX shape component and remove this assignment if redundant.');

      // Fix integer/single math
      FixNumericMath(L);

      L := L + TrailingComment;
      Lines[i] := L;
    end;

    RestoreNonUnsupportedManualReviewSignatures(Lines);
    EnsureFormCreateRunsBeforeFormShow;

    Code := Lines.Text;
    RewriteWindowsMessageHelperCalls(Code);
    Code := TRegEx.Replace(Code,
      '^(\s*)__FMX_CENTER_LABEL_CONTAINER__\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*([A-Za-z_][A-Za-z0-9_]*)\s*\);\s*$',
      '$1$2.Width := Round($3.Width + ($3.Position.X * 2));' + sLineBreak +
      '$1$2.Height := Round($3.Height + ($3.Position.Y * 2));' + sLineBreak +
      '$1$2.Position.X := (Screen.Width - $2.Width) / 2;',
      [roIgnoreCase, roMultiLine]);
    Code := TRegEx.Replace(Code,
      '(?is)(constructor\s+[A-Za-z_][A-Za-z0-9_\.]*\.Create\s*\(\s*AOwner\s*:\s*TComponent\s*\)\s*;\s*begin\b.*?^\s*inherited\s+Create\s*\(\s*AOwner\s*\)\s*;\s*(?://[^\r\n]*)?\s*\r?\n)(\s*)(?:Self\.)?OnCreate\s*:=\s*([A-Za-z_][A-Za-z0-9_]*)\s*;\s*(?://[^\r\n]*)?',
      '$1$2$3(Self);',
      [roIgnoreCase, roSingleLine, roMultiLine]);

  finally
    GenericListFields.Free;
    ControlTypes.Free;
    AnalysisLines.Free;
    Lines.Free;
  end;
end;


procedure TAutoFixRewriter.FixNumericMath(var Line: string);
var
  P: Integer;
  LHS, RHS: string;
  HasSemicolon: Boolean;
  IsFloatTarget: Boolean;
  HasFloatOperand: Boolean;
begin
  P := Pos(':=', Line);
  if P <= 0 then
    Exit;

  LHS := Trim(Copy(Line, 1, P - 1));
  RHS := Trim(Copy(Line, P + 2, Length(Line)));
  HasSemicolon := RHS.EndsWith(';');
  if HasSemicolon then
    RHS := Trim(Copy(RHS, 1, Length(RHS) - 1));

  IsFloatTarget := TRegEx.IsMatch(LHS, '(^|[\.\]])(Width|Height|Size|Value|Opacity|Left|Top)$', [roIgnoreCase]) or
                    EndsText('.Position.X', LHS) or
                    EndsText('.Position.Y', LHS);
  HasFloatOperand :=
    TRegEx.IsMatch(RHS,
      '(^|[^A-Za-z0-9_\.])(?:Screen\.(?:Width|Height|WorkAreaWidth|WorkAreaHeight)|' +
      '[A-Za-z_][A-Za-z0-9_\.]*\.(?:Width|Height|Size|Value|Opacity|Left|Top))(?![A-Za-z0-9_])',
      [roIgnoreCase]) or
    TRegEx.IsMatch(RHS,
      '[A-Za-z_][A-Za-z0-9_\.]*\.Position\.(?:X|Y)\b',
      [roIgnoreCase]);

  if IsFloatTarget and HasFloatOperand and
     TRegEx.IsMatch(RHS, '\bdiv\b', [roIgnoreCase]) then
  begin
    RHS := TRegEx.Replace(RHS, '\bdiv\b', '/', [roIgnoreCase]);
    Line := Copy(Line, 1, P + 1) + ' ' + RHS;
  end;

  if TRegEx.IsMatch(LHS, '(^|[\.\]])(Width|Height)$', [roIgnoreCase]) then
  begin
    // If RHS contains multiplication that might need rounding
    if (Pos('*', RHS) > 0) and (Pos('Round(', RHS) = 0) then
      RHS := 'Round(' + RHS + ')';

    Line := Copy(Line, 1, P + 1) + ' ' + RHS;
  end
  else if TRegEx.IsMatch(LHS, '(^|[\.\]])(Left|Top)$', [roIgnoreCase]) then
  begin
    if (Pos('/', RHS) > 0) and (Pos('Round(', RHS) = 0) then
      RHS := 'Round(' + RHS + ')';

    Line := Copy(Line, 1, P + 1) + ' ' + RHS;
  end
  else if (SameText(RHS, 'Screen.WorkAreaWidth') or
           SameText(RHS, 'Screen.WorkAreaHeight')) and
          TRegEx.IsMatch(LHS, '(^|[\.\]])(ScreenWidth|ScreenHeight)$') then
  begin
    Line := Copy(Line, 1, P + 1) + ' Round(' + RHS + ')';
  end;

  if HasSemicolon and not Line.TrimRight.EndsWith(';') then
    Line := Line + ';';
end;


end.
