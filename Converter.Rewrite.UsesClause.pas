{VCL2FMX (c) 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Rewrite.UsesClause;

interface

uses
  System.SysUtils,
  System.Classes,
  System.RegularExpressions,
  System.StrUtils,
  Converter.Core.Types;

type
  TUsesClauseRewriter = class
  private
    FContext: TConversionContext;
    function BuildWrappedUsesClause(AUnits: TStrings; const AIndent: string;
      const AMaxLineLength: Integer): string;
  public
    constructor Create(AContext: TConversionContext);
    procedure RemoveDuplicateImplementationUses(var Code: string);
    procedure Fix(var Code: string);
  end;

implementation

constructor TUsesClauseRewriter.Create(AContext: TConversionContext);
begin
  inherited Create;
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('Conversion context is not assigned');
  FContext := AContext;
end;

function TUsesClauseRewriter.BuildWrappedUsesClause(
  AUnits: TStrings; const AIndent: string; const AMaxLineLength: Integer): string;
var
  I: Integer;
  CurrentLine: string;
  Candidate: string;
  UnitName: string;
begin
  Result := '';
  if not Assigned(AUnits) or (AUnits.Count = 0) then
    Exit;

  CurrentLine := 'uses ';
  for I := 0 to AUnits.Count - 1 do
  begin
    UnitName := Trim(AUnits[I]);
    if UnitName = '' then
      Continue;

    if CurrentLine = 'uses ' then
      Candidate := CurrentLine + UnitName
    else
      Candidate := CurrentLine + ', ' + UnitName;

    if (Length(CurrentLine) > Length('uses ')) and
       (Length(Candidate) > AMaxLineLength) then
    begin
      if Result <> '' then
        Result := Result + sLineBreak;
      Result := Result + CurrentLine + ',';
      CurrentLine := AIndent + UnitName;
    end
    else
      CurrentLine := Candidate;
  end;

  if Result <> '' then
    Result := Result + sLineBreak;
  Result := Result + CurrentLine + ';';
end;

procedure TUsesClauseRewriter.RemoveDuplicateImplementationUses(var Code: string);
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  i, j: Integer;
  InImplementation: Boolean;
  InUses: Boolean;
  UsesStart, UsesEnd: Integer;
  UsesLine: string;
  Units: TArray<string>;
  UnitList: TStringList;
  TrailingCode: TStringList;
  ProtectedLines: TStringList;
  ConditionalUnits: TStringList;
  UnitName: string;
  OriginalLine: string;
  ConditionalLine: string;
  InConditional: Boolean;
  LowerUsesLine: string;
  OriginalCode: string;
  AnalysisCode: string;
  CleanedProtectedLine: string;

  procedure ExtractTrailingCode(var AUsesLine: string);
  const
    Tokens: array[0..5] of string = ('{$R ', 'function ', 'procedure ',
      'var ', 'const ', 'type ');
  var
    Token: string;
    P: Integer;
    FirstPos: Integer;
  begin
    LowerUsesLine := LowerCase(AUsesLine);
    FirstPos := MaxInt;

    for Token in Tokens do
    begin
      P := Pos(LowerCase(Token), LowerUsesLine);
      if (P > 0) and (P < FirstPos) then
        FirstPos := P;
    end;

    if FirstPos <> MaxInt then
    begin
      TrailingCode.Add(Trim(Copy(AUsesLine, FirstPos, MaxInt)));
      AUsesLine := Trim(Copy(AUsesLine, 1, FirstPos - 1));
    end;
  end;

  function IsLegacyVCLUnit(const AUnitName: string): Boolean;
  begin
    Result := SameText(AUnitName, 'StdCtrls') or
              SameText(AUnitName, 'Controls') or
              SameText(AUnitName, 'Forms') or
              SameText(AUnitName, 'Graphics') or
              SameText(AUnitName, 'Dialogs') or
              SameText(AUnitName, 'ExtCtrls') or
              SameText(AUnitName, 'ComCtrls') or
              SameText(AUnitName, 'Buttons') or
              SameText(AUnitName, 'Menus') or
              SameText(AUnitName, 'ActnList') or
              SameText(AUnitName, 'ImgList') or
              SameText(AUnitName, 'ToolWin') or
              SameText(AUnitName, 'Mask');
  end;

  function IsRemovedConditionalUsesUnit(const AUnitName: string): Boolean;
  begin
    Result := StartsText('Vcl.', AUnitName) or
              IsLegacyVCLUnit(AUnitName) or
              SameText(AUnitName, 'Themes') or
              SameText(AUnitName, 'DBGrids') or
              SameText(AUnitName, 'DBCtrls') or
              SameText(AUnitName, 'ComCtrls') or
              SameText(AUnitName, 'Menus') or
              SameText(AUnitName, 'SqlExpr') or
              SameText(AUnitName, 'Messages') or
              SameText(AUnitName, 'Winapi.Messages') or
              SameText(AUnitName, 'FireDAC.VCLUI.Wait');
  end;

  function CleanProtectedUsesLine(const ALine: string): string;
  var
    TrimmedLine: string;
    Indent: string;
    Body: string;
    Parts: TArray<string>;
    KeptUnits: TStringList;
    Part: string;
    CleanPart: string;
    EndsWithComma: Boolean;
    K: Integer;
  begin
    Result := ALine;
    TrimmedLine := Trim(ALine);
    if (TrimmedLine = '') or StartsText('{$', TrimmedLine) or StartsText('(*$', TrimmedLine) then
      Exit;

    Body := StringReplace(TrimmedLine, ';', '', [rfReplaceAll]);
    EndsWithComma := EndsText(',', Body);
    Parts := Body.Split([',']);
    KeptUnits := TStringList.Create;
    try
      for Part in Parts do
      begin
        CleanPart := Trim(Part);
        if CleanPart = '' then
          Continue;
        if not IsRemovedConditionalUsesUnit(CleanPart) then
          KeptUnits.Add(CleanPart);
      end;

      if KeptUnits.Count = 0 then
        Exit('');

      Indent := Copy(ALine, 1, Length(ALine) - Length(TrimLeft(ALine)));
      Result := Indent;
      for K := 0 to KeptUnits.Count - 1 do
      begin
        if K > 0 then
          Result := Result + ', ';
        Result := Result + KeptUnits[K];
      end;
      if EndsWithComma then
        Result := Result + ',';
    finally
      KeptUnits.Free;
    end;
  end;

  function StripStringLiteralsForAnalysis(const S: string): string;
  var
    K: Integer;
    InString: Boolean;
  begin
    Result := '';
    InString := False;
    K := 1;
    while K <= Length(S) do
    begin
      if S[K] = '''' then
      begin
        if not InString then
          InString := True
        else if (K < Length(S)) and (S[K + 1] = '''') then
        begin
          Result := Result + '  ';
          Inc(K, 2);
          Continue;
        end
        else
          InString := False;
        Result := Result + ' ';
      end
      else if InString then
        Result := Result + ' '
      else
        Result := Result + S[K];
      Inc(K);
    end;
  end;

  function HasLikelyMessageAPICall(const ACode: string): Boolean;
  var
    LocalLines: TStringList;
    LineText: string;
    TrimmedLine: string;
    LineIndex: Integer;
  begin
    Result := False;
    LocalLines := TStringList.Create;
    try
      LocalLines.Text := ACode;
      for LineIndex := 0 to LocalLines.Count - 1 do
      begin
        LineText := LocalLines[LineIndex];
        TrimmedLine := Trim(LineText);
        if TRegEx.IsMatch(TrimmedLine,
             '^(class\s+)?(procedure|function|constructor|destructor)\b',
             [roIgnoreCase]) then
          Continue;

        if TRegEx.IsMatch(LineText, '\b(SendMessage|PostMessage)\s*\(', [roIgnoreCase]) then
        begin
          if TRegEx.IsMatch(LineText, '\b(WM_|CM_|CN_|EM_|LB_|CB_|LVM_|TVM_|TCM_|SB_|Handle\b|HWND\b)', [roIgnoreCase]) then
            Exit(True);
          Continue;
        end;

        if TRegEx.IsMatch(LineText,
             '\b(DispatchMessage|PeekMessage|GetMessage|TranslateMessage)\s*\(\s*(Msg|Message|TMsg\b|PMsg\b|@)',
             [roIgnoreCase]) then
          Exit(True);

        if TRegEx.IsMatch(LineText, '\.\s*Perform\s*\(', [roIgnoreCase]) and
           TRegEx.IsMatch(LineText, '\b(WM_|CM_|CN_|EM_|LB_|CB_|LVM_|TVM_|TCM_|SB_)', [roIgnoreCase]) then
          Exit(True);
      end;
    finally
      LocalLines.Free;
    end;
  end;
begin
  Assert(Assigned(FContext));

  OriginalCode := Code;
  AnalysisCode := StripStringLiteralsForAnalysis(VCL2FMXStripCommentsForAnalysis(Code));
  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  UnitList := TStringList.Create;
  TrailingCode := TStringList.Create;
  ProtectedLines := TStringList.Create;
  ConditionalUnits := TStringList.Create;
  try
    UnitList.Sorted := True;
    UnitList.Duplicates := dupIgnore;

    Lines.Text := Code;
    AnalysisLines.Text := AnalysisCode;
    InImplementation := False;
    InUses := False;
    UsesStart := -1;
    UsesEnd := -1;

    // Find the implementation uses clause
    for i := 0 to AnalysisLines.Count - 1 do
    begin
      var Line := Trim(AnalysisLines[i]);

      if Pos('implementation', LowerCase(Line)) = 1 then
      begin
        InImplementation := True;
        Continue;
      end;

      if InImplementation and (Pos('uses', LowerCase(Line)) = 1) then
      begin
        InUses := True;
        UsesStart := i;
        UsesLine := Trim(Copy(Line, 5, MaxInt));
        if EndsText(';', Trim(Line)) then
        begin
          UsesEnd := i;
          Break;
        end;
        Continue;
      end;

      if InImplementation and InUses then
      begin
        if i > UsesStart then
          UsesLine := UsesLine + ' ' + Line;

        if Pos(';', Line) > 0 then
        begin
          UsesEnd := i;
          Break;
        end;
      end;
    end;

    if (UsesStart <> -1) and (UsesEnd <> -1) then
    begin
      InConditional := False;
      for j := UsesStart to UsesEnd do
      begin
        OriginalLine := Lines[j];
        if StartsText('{$IF', TrimLeft(OriginalLine)) then
          InConditional := True;
        if InConditional then
        begin
          CleanedProtectedLine := CleanProtectedUsesLine(OriginalLine);
          if CleanedProtectedLine = '' then
            Continue;
          ProtectedLines.Add(CleanedProtectedLine);
          ConditionalLine := Trim(CleanedProtectedLine);
          ConditionalLine := StringReplace(ConditionalLine, ',', '', [rfReplaceAll]);
          ConditionalLine := StringReplace(ConditionalLine, ';', '', [rfReplaceAll]);
          ConditionalLine := Trim(ConditionalLine);
          if ConditionalLine <> '' then
            ConditionalUnits.Add(ConditionalLine);
        end
        else if (Trim(AnalysisLines[j]) = '') and (Trim(OriginalLine) <> '') then
          ProtectedLines.Add(OriginalLine);
        if StartsText('{$ENDIF', TrimLeft(OriginalLine)) then
          InConditional := False;
      end;

      ExtractTrailingCode(UsesLine);

      // Clean up the uses line
      UsesLine := StringReplace(UsesLine, ';', '', []);
      UsesLine := StringReplace(UsesLine, #13, ' ', [rfReplaceAll]);
      UsesLine := StringReplace(UsesLine, #10, ' ', [rfReplaceAll]);

      // Split into individual units
      Units := UsesLine.Split([',']);

      // Add only FMX-safe units to the list
      for j := 0 to High(Units) do
      begin
        UnitName := Trim(Units[j]);
        if UnitName = '' then Continue;
        if SameText(UnitName, 'uses') then Continue;
        if ConditionalUnits.IndexOf(UnitName) <> -1 then Continue;
        if Pos('{$', UnitName) > 0 then
        begin
          if ConditionalUnits.IndexOf(Trim(Copy(UnitName, 1, Pos('{$', UnitName) - 1))) <> -1 then Continue;
          UnitName := Trim(Copy(UnitName, 1, Pos('{$', UnitName) - 1));
        end;
        if Pos(' var ', ' ' + LowerCase(UnitName) + ' ') > 0 then
          UnitName := Trim(Copy(UnitName, 1, Pos(' var ', ' ' + LowerCase(UnitName) + ' ') - 1));
        if UnitName = '' then Continue;
        if ConditionalUnits.IndexOf(UnitName) <> -1 then Continue;

        // Exclude VCL units entirely; drop Winapi.* implementation units here.
        // Fix scans the full converted code and re-adds required Winapi units to the interface uses.
        if StartsText('Vcl.', UnitName) then Continue;
        if StartsText('Winapi.', UnitName) then
        begin
          if SameText(UnitName, 'Winapi.MMSystem') then
            UnitList.Add('Winapi.MMSystem');
          Continue;
        end;
        if SameText(UnitName, 'Windows') then Continue;
        if SameText(UnitName, 'Messages') then Continue;
        if IsLegacyVCLUnit(UnitName) then Continue;
        if SameText(UnitName, 'MMSystem') then
        begin
          UnitList.Add('Winapi.MMSystem');
          Continue;
        end;
        if SameText(UnitName, 'ActiveX') then Continue;
        if ContainsText(UnitName, 'DBGrids') then Continue;
        if ContainsText(UnitName, 'DBCtrls') then Continue;
        if ContainsText(UnitName, 'ComCtrls') then Continue;
        if ContainsText(UnitName, 'Menus') then Continue;
        if ContainsText(UnitName, 'ShellAPI') then Continue;
        if ContainsText(UnitName, 'SqlExpr') then Continue;
        if SameText(UnitName, 'FireDAC.VCLUI.Wait') then
          UnitName := 'FireDAC.FMXUI.Wait';

        // Keep FMX, FireDAC, and System units
        if (UnitName <> '') then
          UnitList.Add(UnitName);
      end;

      // Rebuild the uses clause
      if UnitList.Count > 0 then
      begin
        UsesLine := BuildWrappedUsesClause(UnitList, '  ', 100);
        if ProtectedLines.Count > 0 then
        begin
          Delete(UsesLine, Length(UsesLine), 1);
          ConditionalLine := TrimRight(ProtectedLines.Text);
          if EndsText(';', ConditionalLine) then
            Delete(ConditionalLine, Length(ConditionalLine), 1);
          UsesLine := UsesLine + sLineBreak + ConditionalLine + sLineBreak + ';';
        end;
      end
      else
        UsesLine := '';

      // Replace the old uses clause with the new one
      for j := UsesStart to UsesEnd do
        Lines[j] := '';

      if UsesLine <> '' then
        Lines[UsesStart] := UsesLine;

      // Rebuild the code
      Code := '';
      for j := 0 to Lines.Count - 1 do
      begin
        if Lines[j] <> '' then
          Code := Code + Lines[j] + sLineBreak;
      end;

      if (UsesLine <> '') and (TrailingCode.Count > 0) then
        Code := StringReplace(Code, UsesLine + sLineBreak,
          UsesLine + sLineBreak + sLineBreak + TrailingCode.Text + sLineBreak, []);

      Code := StringReplace(Code, '  {$R *.fmx}', sLineBreak + '{$R *.fmx}', [rfReplaceAll]);
      Code := StringReplace(Code, '{$R *.fmx}  var ', '{$R *.fmx}' + sLineBreak + sLineBreak + 'var ', [rfReplaceAll]);
      Code := StringReplace(Code, '{$R *.fmx} var ', '{$R *.fmx}' + sLineBreak + sLineBreak + 'var ', [rfReplaceAll]);
    end;

  finally
    ConditionalUnits.Free;
    ProtectedLines.Free;
    TrailingCode.Free;
    UnitList.Free;
    AnalysisLines.Free;
    Lines.Free;
  end;

  if Code <> OriginalCode then
  begin
    FContext.AddIssue(csInfo,
      'Implementation uses clause normalized for FMX compatibility.');
    if ContainsText(OriginalCode, 'Vcl.') or ContainsText(OriginalCode, 'Winapi.') then
      FContext.AddIssue(csInfo,
        'Implementation uses clause had VCL/WinAPI units reviewed against FMX compatibility rules.');
  end;
end;

procedure TUsesClauseRewriter.Fix(var Code: string);
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  i, j: Integer;
  Line: string;
  UsesLine: string;
  Units: TArray<string>;
  UnitList: TStringList;
  ProtectedLines: TStringList;
  ConditionalUnits: TStringList;
  UnitName: string;
  OriginalLine: string;
  ConditionalLine: string;
  InConditional: Boolean;
  InUses: Boolean;
  StartIdx, EndIdx: Integer;
  NeedsFMXObjects: Boolean;
  NeedsFMXStdCtrls: Boolean;
  NeedsFMXEdit: Boolean;
  NeedsFMXComboEdit: Boolean;
  NeedsFMXMemo: Boolean;
  NeedsFMXSpinBox: Boolean;
  NeedsFMXNumberBox: Boolean;
  NeedsFMXColors: Boolean;
  NeedsFMXListBox: Boolean;
  NeedsFMXLayouts: Boolean;
  NeedsFMXMenus: Boolean;
  NeedsFMXGrid: Boolean;
  NeedsFMXImgList: Boolean;
  NeedsFMXDateTimeCtrls: Boolean;
  NeedsFMXDialogs: Boolean;
  NeedsFMXMedia: Boolean;
  NeedsDataBindComponents: Boolean;
  NeedsDataBindDBScope: Boolean;
  NeedsDataBindGrid: Boolean;
  NeedsFmxBindDBLinks: Boolean;
  NeedsFmxBindNavigator: Boolean;
  NeedsFmxBindEditors: Boolean;
  NeedsSystemUITypes: Boolean;
  NeedsSystemRtti: Boolean;
  NeedsSystemTypes: Boolean;
  NeedsSystemGenericsCollections: Boolean;
  NeedsSystemUIConsts: Boolean;
  NeedsWinapiWindows: Boolean;
  NeedsWinapiShellAPI: Boolean;
  NeedsWinapiMessages: Boolean;
  NeedsSystemMessaging: Boolean;
  NeedsWinapiActiveX: Boolean;
  NeedsWinapiMMSystem: Boolean;
  NeedsSystemWinComObj: Boolean;
  NeedsFMXCoreUnits: Boolean;
  InterfaceIdx: Integer;
  OriginalCode: string;
  AnalysisCode: string;
  CleanedProtectedLine: string;

  function IsLegacyVCLUnit(const AUnitName: string): Boolean;
  begin
    Result := SameText(AUnitName, 'StdCtrls') or
              SameText(AUnitName, 'Controls') or
              SameText(AUnitName, 'Forms') or
              SameText(AUnitName, 'Graphics') or
              SameText(AUnitName, 'Dialogs') or
              SameText(AUnitName, 'ExtCtrls') or
              SameText(AUnitName, 'ComCtrls') or
              SameText(AUnitName, 'Buttons') or
              SameText(AUnitName, 'Menus') or
              SameText(AUnitName, 'ActnList') or
              SameText(AUnitName, 'ImgList') or
              SameText(AUnitName, 'ToolWin') or
              SameText(AUnitName, 'Mask');
  end;

  function IsRemovedConditionalUsesUnit(const AUnitName: string): Boolean;
  begin
    Result := StartsText('Vcl.', AUnitName) or
              IsLegacyVCLUnit(AUnitName) or
              SameText(AUnitName, 'Themes') or
              SameText(AUnitName, 'DBGrids') or
              SameText(AUnitName, 'DBCtrls') or
              SameText(AUnitName, 'ComCtrls') or
              SameText(AUnitName, 'Menus') or
              SameText(AUnitName, 'SqlExpr') or
              ((SameText(AUnitName, 'Messages') or SameText(AUnitName, 'Winapi.Messages')) and
                not NeedsWinapiMessages) or
              SameText(AUnitName, 'FireDAC.VCLUI.Wait');
  end;

  function CleanProtectedUsesLine(const ALine: string): string;
  var
    TrimmedLine: string;
    Indent: string;
    Body: string;
    Parts: TArray<string>;
    KeptUnits: TStringList;
    Part: string;
    CleanPart: string;
    EndsWithComma: Boolean;
    K: Integer;
  begin
    Result := ALine;
    TrimmedLine := Trim(ALine);
    if (TrimmedLine = '') or StartsText('{$', TrimmedLine) or StartsText('(*$', TrimmedLine) then
      Exit;

    Body := StringReplace(TrimmedLine, ';', '', [rfReplaceAll]);
    EndsWithComma := EndsText(',', Body);
    Parts := Body.Split([',']);
    KeptUnits := TStringList.Create;
    try
      for Part in Parts do
      begin
        CleanPart := Trim(Part);
        if CleanPart = '' then
          Continue;
        if not IsRemovedConditionalUsesUnit(CleanPart) then
          KeptUnits.Add(CleanPart);
      end;

      if KeptUnits.Count = 0 then
        Exit('');

      Indent := Copy(ALine, 1, Length(ALine) - Length(TrimLeft(ALine)));
      Result := Indent;
      for K := 0 to KeptUnits.Count - 1 do
      begin
        if K > 0 then
          Result := Result + ', ';
        Result := Result + KeptUnits[K];
      end;
      if EndsWithComma then
        Result := Result + ',';
    finally
      KeptUnits.Free;
    end;
  end;

  function StripStringLiteralsForAnalysis(const S: string): string;
  var
    K: Integer;
    InString: Boolean;
  begin
    Result := '';
    InString := False;
    K := 1;
    while K <= Length(S) do
    begin
      if S[K] = '''' then
      begin
        if not InString then
          InString := True
        else if (K < Length(S)) and (S[K + 1] = '''') then
        begin
          Result := Result + '  ';
          Inc(K, 2);
          Continue;
        end
        else
          InString := False;
        Result := Result + ' ';
      end
      else if InString then
        Result := Result + ' '
      else
        Result := Result + S[K];
      Inc(K);
    end;
  end;
  function HasLikelyMessageAPICall(const ACode: string): Boolean;
  var
    LocalLines: TStringList;
    LineText: string;
    TrimmedLine: string;
    LineIndex: Integer;
  begin
    Result := False;
    LocalLines := TStringList.Create;
    try
      LocalLines.Text := ACode;
      for LineIndex := 0 to LocalLines.Count - 1 do
      begin
        LineText := LocalLines[LineIndex];
        TrimmedLine := Trim(LineText);
        if TRegEx.IsMatch(TrimmedLine,
             '^(class\s+)?(procedure|function|constructor|destructor)\b',
             [roIgnoreCase]) then
          Continue;

        if TRegEx.IsMatch(LineText, '\b(SendMessage|PostMessage)\s*\(', [roIgnoreCase]) then
        begin
          if TRegEx.IsMatch(LineText, '\b(WM_|CM_|CN_|EM_|LB_|CB_|LVM_|TVM_|TCM_|SB_|Handle\b|HWND\b)', [roIgnoreCase]) then
            Exit(True);
          Continue;
        end;

        if TRegEx.IsMatch(LineText,
             '\b(DispatchMessage|PeekMessage|GetMessage|TranslateMessage)\s*\(\s*(Msg|Message|TMsg\b|PMsg\b|@)',
             [roIgnoreCase]) then
          Exit(True);

        if TRegEx.IsMatch(LineText, '\.\s*Perform\s*\(', [roIgnoreCase]) and
           TRegEx.IsMatch(LineText, '\b(WM_|CM_|CN_|EM_|LB_|CB_|LVM_|TVM_|TCM_|SB_)', [roIgnoreCase]) then
          Exit(True);
      end;
    finally
      LocalLines.Free;
    end;
  end;
begin
  Assert(Assigned(FContext));

  OriginalCode := Code;
  AnalysisCode := StripStringLiteralsForAnalysis(VCL2FMXStripCommentsForAnalysis(Code));
  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  UnitList := TStringList.Create;
  ProtectedLines := TStringList.Create;
  ConditionalUnits := TStringList.Create;
  try
    UnitList.Sorted := True;
    UnitList.Duplicates := dupIgnore;
    NeedsFMXObjects := False;
    NeedsFMXStdCtrls := False;
    NeedsFMXEdit := False;
    NeedsFMXComboEdit := False;
    NeedsFMXMemo := False;
    NeedsFMXSpinBox := False;
    NeedsFMXNumberBox := False;
    NeedsFMXColors := False;
    NeedsFMXListBox := False;
    NeedsFMXLayouts := False;
    NeedsFMXMenus := False;
    NeedsFMXGrid := False;
    NeedsFMXImgList := False;
    NeedsFMXDateTimeCtrls := False;
    NeedsFMXDialogs := False;
    NeedsFMXMedia := False;
    NeedsDataBindComponents := False;
    NeedsDataBindDBScope := False;
    NeedsFmxBindDBLinks := False;
    NeedsFmxBindNavigator := False;
    NeedsFmxBindEditors := False;
    NeedsSystemUITypes := False;
    NeedsSystemRtti := False;
    NeedsSystemGenericsCollections := False;
    NeedsSystemUIConsts := False;
    NeedsWinapiMessages := False;
    NeedsSystemMessaging := False;
    NeedsWinapiActiveX := False;
    NeedsWinapiMMSystem := False;
    NeedsSystemWinComObj := False;
    InterfaceIdx := -1;

    Lines.Text := Code;
    AnalysisLines.Text := AnalysisCode;
    InUses := False;
    StartIdx := -1;
    EndIdx := -1;

    // First, check if we need FMX.Objects
    if (Pos('TImage', AnalysisCode) > 0) or (Pos('TShape', AnalysisCode) > 0) or
       (Pos('TRectangle', AnalysisCode) > 0) or (Pos('TRoundRect', AnalysisCode) > 0) or
       (Pos('TEllipse', AnalysisCode) > 0) or (Pos('TCircle', AnalysisCode) > 0) or
       (Pos('TLine', AnalysisCode) > 0) or (Pos('TPaintBox', AnalysisCode) > 0) then
    begin
      NeedsFMXObjects := True;
    end;

    NeedsFMXStdCtrls := (Pos('TLabel', AnalysisCode) > 0) or
                         (Pos('TButton', AnalysisCode) > 0) or
                         (Pos('TPanel', AnalysisCode) > 0) or
                         (Pos('TCheckBox', AnalysisCode) > 0) or
                         (Pos('TRadioButton', AnalysisCode) > 0) or
                         (Pos('TGroupBox', AnalysisCode) > 0) or
                         (Pos('TSpeedButton', AnalysisCode) > 0) or
                         (Pos('TTrackBar', AnalysisCode) > 0) or
                         (Pos('TProgressBar', AnalysisCode) > 0) or
                         (Pos('TToolBar', AnalysisCode) > 0) or
                         (Pos('TFontDialog', AnalysisCode) > 0) or
                         (Pos('TColorDialog', AnalysisCode) > 0);
    NeedsFMXEdit := (Pos('TEdit', AnalysisCode) > 0) or
                    (Pos('TCustomEdit', AnalysisCode) > 0);
    NeedsFMXComboEdit := Pos('TComboEdit', AnalysisCode) > 0;
    NeedsFMXMemo := Pos('TMemo', AnalysisCode) > 0;
    NeedsFMXSpinBox := (Pos('TSpinBox', AnalysisCode) > 0) or (Pos('TFontDialog', AnalysisCode) > 0);
    NeedsFMXNumberBox := Pos('TNumberBox', AnalysisCode) > 0;
    NeedsFMXColors := (Pos('TColorComboBox', AnalysisCode) > 0) or
                      (Pos('TColorBox', AnalysisCode) > 0) or
                      (Pos('TColorDialog', AnalysisCode) > 0);
    NeedsFMXListBox := (Pos('TComboBox', AnalysisCode) > 0) or
                       (Pos('TListBox', AnalysisCode) > 0) or
                       (Pos('TFontDialog', AnalysisCode) > 0);
    NeedsFMXLayouts := Pos('TLayout', AnalysisCode) > 0;
    NeedsFMXMenus := (Pos('TMenuBar', AnalysisCode) > 0) or
                     (Pos('TMenuItem', AnalysisCode) > 0) or
                     (Pos('TPopupMenu', AnalysisCode) > 0);
    NeedsFMXGrid := (Pos('TGrid', AnalysisCode) > 0) or
                    (Pos('TStringGrid', AnalysisCode) > 0) or
                    (Pos('TColumn', AnalysisCode) > 0);
    NeedsFMXImgList := Pos('TImageList', AnalysisCode) > 0;
    NeedsFMXDateTimeCtrls := Pos('TDateEdit', AnalysisCode) > 0;
    NeedsFMXDialogs := (Pos('ShowMessage(', AnalysisCode) > 0) or
                        (Pos('MessageDlg(', AnalysisCode) > 0) or
                        (Pos('TOpenDialog', AnalysisCode) > 0) or
                        (Pos('TSaveDialog', AnalysisCode) > 0);
    NeedsFMXMedia := (Pos('TMediaPlayer', AnalysisCode) > 0) or
                     (Pos('mpPlaying', AnalysisCode) > 0);
    NeedsDataBindComponents := (Pos('TLinkControlToField', AnalysisCode) > 0) or
                               (Pos('TLinkPropertyToField', AnalysisCode) > 0) or
                               (Pos('TLinkFillControlToField', AnalysisCode) > 0);
    NeedsDataBindDBScope := Pos('TBindSourceDB', AnalysisCode) > 0;
    NeedsDataBindGrid := (Pos('TLinkGridToDataSource', AnalysisCode) > 0) or
                         (Pos('TLinkGridToDataSourceColumn', AnalysisCode) > 0);
    NeedsFmxBindDBLinks := Pos('TBindDBGridLink', AnalysisCode) > 0;
    NeedsFmxBindNavigator := (Pos('TBindNavigator', AnalysisCode) > 0) or
                             (Pos('TBindNavigateBtn', AnalysisCode) > 0) or
                             (Pos('TBindNavButtonSet', AnalysisCode) > 0);
    NeedsFmxBindEditors := NeedsDataBindComponents or NeedsDataBindDBScope or
      NeedsDataBindGrid or NeedsFmxBindDBLinks;
    NeedsSystemUITypes := (Pos('TAlphaColor', AnalysisCode) > 0) or
                          TRegEx.IsMatch(AnalysisCode, '\bcla[A-Z][A-Za-z0-9_]*\b') or
                          (Pos('MessageDlg(', AnalysisCode) > 0) or
                          (Pos('TOpenOption.', AnalysisCode) > 0) or
                          (Pos('TOpenOptionEx.', AnalysisCode) > 0) or
                          (Pos('mrOk', AnalysisCode) > 0) or
                          (Pos('mrCancel', AnalysisCode) > 0) or
                          (Pos('TColorDialog', AnalysisCode) > 0);
    NeedsSystemRtti := (Pos('TValue.From<', AnalysisCode) > 0) or
                       (Pos(': TValue', AnalysisCode) > 0) or
                       (Pos(' TValue;', AnalysisCode) > 0);
    NeedsSystemGenericsCollections := (Pos('TObjectList<', AnalysisCode) > 0) or
                                      (Pos('TObjectDictionary<', AnalysisCode) > 0);
    NeedsSystemTypes := (Pos('RectF(', AnalysisCode) > 0) or
                         (Pos('PointF(', AnalysisCode) > 0) or
                         (Pos('TRectF', AnalysisCode) > 0) or
                         (Pos('TPointF', AnalysisCode) > 0) or
                         (Pos('GeneratedClientRect(', AnalysisCode) > 0) or
                         (Pos('GeneratedDrawText(', AnalysisCode) > 0);
    NeedsSystemUIConsts := TRegEx.IsMatch(AnalysisCode, '\bcla[A-Z][A-Za-z0-9_]*\b') or
                           (Pos('TColorDialog', AnalysisCode) > 0);
    NeedsWinapiWindows := (Pos('CreateFile', AnalysisCode) > 0) or
                          (Pos('CloseHandle', AnalysisCode) > 0) or
                          (Pos('INVALID_HANDLE_VALUE', AnalysisCode) > 0) or
                          (Pos('GENERIC_READ', AnalysisCode) > 0) or
                          (Pos('GENERIC_WRITE', AnalysisCode) > 0) or
                          (Pos('OPEN_ALWAYS', AnalysisCode) > 0) or
                          (Pos('FILE_ATTRIBUTE_NORMAL', AnalysisCode) > 0) or
                          TRegEx.IsMatch(AnalysisCode, '\bSleep\s*\(') or
                          (Pos('SetThreadExecutionState', AnalysisCode) > 0) or
                          (Pos('ES_CONTINUOUS', AnalysisCode) > 0) or
                          (Pos('ES_SYSTEM_REQUIRED', AnalysisCode) > 0) or
                          (Pos('DT_', AnalysisCode) > 0) or
                          (Pos('RGB(', AnalysisCode) > 0) or
                          (Pos('GetRValue(', AnalysisCode) > 0) or
                          (Pos('GetGValue(', AnalysisCode) > 0) or
                          (Pos('GetBValue(', AnalysisCode) > 0) or
                          (Pos('ColorToRGB(', AnalysisCode) > 0);
    NeedsWinapiShellAPI := (Pos('ShellExecute(', AnalysisCode) > 0) or
                            (Pos('Winapi.ShellAPI.ShellExecute(', AnalysisCode) > 0);
    NeedsWinapiMessages :=
      TRegEx.IsMatch(AnalysisCode,
        '\b(WM_|CM_|CN_|EM_|LB_|CB_|LVM_|TVM_|TCM_|TWM[A-Za-z0-9_]*|TCM[A-Za-z0-9_]*)') or
      HasLikelyMessageAPICall(AnalysisCode);
    NeedsSystemMessaging := (Pos('TMessageManager', AnalysisCode) > 0) or
                            (Pos('SubscribeToMessage', AnalysisCode) > 0) or
                            (Pos('System.Messaging', AnalysisCode) > 0);
    NeedsWinapiActiveX := (Pos('CoInitialize', AnalysisCode) > 0) or
                          (Pos('OleInitialize', AnalysisCode) > 0) or
                          (Pos('OleUninitialize', AnalysisCode) > 0) or
                          (Pos('CoCreateInstance', AnalysisCode) > 0) or
                          (Pos('CLSCTX_', AnalysisCode) > 0) or
                          (Pos('TOleEnum', AnalysisCode) > 0) or
                          (Pos('SYSUINT', AnalysisCode) > 0);
    NeedsWinapiMMSystem := (Pos('waveOut', AnalysisCode) > 0) or
                           (Pos('HWAVEOUT', AnalysisCode) > 0) or
                           (Pos('TWaveHdr', AnalysisCode) > 0) or
                           (Pos('TWaveFormatEx', AnalysisCode) > 0) or
                           (Pos('WAVE_FORMAT_', AnalysisCode) > 0) or
                           (Pos('WAVE_MAPPER', AnalysisCode) > 0) or
                           (Pos('WHDR_', AnalysisCode) > 0) or
                           (Pos('MMSYSERR_', AnalysisCode) > 0);
    NeedsSystemWinComObj := (Pos('CreateOleObject', AnalysisCode) > 0) or
                            (Pos('GetActiveOleObject', AnalysisCode) > 0);
    NeedsFMXCoreUnits :=
      NeedsFMXObjects or NeedsFMXStdCtrls or NeedsFMXEdit or
      NeedsFMXComboEdit or NeedsFMXMemo or NeedsFMXSpinBox or
      NeedsFMXNumberBox or NeedsFMXColors or NeedsFMXListBox or
      NeedsFMXLayouts or NeedsFMXMenus or NeedsFMXGrid or
      NeedsFMXImgList or NeedsFMXDateTimeCtrls or NeedsFMXDialogs or
      NeedsFMXMedia or
      TRegEx.IsMatch(AnalysisCode,
        '\b(TForm|TFrame|TDataModule|TControl|TFmxObject|TCanvas|TBitmap)\b',
        [roIgnoreCase]) or
      ContainsText(AnalysisCode, 'FMX.');

    // Find the interface uses clause (skip implementation uses)
    for i := 0 to AnalysisLines.Count - 1 do
    begin
      Line := Trim(AnalysisLines[i]);

      if Line.StartsWith('interface') then
      begin
        InterfaceIdx := i;
        // Reset flags when we hit interface
        InUses := False;
        Continue;
      end;

      if Line.StartsWith('implementation') then
      begin
        // Stop searching - we're past interface
        Break;
      end;

      if Line.StartsWith('uses', True) and not InUses then
      begin
        InUses := True;
        StartIdx := i;
        UsesLine := Trim(Copy(Line, 5, MaxInt));
        if Line.EndsWith(';') then
        begin
          EndIdx := i;
          Break;
        end;
        Continue;
      end;

      if InUses then
      begin
        UsesLine := UsesLine + ' ' + Line;
        if Line.EndsWith(';') then
        begin
          EndIdx := i;
          Break;
        end;
      end;
    end;

    if (StartIdx <> -1) and (EndIdx <> -1) then
    begin
      InConditional := False;
      for j := StartIdx to EndIdx do
      begin
        OriginalLine := Lines[j];
        if StartsText('{$IF', TrimLeft(OriginalLine)) then
          InConditional := True;
        if InConditional then
        begin
          CleanedProtectedLine := CleanProtectedUsesLine(OriginalLine);
          if CleanedProtectedLine = '' then
            Continue;
          ProtectedLines.Add(CleanedProtectedLine);
          ConditionalLine := Trim(CleanedProtectedLine);
          ConditionalLine := StringReplace(ConditionalLine, ',', '', [rfReplaceAll]);
          ConditionalLine := StringReplace(ConditionalLine, ';', '', [rfReplaceAll]);
          ConditionalLine := Trim(ConditionalLine);
          if ConditionalLine <> '' then
            ConditionalUnits.Add(ConditionalLine);
        end
        else if (Trim(AnalysisLines[j]) = '') and (Trim(OriginalLine) <> '') then
          ProtectedLines.Add(OriginalLine);
        if StartsText('{$ENDIF', TrimLeft(OriginalLine)) then
          InConditional := False;
      end;

      // Clean up the uses line
      UsesLine := StringReplace(UsesLine, ';', '', []);
      UsesLine := StringReplace(UsesLine, #13, ' ', [rfReplaceAll]);
      UsesLine := StringReplace(UsesLine, #10, ' ', [rfReplaceAll]);

      // Split into individual units
      Units := UsesLine.Split([',']);

      // Add only FMX-safe units to the list
      for j := 0 to High(Units) do
      begin
        UnitName := Trim(Units[j]);
        if UnitName = '' then Continue;
        if SameText(UnitName, 'uses') then Continue;
        if ConditionalUnits.IndexOf(UnitName) <> -1 then Continue;
        if Pos('{$', UnitName) > 0 then
        begin
          if ConditionalUnits.IndexOf(Trim(Copy(UnitName, 1, Pos('{$', UnitName) - 1))) <> -1 then Continue;
          UnitName := Trim(Copy(UnitName, 1, Pos('{$', UnitName) - 1));
        end;
        if Pos(' var ', ' ' + LowerCase(UnitName) + ' ') > 0 then
          UnitName := Trim(Copy(UnitName, 1, Pos(' var ', ' ' + LowerCase(UnitName) + ' ') - 1));
        if UnitName = '' then Continue;
        if ConditionalUnits.IndexOf(UnitName) <> -1 then Continue;

        if SameText(UnitName, 'SysUtils') then
          UnitName := 'System.SysUtils'
        else if SameText(UnitName, 'Classes') then
          UnitName := 'System.Classes'
        else if SameText(UnitName, 'Variants') then
          UnitName := 'System.Variants'
        else if SameText(UnitName, 'ComObj') then
          UnitName := 'System.Win.ComObj'
        else if SameText(UnitName, 'ActiveX') then
          UnitName := 'Winapi.ActiveX';

        // Exclude VCL units entirely; translate Winapi.* units to need-flags.
        if StartsText('Vcl.', UnitName) then Continue;
        if StartsText('Winapi.', UnitName) then
        begin
          if SameText(UnitName, 'Winapi.Windows') then
            NeedsWinapiWindows := True
          else if SameText(UnitName, 'Winapi.ShellAPI') then
            NeedsWinapiShellAPI := True
          else if SameText(UnitName, 'Winapi.Messages') then
            Continue
          else if SameText(UnitName, 'Winapi.ActiveX') then
            NeedsWinapiActiveX := True
          else if SameText(UnitName, 'Winapi.MMSystem') then
            NeedsWinapiMMSystem := True;
          Continue;
        end;
        if SameText(UnitName, 'Windows') then
        begin
          NeedsWinapiWindows := True;
          Continue;
        end;
        if SameText(UnitName, 'Messages') then
          Continue;
        if SameText(UnitName, 'ShellAPI') then
        begin
          NeedsWinapiShellAPI := True;
          Continue;
        end;
        if SameText(UnitName, 'MMSystem') then
        begin
          NeedsWinapiMMSystem := True;
          Continue;
        end;
        if SameText(UnitName, 'System.Win.ComObj') then
          NeedsSystemWinComObj := True;
        if SameText(UnitName, 'FireDAC.VCLUI.Wait') then
          UnitName := 'FireDAC.FMXUI.Wait';
        if IsLegacyVCLUnit(UnitName) then Continue;
        if ContainsText(UnitName, 'DBGrids') then Continue;
        if ContainsText(UnitName, 'DBCtrls') then Continue;
        if ContainsText(UnitName, 'ComCtrls') and not SameText(UnitName, 'FMX.StdCtrls') then Continue;
        if ContainsText(UnitName, 'Menus') then Continue;
        if ContainsText(UnitName, 'SqlExpr') then Continue;

        // Keep FMX, FireDAC, and System units
        if (UnitName <> '') then
          UnitList.Add(UnitName);
      end;

      // Ensure required FMX core units are present only for visual/FMX units.
      // Plain utility units should not receive form/control infrastructure.
      if NeedsFMXCoreUnits and (UnitList.IndexOf('FMX.Forms') = -1) then
        UnitList.Add('FMX.Forms');
      if NeedsFMXCoreUnits and (UnitList.IndexOf('FMX.Controls') = -1) then
        UnitList.Add('FMX.Controls');
      if NeedsFMXCoreUnits and (UnitList.IndexOf('FMX.Graphics') = -1) then
        UnitList.Add('FMX.Graphics');
      if NeedsFMXCoreUnits and (UnitList.IndexOf('FMX.Types') = -1) then
        UnitList.Add('FMX.Types');
      if NeedsSystemRtti and (UnitList.IndexOf('System.Rtti') = -1) then
        UnitList.Add('System.Rtti');
      if NeedsSystemGenericsCollections and (UnitList.IndexOf('System.Generics.Collections') = -1) then
        UnitList.Add('System.Generics.Collections');
      if NeedsSystemTypes and (UnitList.IndexOf('System.Types') = -1) then
        UnitList.Add('System.Types');

      // Add FMX.Objects if needed
      if NeedsFMXObjects and (UnitList.IndexOf('FMX.Objects') = -1) then
        UnitList.Add('FMX.Objects');
      if NeedsFMXStdCtrls and (UnitList.IndexOf('FMX.StdCtrls') = -1) then
        UnitList.Add('FMX.StdCtrls');
      if NeedsFMXEdit and (UnitList.IndexOf('FMX.Edit') = -1) then
        UnitList.Add('FMX.Edit');
      if NeedsFMXComboEdit and (UnitList.IndexOf('FMX.ComboEdit') = -1) then
        UnitList.Add('FMX.ComboEdit');
      if NeedsFMXMemo and (UnitList.IndexOf('FMX.Memo') = -1) then
        UnitList.Add('FMX.Memo');
      if NeedsFMXSpinBox and (UnitList.IndexOf('FMX.SpinBox') = -1) then
        UnitList.Add('FMX.SpinBox');
      if NeedsFMXNumberBox and (UnitList.IndexOf('FMX.NumberBox') = -1) then
        UnitList.Add('FMX.NumberBox');
      if NeedsFMXColors and (UnitList.IndexOf('FMX.Colors') = -1) then
        UnitList.Add('FMX.Colors');
      if NeedsFMXListBox and (UnitList.IndexOf('FMX.ListBox') = -1) then
        UnitList.Add('FMX.ListBox');
      if NeedsFMXLayouts and (UnitList.IndexOf('FMX.Layouts') = -1) then
        UnitList.Add('FMX.Layouts');
      if NeedsFMXMenus and (UnitList.IndexOf('FMX.Menus') = -1) then
        UnitList.Add('FMX.Menus');
      if NeedsFMXGrid and (UnitList.IndexOf('FMX.Grid') = -1) then
        UnitList.Add('FMX.Grid');
      if NeedsFMXGrid and (UnitList.IndexOf('FMX.Grid.Style') = -1) then
        UnitList.Add('FMX.Grid.Style');
      if NeedsFMXImgList and (UnitList.IndexOf('FMX.ImgList') = -1) then
        UnitList.Add('FMX.ImgList');
      if NeedsFMXDateTimeCtrls and (UnitList.IndexOf('FMX.DateTimeCtrls') = -1) then
        UnitList.Add('FMX.DateTimeCtrls');
      if NeedsFMXDialogs and (UnitList.IndexOf('FMX.Dialogs') = -1) then
        UnitList.Add('FMX.Dialogs');
      if NeedsFMXMedia and (UnitList.IndexOf('FMX.Media') = -1) then
        UnitList.Add('FMX.Media');
      if NeedsDataBindComponents and (UnitList.IndexOf('Data.Bind.Components') = -1) then
        UnitList.Add('Data.Bind.Components');
      if NeedsDataBindDBScope and (UnitList.IndexOf('Data.Bind.DBScope') = -1) then
        UnitList.Add('Data.Bind.DBScope');
      if NeedsDataBindGrid and (UnitList.IndexOf('Data.Bind.Grid') = -1) then
        UnitList.Add('Data.Bind.Grid');
      if NeedsDataBindGrid and (UnitList.IndexOf('Fmx.Bind.Grid') = -1) then
        UnitList.Add('Fmx.Bind.Grid');
      if NeedsFmxBindDBLinks and (UnitList.IndexOf('Fmx.Bind.DBLinks') = -1) then
        UnitList.Add('Fmx.Bind.DBLinks');
      if NeedsFmxBindNavigator and (UnitList.IndexOf('Data.Bind.Controls') = -1) then
        UnitList.Add('Data.Bind.Controls');
      if NeedsFmxBindNavigator and (UnitList.IndexOf('Fmx.Bind.Navigator') = -1) then
        UnitList.Add('Fmx.Bind.Navigator');
      if NeedsFmxBindEditors and (UnitList.IndexOf('Fmx.Bind.Editors') = -1) then
        UnitList.Add('Fmx.Bind.Editors');
      if NeedsSystemUITypes and (UnitList.IndexOf('System.UITypes') = -1) then
        UnitList.Add('System.UITypes');
      if NeedsSystemTypes and (UnitList.IndexOf('System.Types') = -1) then
        UnitList.Add('System.Types');
      if NeedsSystemUIConsts and (UnitList.IndexOf('System.UIConsts') = -1) then
        UnitList.Add('System.UIConsts');
      if NeedsWinapiWindows and (UnitList.IndexOf('Winapi.Windows') = -1) then
        UnitList.Add('Winapi.Windows');
      if NeedsWinapiShellAPI and (UnitList.IndexOf('Winapi.ShellAPI') = -1) then
        UnitList.Add('Winapi.ShellAPI');
      if NeedsWinapiMessages and (UnitList.IndexOf('Winapi.Messages') = -1) then
        UnitList.Add('Winapi.Messages');
      if NeedsSystemMessaging and (UnitList.IndexOf('System.Messaging') = -1) then
        UnitList.Add('System.Messaging');
      if NeedsWinapiActiveX and (UnitList.IndexOf('Winapi.ActiveX') = -1) then
        UnitList.Add('Winapi.ActiveX');
      if NeedsWinapiMMSystem and (UnitList.IndexOf('Winapi.MMSystem') = -1) then
        UnitList.Add('Winapi.MMSystem');
      if NeedsSystemWinComObj and (UnitList.IndexOf('System.Win.ComObj') = -1) then
        UnitList.Add('System.Win.ComObj');

      // Rebuild the uses clause
      UsesLine := BuildWrappedUsesClause(UnitList, '  ', 100);
      if ProtectedLines.Count > 0 then
      begin
        Delete(UsesLine, Length(UsesLine), 1);
        ConditionalLine := TrimRight(ProtectedLines.Text);
        if EndsText(';', ConditionalLine) then
          Delete(ConditionalLine, Length(ConditionalLine), 1);
        UsesLine := UsesLine + sLineBreak + ConditionalLine + sLineBreak + ';';
      end;

      // Replace the old uses clause with the new one
      for i := StartIdx to EndIdx do
        Lines[i] := '';

      Lines[StartIdx] := UsesLine;

      // Rebuild the code
      Code := '';
      for i := 0 to Lines.Count - 1 do
      begin
        if Lines[i] <> '' then
          Code := Code + Lines[i] + sLineBreak;
      end;
    end
    else if InterfaceIdx <> -1 then
    begin
      if NeedsFMXMedia then
        UnitList.Add('FMX.Media');
      if NeedsDataBindComponents then
        UnitList.Add('Data.Bind.Components');
      if NeedsDataBindDBScope then
        UnitList.Add('Data.Bind.DBScope');
      if NeedsDataBindGrid then
        UnitList.Add('Data.Bind.Grid');
      if NeedsDataBindGrid then
        UnitList.Add('Fmx.Bind.Grid');
      if NeedsFmxBindDBLinks then
        UnitList.Add('Fmx.Bind.DBLinks');
      if NeedsFmxBindNavigator then
        UnitList.Add('Data.Bind.Controls');
      if NeedsFmxBindNavigator then
        UnitList.Add('Fmx.Bind.Navigator');
      if NeedsFmxBindEditors then
        UnitList.Add('Fmx.Bind.Editors');
      if NeedsFMXGrid then
        UnitList.Add('FMX.Grid');
      if NeedsFMXGrid then
        UnitList.Add('FMX.Grid.Style');
      if NeedsSystemUITypes then
        UnitList.Add('System.UITypes');
      if NeedsSystemGenericsCollections then
        UnitList.Add('System.Generics.Collections');
      if NeedsSystemTypes then
        UnitList.Add('System.Types');
      if NeedsSystemUIConsts then
        UnitList.Add('System.UIConsts');
      if NeedsWinapiWindows then
        UnitList.Add('Winapi.Windows');
      if NeedsWinapiShellAPI then
        UnitList.Add('Winapi.ShellAPI');
      if NeedsWinapiMessages then
        UnitList.Add('Winapi.Messages');
      if NeedsSystemMessaging then
        UnitList.Add('System.Messaging');
      if NeedsWinapiActiveX then
        UnitList.Add('Winapi.ActiveX');
      if NeedsWinapiMMSystem then
        UnitList.Add('Winapi.MMSystem');
      if NeedsSystemWinComObj then
        UnitList.Add('System.Win.ComObj');

      if UnitList.Count > 0 then
      begin
        UsesLine := BuildWrappedUsesClause(UnitList, '  ', 100);
        Lines.Insert(InterfaceIdx + 1, UsesLine);
        Code := Lines.Text;
      end;
    end;

  finally
    ConditionalUnits.Free;
    ProtectedLines.Free;
    UnitList.Free;
    AnalysisLines.Free;
    Lines.Free;
  end;

  if Code <> OriginalCode then
  begin
    FContext.AddIssue(csInfo,
      'Interface uses clause normalized for FMX compatibility.');
    if ContainsText(Code, 'FMX.Forms') and not ContainsText(OriginalCode, 'FMX.Forms') then
      FContext.AddIssue(csInfo, 'Added FMX.Forms to the interface uses clause.');
    if ContainsText(Code, 'FMX.Controls') and not ContainsText(OriginalCode, 'FMX.Controls') then
      FContext.AddIssue(csInfo, 'Added FMX.Controls to the interface uses clause.');
    if ContainsText(Code, 'FMX.StdCtrls') and not ContainsText(OriginalCode, 'FMX.StdCtrls') then
      FContext.AddIssue(csInfo, 'Added FMX.StdCtrls to the interface uses clause.');
    if ContainsText(Code, 'FMX.Graphics') and not ContainsText(OriginalCode, 'FMX.Graphics') then
      FContext.AddIssue(csInfo, 'Added FMX.Graphics to the interface uses clause.');
    if ContainsText(Code, 'Winapi.Messages') and not ContainsText(OriginalCode, 'Winapi.Messages') then
      FContext.AddIssue(csWarning,
        'Winapi.Messages was added because the converted code still references Windows message APIs (WM_/CM_ constants, SendMessage, Perform, etc.). Review for cross-platform FMX use.');
  end;
end;

end.
