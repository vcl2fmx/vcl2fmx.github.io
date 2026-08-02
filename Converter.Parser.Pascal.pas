{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v6.0 Navigator
 Written and built in the USA}

unit Converter.Parser.Pascal;

interface

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.Generics.Collections,
  System.RegularExpressions,
  Converter.Core.Types;

type
  TPascalMethod = class
  private
    FName: string;
    FMethodType: string;
    FParameters: string;
    FReturnType: string;
    FBody: TStringList;
    FLocalRoutines: TStringList;
    FCalledRoutines: TStringList;
    FStartLine: Integer;
    FEndLine: Integer;
    FIsPublished: Boolean;
    FClassName: string;
    FFullName: string;
    FUnitName: string;
    FIsClassMethod: Boolean;
  public
    property Name: string read FName write FName;
    property MethodType: string read FMethodType write FMethodType;
    property Parameters: string read FParameters write FParameters;
    property ReturnType: string read FReturnType write FReturnType;
    property Body: TStringList read FBody;
    property LocalRoutines: TStringList read FLocalRoutines;
    property CalledRoutines: TStringList read FCalledRoutines;
    property StartLine: Integer read FStartLine write FStartLine;
    property EndLine: Integer read FEndLine write FEndLine;
    property IsPublished: Boolean read FIsPublished write FIsPublished;
    property PascalClassName: string read FClassName write FClassName;
    property FullName: string read FFullName write FFullName;
    property SourceUnitName: string read FUnitName write FUnitName;
    property IsClassMethod: Boolean read FIsClassMethod write FIsClassMethod;

    constructor Create;
    destructor Destroy; override;

    function FullSignature: string;
    function HasGDICalls: Boolean;
    function HasMessageCalls: Boolean;
    function HasWindowsSystemCommandHandling: Boolean;
    function HasWindowsSystemCommandSideEffects: Boolean;
    function HasSynchronizeCalls: Boolean;
    function UsesFMXCanvasSignature: Boolean;
    function GetDisplayName: string;
  end;

  TPascalSection = (psInterface, psImplementation, psInitialization, psFinalization, psUnknown);

  TPascalClass = class
  private
    FName: string;
    FParentClass: string;
    FDeclarationKind: string;
    FMethods: TList<TPascalMethod>;
    FFields: TStringList;
    FProperties: TStringList;
    FMethodDeclarations: TStringList;
    FMessageHandlers: TStringList;
    FStartLine: Integer;
    FEndLine: Integer;
  public
    property Name: string read FName write FName;
    property ParentClass: string read FParentClass write FParentClass;
    property DeclarationKind: string read FDeclarationKind write FDeclarationKind;
    property Methods: TList<TPascalMethod> read FMethods;
    property Fields: TStringList read FFields;
    property Properties: TStringList read FProperties;
    property MethodDeclarations: TStringList read FMethodDeclarations;
    property MessageHandlers: TStringList read FMessageHandlers;
    property StartLine: Integer read FStartLine write FStartLine;
    property EndLine: Integer read FEndLine write FEndLine;

    constructor Create;
    destructor Destroy; override;
  end;

  TPascalUnit = class
  private
    FUnitName: string;
    FUsesClause: TStringList;
    FInterfaceUses: TStringList;
    FImplementationUses: TStringList;
    FTypes: TStringList;
    FVariables: TStringList;
    FConstants: TStringList;
    FMethods: TObjectList<TPascalMethod>;
    FPublishedMethods: TObjectList<TPascalMethod>;
    FClasses: TObjectList<TPascalClass>;
    FCurrentSection: TPascalSection;
    FCurrentClass: TPascalClass;
    FImplementationUsesStart: Integer;
    FImplementationUsesEnd: Integer;
  public
    property SourceUnitName: string read FUnitName write FUnitName;
    property UsesClause: TStringList read FUsesClause;
    property InterfaceUses: TStringList read FInterfaceUses;
    property ImplementationUses: TStringList read FImplementationUses;
    property Types: TStringList read FTypes;
    property Variables: TStringList read FVariables;
    property Constants: TStringList read FConstants;
    property Methods: TObjectList<TPascalMethod> read FMethods;
    property PublishedMethods: TObjectList<TPascalMethod> read FPublishedMethods;
    property Classes: TObjectList<TPascalClass> read FClasses;
    property CurrentSection: TPascalSection read FCurrentSection write FCurrentSection;
    property CurrentClass: TPascalClass read FCurrentClass write FCurrentClass;
    property ImplementationUsesStart: Integer read FImplementationUsesStart write FImplementationUsesStart;
    property ImplementationUsesEnd: Integer read FImplementationUsesEnd write FImplementationUsesEnd;

    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  TPascalParser = class
  private
    FContext: TConversionContext;
    FCurrentUnit: TPascalUnit;
    FLines: TStringList;
    FClassStack: TStack<string>;

    procedure ParseUnit(const FileName: string);
    procedure ParseInterface;
    procedure ParseImplementation;
    procedure ParseUsesClause(StartIndex: Integer; var EndIndex: Integer; IsInterface: Boolean);
    procedure ParseMethod(StartIndex: Integer; var EndIndex: Integer);
    procedure ParseTypeSection(StartIndex: Integer; var EndIndex: Integer);
    procedure ParseVarSection(StartIndex: Integer; var EndIndex: Integer);
    procedure ParseConstSection(StartIndex: Integer; var EndIndex: Integer);
    procedure ParseClassDeclaration(const Line: string; StartIndex: Integer);

    function IsMethodDeclaration(const Line: string): Boolean;
    function IsClassDeclaration(const Line: string): Boolean;
    function IsClassMethodDeclaration(const Line: string): Boolean;
    function StripComments(const Line: string): string;
    function StripStringLiterals(const Line: string): string;
    function ExtractMethodName(const Declaration: string; out ClassName: string): string;
    function ExtractMethodType(const Declaration: string): string;
    function ExtractParameters(const Declaration: string): string;
    function ExtractReturnType(const Declaration: string): string;
    function ExtractClassName(const Line: string): string;
    function ExtractParentClass(const Line: string): string;
    function ExtractDeclarationKind(const Line: string): string;
    function GetCurrentContext: string;
    function IsMethodPrototypeLine(const Line: string): Boolean;
    function IsClassVisibilityLine(const Line: string): Boolean;
    function IsFieldDeclarationLine(const Line: string): Boolean;
    function IsPropertyDeclarationLine(const Line: string): Boolean;
    function IsMessageHandlerDeclarationLine(const Line: string): Boolean;
    function ExtractMemberName(const Line: string): string;
    function ExtractCalledRoutineName(const Line: string): string;
    procedure CollectMethodStructure(AMethod: TPascalMethod);
    procedure CloseCurrentClass(EndLine: Integer);
    procedure ParseClassMember(const Line: string);

  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    procedure Parse(const FileName: string; var Code: string);
    function FindMethod(const MethodName: string): TPascalMethod;
    function FindMethodsByPattern(const Pattern: string): TList<TPascalMethod>;

    property CurrentUnit: TPascalUnit read FCurrentUnit;
  end;

implementation

{ TPascalMethod }

constructor TPascalMethod.Create;
begin
  inherited Create;
  FBody := TStringList.Create;
  FLocalRoutines := TStringList.Create;
  FCalledRoutines := TStringList.Create;
  FLocalRoutines.CaseSensitive := False;
  FCalledRoutines.CaseSensitive := False;
  FName := '';
  FClassName := '';
  FFullName := '';
  FUnitName := '';
  FIsClassMethod := False;
end;

destructor TPascalMethod.Destroy;
begin
  FCalledRoutines.Free;
  FLocalRoutines.Free;
  FBody.Free;
  inherited;
end;

function TPascalMethod.GetDisplayName: string;
begin
  if FClassName <> '' then
    Result := FClassName + '.' + FName
  else
    Result := FName;

  if FUnitName <> '' then
    Result := FUnitName + '.' + Result;
end;

function TPascalMethod.FullSignature: string;
begin
  Result := FMethodType + ' ' + GetDisplayName;
  if FParameters <> '' then
    Result := Result + '(' + FParameters + ')';
  if FReturnType <> '' then
    Result := Result + ': ' + FReturnType;
end;

function TPascalMethod.HasGDICalls: Boolean;
var
  i: Integer;
  Line: string;
begin
  Result := False;
  for i := 0 to FBody.Count - 1 do
  begin
    Line := LowerCase(FBody[i]);

    // Do not flag code that is already using FMX-style canvas APIs.
    if (Pos('canvas.beginscene', Line) > 0) or
       (Pos('canvas.endscene', Line) > 0) or
       (Pos('canvas.filltext', Line) > 0) or
       (Pos('canvas.drawline', Line) > 0) or
       (Pos('canvas.drawrect', Line) > 0) or
       (Pos('canvas.fillrect', Line) > 0) or
       (Pos('canvas.drawellipse', Line) > 0) or
       (Pos('canvas.fillellipse', Line) > 0) or
       (Pos('talphacolor', Line) > 0) or
       (Pos('talphacolorrec', Line) > 0) then
      Continue;

    if (Pos('bitblt', Line) > 0) or
       (Pos('stretchblt', Line) > 0) or
       (Pos('maskblt', Line) > 0) or
       (TRegEx.IsMatch(Line, '\balphablend\s*\(', [roIgnoreCase]) and
        (Pos('.alphablend', Line) = 0) and
        (Pos('generatedalphablend', Line) = 0)) or
       (Pos('createcompatibledc', Line) > 0) or
       (Pos('createcompatiblebitmap', Line) > 0) or
       (Pos('setdibits', Line) > 0) or
       (Pos('getdibits', Line) > 0) or
       (Pos('polybezier', Line) > 0) or
       (Pos('getdc(', Line) > 0) or
       (Pos('releasedc(', Line) > 0) or
       (Pos('beginpaint(', Line) > 0) or
       (Pos('endpaint(', Line) > 0) or
       (Pos('invalidaterect(', Line) > 0) or
       (Pos('updatewindow(', Line) > 0) or
       (Pos('createpen(', Line) > 0) or
       (Pos('createsolidbrush(', Line) > 0) or
       (Pos('selectobject(', Line) > 0) or
       (Pos('deleteobject(', Line) > 0) or
       (Pos('getstockobject(', Line) > 0) or
       (Pos('setbkmode(', Line) > 0) or
       (Pos('settextcolor(', Line) > 0) then
    begin
      Result := True;
      Exit;
    end;

    if (Pos('canvas.', Line) > 0) and
       ((Pos('textout', Line) > 0) or
        (Pos('lineto', Line) > 0) or
        (Pos('moveto', Line) > 0) or
        (Pos('framerect', Line) > 0) or
        (Pos('polygon', Line) > 0) or
        (Pos('polyline', Line) > 0) or
        TRegEx.IsMatch(Line, '\bpie\b') or
        TRegEx.IsMatch(Line, '\barc\b') or
        (Pos('chord', Line) > 0) or
        (Pos('canvas.rectangle', Line) > 0) or
        (Pos('canvas.ellipse', Line) > 0)) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;
function TPascalMethod.HasMessageCalls: Boolean;
var
  i: Integer;
  SanIdx: Integer;
  Line: string;
  SanitizedLine: string;
  InString: Boolean;
  function ContainsStandaloneToken(const Source, Token: string): Boolean;
  var
    StartPos: Integer;
    BeforeChar: Char;
    AfterChar: Char;
    TokenLen: Integer;
    function IsIdentChar(const Value: Char): Boolean;
    begin
      Result := CharInSet(Value, ['A'..'Z', 'a'..'z', '0'..'9', '_']);
    end;
  begin
    Result := False;
    TokenLen := Length(Token);
    StartPos := Pos(Token, Source);
    while StartPos > 0 do
    begin
      if StartPos > 1 then
        BeforeChar := Source[StartPos - 1]
      else
        BeforeChar := #0;

      if (StartPos + TokenLen) <= Length(Source) then
        AfterChar := Source[StartPos + TokenLen]
      else
        AfterChar := #0;

      if (BeforeChar <> '.') and not IsIdentChar(BeforeChar) and
         not IsIdentChar(AfterChar) then
        Exit(True);

      StartPos := PosEx(Token, Source, StartPos + TokenLen);
    end;
  end;
begin
  Result := False;
  for i := 0 to FBody.Count - 1 do
  begin
    Line := TRegEx.Replace(FBody[i], '//.*$', '');
    if TRegEx.IsMatch(Line,
         '\.\s*perform\s*\(\s*(em_scrollcaret|wm_vscroll)\b',
         [roIgnoreCase]) then
      Continue;

    SanitizedLine := '';
    InString := False;
    SanIdx := 1;
    while SanIdx <= Length(Line) do
    begin
      if Line[SanIdx] = '''' then
      begin
        if not InString then
          InString := True
        else if (SanIdx < Length(Line)) and (Line[SanIdx + 1] = '''') then
        begin
          SanitizedLine := SanitizedLine + '  ';
          Inc(SanIdx, 2);
          Continue;
        end
        else
          InString := False;
        SanitizedLine := SanitizedLine + ' ';
      end
      else if InString then
        SanitizedLine := SanitizedLine + ' '
      else
        SanitizedLine := SanitizedLine + Line[SanIdx];
      Inc(SanIdx);
    end;

    // Message constants are conventionally uppercase. Keeping this match
    // case-sensitive prevents ordinary lower-case domain identifiers such as
    // cm_custom_mode or tcmWidgetName from becoming Windows-message hits.
    if TRegEx.IsMatch(SanitizedLine,
         '\b(WM|CM|CN|EM|LB|CB|LVM|TVM|TCM)_[A-Z0-9_]+\b') or
       TRegEx.IsMatch(SanitizedLine,
         '\b(sendmessage|postmessage)\s*\(.*\b(handle|hwnd|wm_|cm_|cn_|em_|lb_|cb_|lvm_|tvm_|tcm_)',
         [roIgnoreCase]) or
       TRegEx.IsMatch(SanitizedLine,
         '\b(dispatchmessage|peekmessage|getmessage|translatemessage)\s*\(\s*(msg|message|tmsg\b|pmsg\b|@)',
         [roIgnoreCase]) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TPascalMethod.HasWindowsSystemCommandHandling: Boolean;
begin
  Result := TRegEx.IsMatch(FBody.Text, '\b(WM_SYSCOMMAND|TWMSysCommand|SC_CLOSE|SC_MINIMIZE|SC_MAXIMIZE|SC_RESTORE)\b',
    [roIgnoreCase]);
end;

function TPascalMethod.HasWindowsSystemCommandSideEffects: Boolean;
begin
  Result := TRegEx.IsMatch(FBody.Text,
    '\b(SC_MINIMIZE|SC_MAXIMIZE|SC_RESTORE)\b[\s\S]*\b(Enabled\s*:=|WindowState\s*:=|Show|Hide|PostMessage|SendMessage|Application\.)',
    [roIgnoreCase]);
end;
function TPascalMethod.HasSynchronizeCalls: Boolean;
var
  i: Integer;
  Line: string;
begin
  Result := False;
  for i := 0 to FBody.Count - 1 do
  begin
    Line := LowerCase(FBody[i]);
    if (Pos('synchronize', Line) > 0) or
       (Pos('queue', Line) > 0) or
       (Pos('criticalsection', Line) > 0) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

{ TPascalClass }

constructor TPascalClass.Create;
begin
  inherited Create;
  FMethods := TList<TPascalMethod>.Create;
  FFields := TStringList.Create;
  FProperties := TStringList.Create;
  FMethodDeclarations := TStringList.Create;
  FMessageHandlers := TStringList.Create;
  FFields.CaseSensitive := False;
  FProperties.CaseSensitive := False;
  FMethodDeclarations.CaseSensitive := False;
  FMessageHandlers.CaseSensitive := False;
end;

destructor TPascalClass.Destroy;
begin
  FMessageHandlers.Free;
  FMethodDeclarations.Free;
  FProperties.Free;
  FFields.Free;
  FMethods.Free;
  inherited;
end;

{ TPascalUnit }

constructor TPascalUnit.Create;
begin
  inherited Create;
  FUsesClause := TStringList.Create;
  FInterfaceUses := TStringList.Create;
  FImplementationUses := TStringList.Create;
  FTypes := TStringList.Create;
  FVariables := TStringList.Create;
  FConstants := TStringList.Create;
  FMethods := TObjectList<TPascalMethod>.Create(True);
  FPublishedMethods := TObjectList<TPascalMethod>.Create(False);
  FClasses := TObjectList<TPascalClass>.Create(True);
  FCurrentSection := psInterface;
  FCurrentClass := nil;
  FImplementationUsesStart := -1;
  FImplementationUsesEnd := -1;
end;

destructor TPascalUnit.Destroy;
begin
  FUsesClause.Free;
  FInterfaceUses.Free;
  FImplementationUses.Free;
  FTypes.Free;
  FVariables.Free;
  FConstants.Free;
  FMethods.Free;
  FPublishedMethods.Free;
  FClasses.Free;
  inherited;
end;

procedure TPascalUnit.Clear;
begin
  FUsesClause.Clear;
  FInterfaceUses.Clear;
  FImplementationUses.Clear;
  FTypes.Clear;
  FVariables.Clear;
  FConstants.Clear;
  FMethods.Clear;
  FPublishedMethods.Clear;
  FClasses.Clear;
  FCurrentClass := nil;
  FImplementationUsesStart := -1;
  FImplementationUsesEnd := -1;
end;

{ TPascalParser }

constructor TPascalParser.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;
  FCurrentUnit := TPascalUnit.Create;
  FLines := TStringList.Create;
  FClassStack := TStack<string>.Create;
end;

destructor TPascalParser.Destroy;
begin
  FClassStack.Free;
  FCurrentUnit.Free;
  FLines.Free;
  inherited;
end;

function TPascalParser.GetCurrentContext: string;
begin
  if FClassStack.Count > 0 then
    Result := FClassStack.Peek
  else
    Result := '';
end;

procedure TPascalParser.Parse(const FileName: string; var Code: string);
begin
  FContext.AddIssue(csInfo, 'Deep parsing: ' + ExtractFileName(FileName));

  try
    FLines.Text := VCL2FMXStripCommentsForAnalysis(Code);
    FCurrentUnit.Clear;
    FClassStack.Clear;

    ParseUnit(FileName);

    FContext.AddIssue(csInfo, Format('Parsed %d methods in %s',
      [FCurrentUnit.Methods.Count, ExtractFileName(FileName)]));

  except
    on E: Exception do
      FContext.AddIssue(
        csWarning,
        'Parser warning in ' + FileName + ': ' + E.Message
      );
  end;
end;

procedure TPascalParser.ParseUnit(const FileName: string);
var
  i: Integer;
  Line: string;
begin
  i := 0;
  while i < FLines.Count do
  begin
    Line := Trim(FLines[i]);

    if (Line = '') or Line.StartsWith('//') or Line.StartsWith('{') then
    begin
      Inc(i);
      Continue;
    end;

    if Line.StartsWith('unit ', True) then
    begin
      FCurrentUnit.SourceUnitName := Copy(Line, 6, Length(Line) - 5).Replace(';', '').Trim;
      Inc(i);
    end
    else if VCL2FMXIsPascalKeywordLine(Line, 'interface') then
    begin
      FCurrentUnit.CurrentSection := psInterface;
      ParseInterface;
      Break;
    end
    else
      Inc(i);
  end;
end;

procedure TPascalParser.ParseInterface;
var
  i: Integer;
  Line: string;
begin
  i := 0;
  while (i < FLines.Count) and not VCL2FMXIsPascalKeywordLine(FLines[i], 'interface') do
    Inc(i);

  if i < FLines.Count then
    Inc(i);

  while i < FLines.Count do
  begin
    Line := Trim(FLines[i]);

    if VCL2FMXIsPascalKeywordLine(Line, 'implementation') then
    begin
      FClassStack.Clear;
      FCurrentUnit.CurrentClass := nil;
      FCurrentUnit.CurrentSection := psImplementation;
      ParseImplementation;
      Break;
    end;

    if VCL2FMXIsPascalKeywordLine(Line, 'uses') then
    begin
      ParseUsesClause(i, i, True);
      Continue;
    end;

    if VCL2FMXIsPascalKeywordLine(Line, 'type') then
    begin
      ParseTypeSection(i, i);
      Continue;
    end;

    if VCL2FMXIsPascalKeywordLine(Line, 'var') then
    begin
      ParseVarSection(i, i);
      Continue;
    end;

    if VCL2FMXIsPascalKeywordLine(Line, 'const') then
    begin
      ParseConstSection(i, i);
      Continue;
    end;

    if IsClassDeclaration(Line) then
    begin
      ParseClassDeclaration(Line, i);
      Inc(i);
      Continue;
    end;

    if IsMethodDeclaration(Line) then
    begin
      ParseMethod(i, i);
      Continue;
    end;

    Inc(i);
  end;
end;

procedure TPascalParser.ParseImplementation;
var
  i: Integer;
  Line: string;
begin
  i := 0;
  while (i < FLines.Count) and not VCL2FMXIsPascalKeywordLine(FLines[i], 'implementation') do
    Inc(i);

  if i < FLines.Count then
    Inc(i);

  while i < FLines.Count do
  begin
    Line := Trim(FLines[i]);

    if VCL2FMXIsPascalKeywordLine(Line, 'initialization') or
       VCL2FMXIsPascalKeywordLine(Line, 'finalization') then
    begin
      Break;
    end;

    if VCL2FMXIsPascalKeywordLine(Line, 'uses') then
    begin
      FCurrentUnit.ImplementationUsesStart := i;
      ParseUsesClause(i, i, False);
      FCurrentUnit.ImplementationUsesEnd := i;
      Continue;
    end;

    if IsMethodDeclaration(Line) then
    begin
      ParseMethod(i, i);
      Continue;
    end;

    Inc(i);
  end;
end;

procedure TPascalParser.ParseClassDeclaration(const Line: string; StartIndex: Integer);
var
  ClassName: string;
  ParentClass: string;
  NewClass: TPascalClass;
begin
  ClassName := ExtractClassName(Line);
  ParentClass := ExtractParentClass(Line);

  if ClassName <> '' then
  begin
    NewClass := TPascalClass.Create;
    NewClass.Name := ClassName;
    NewClass.ParentClass := ParentClass;
    NewClass.DeclarationKind := ExtractDeclarationKind(Line);
    NewClass.StartLine := StartIndex;

    FCurrentUnit.Classes.Add(NewClass);
    FClassStack.Push(ClassName);
    FCurrentUnit.CurrentClass := NewClass;
  end;
end;

function TPascalMethod.UsesFMXCanvasSignature: Boolean;
begin
  Result := ContainsText(FParameters, 'Canvas: TCanvas') and
            (ContainsText(FParameters, 'TRectF') or
             ContainsText(FParameters, 'TGridDrawStates') or
             ContainsText(FParameters, 'TValue'));
end;

function TPascalParser.IsClassVisibilityLine(const Line: string): Boolean;
var
  L: string;
begin
  L := LowerCase(Trim(StripComments(Line)));
  Result := (L = 'private') or (L = 'protected') or (L = 'public') or
            (L = 'published') or (L = 'strict private') or
            (L = 'strict protected');
end;

function TPascalParser.IsPropertyDeclarationLine(const Line: string): Boolean;
var
  L: string;
begin
  L := LowerCase(Trim(StripComments(Line)));
  L := StripStringLiterals(L);
  Result := VCL2FMXIsPascalKeywordLine(L, 'property');
end;

function TPascalParser.IsMessageHandlerDeclarationLine(const Line: string): Boolean;
var
  L: string;
begin
  L := StripComments(Line);
  L := StripStringLiterals(L);
  Result := TRegEx.IsMatch(L,
    '\bmessage\s+(WM_|CM_|CN_|EM_|LB_|CB_|LVM_|TVM_|TCM_)[A-Za-z0-9_]*\s*;',
    [roIgnoreCase]);
end;

function TPascalParser.ExtractMemberName(const Line: string): string;
var
  L: string;
  ColonPos: Integer;
  SpacePos: Integer;
  ParenPos: Integer;
  SemiPos: Integer;
begin
  Result := '';
  L := Trim(StripComments(Line));
  L := StripStringLiterals(L);
  if L = '' then
    Exit;

  if L.StartsWith('property ', True) then
    L := Trim(Copy(L, Length('property ') + 1, MaxInt))
  else if L.StartsWith('class procedure ', True) then
    L := Trim(Copy(L, Length('class procedure ') + 1, MaxInt))
  else if L.StartsWith('class function ', True) then
    L := Trim(Copy(L, Length('class function ') + 1, MaxInt))
  else if L.StartsWith('procedure ', True) then
    L := Trim(Copy(L, Length('procedure ') + 1, MaxInt))
  else if L.StartsWith('function ', True) then
    L := Trim(Copy(L, Length('function ') + 1, MaxInt))
  else if L.StartsWith('constructor ', True) then
    L := Trim(Copy(L, Length('constructor ') + 1, MaxInt))
  else if L.StartsWith('destructor ', True) then
    L := Trim(Copy(L, Length('destructor ') + 1, MaxInt));

  ColonPos := Pos(':', L);
  SpacePos := Pos(' ', L);
  ParenPos := Pos('(', L);
  SemiPos := Pos(';', L);

  if (ParenPos > 0) and ((ColonPos = 0) or (ParenPos < ColonPos)) and
     ((SpacePos = 0) or (ParenPos < SpacePos)) then
    Result := Copy(L, 1, ParenPos - 1)
  else if (ColonPos > 0) and ((SpacePos = 0) or (ColonPos < SpacePos)) then
    Result := Copy(L, 1, ColonPos - 1)
  else if (SemiPos > 0) and ((SpacePos = 0) or (SemiPos < SpacePos)) then
    Result := Copy(L, 1, SemiPos - 1)
  else if SpacePos > 0 then
    Result := Copy(L, 1, SpacePos - 1)
  else
    Result := L;

  Result := Trim(Result);
end;

function TPascalParser.IsFieldDeclarationLine(const Line: string): Boolean;
var
  L: string;
begin
  L := Trim(StripComments(Line));
  L := StripStringLiterals(L);
  Result := (L <> '') and L.EndsWith(';') and (Pos(':', L) > 0) and
            not IsPropertyDeclarationLine(L) and
            not IsMethodDeclaration(L) and
            not IsClassVisibilityLine(L) and
            (Pos('=', L) = 0);
end;

function TPascalParser.ExtractCalledRoutineName(const Line: string): string;
var
  L: string;
  Match: TMatch;
begin
  Result := '';
  L := StripComments(Line);
  L := StripStringLiterals(L);

  Match := TRegEx.Match(L,
    '(?<![A-Za-z0-9_\.])([A-Za-z_][A-Za-z0-9_]*)\s*\(',
    [roIgnoreCase]);
  if Match.Success then
    Result := Match.Groups[1].Value;
end;

procedure TPascalParser.CollectMethodStructure(AMethod: TPascalMethod);
var
  I: Integer;
  L: string;
  Name: string;
  ClassName: string;
begin
  if AMethod = nil then
    Exit;

  for I := 0 to AMethod.Body.Count - 1 do
  begin
    L := Trim(AMethod.Body[I]);
    if L = '' then
      Continue;

    if (I > 0) and IsMethodDeclaration(L) then
    begin
      Name := ExtractMethodName(L, ClassName);
      if (Name <> '') and (AMethod.LocalRoutines.IndexOf(Name) = -1) then
        AMethod.LocalRoutines.Add(Name);
      Continue;
    end;

    Name := ExtractCalledRoutineName(L);
    if (Name <> '') and (AMethod.CalledRoutines.IndexOf(Name) = -1) then
      AMethod.CalledRoutines.Add(Name);
  end;
end;
procedure TPascalParser.ParseClassMember(const Line: string);
var
  MemberName: string;
begin
  if FCurrentUnit.CurrentClass = nil then
    Exit;

  if IsClassVisibilityLine(Line) then
    Exit;

  MemberName := ExtractMemberName(Line);
  if MemberName = '' then
    Exit;

  if IsPropertyDeclarationLine(Line) then
  begin
    FCurrentUnit.CurrentClass.Properties.Add(MemberName);
    Exit;
  end;

  if IsMethodDeclaration(Line) then
  begin
    FCurrentUnit.CurrentClass.MethodDeclarations.Add(MemberName);
    if IsMessageHandlerDeclarationLine(Line) then
      FCurrentUnit.CurrentClass.MessageHandlers.Add(MemberName + '=' + Trim(Line));
    Exit;
  end;

  if IsFieldDeclarationLine(Line) then
    FCurrentUnit.CurrentClass.Fields.Add(MemberName);
end;
procedure TPascalParser.CloseCurrentClass(EndLine: Integer);
begin
  if FCurrentUnit.CurrentClass <> nil then
  begin
    FCurrentUnit.CurrentClass.EndLine := EndLine;
    FCurrentUnit.CurrentClass := nil;
  end;

  if FClassStack.Count > 0 then
    FClassStack.Pop;
end;

function TPascalParser.ExtractDeclarationKind(const Line: string): string;
var
  L: string;
begin
  L := LowerCase(StripComments(Line));
  L := StripStringLiterals(L);

  if TRegEx.IsMatch(L, '=\s*class\s+helper\b', [roIgnoreCase]) then
    Result := 'class helper'
  else if TRegEx.IsMatch(L, '=\s*record\s+helper\b', [roIgnoreCase]) then
    Result := 'record helper'
  else if TRegEx.IsMatch(L, '=\s*class\b', [roIgnoreCase]) then
    Result := 'class'
  else if TRegEx.IsMatch(L, '=\s*record\b', [roIgnoreCase]) then
    Result := 'record'
  else if TRegEx.IsMatch(L, '=\s*interface\b', [roIgnoreCase]) then
    Result := 'interface'
  else
    Result := 'type';
end;
function TPascalParser.ExtractParentClass(const Line: string): string;
var
  L: string;
  ParenPos: Integer;
  CloseParenPos: Integer;
begin
  L := StripComments(Line);
  L := StripStringLiterals(L);

  ParenPos := Pos('(', L);
  if ParenPos > 0 then
  begin
    CloseParenPos := Pos(')', Copy(L, ParenPos + 1, Length(L)));
    if CloseParenPos > 0 then
    begin
      Result := Copy(L, ParenPos + 1, CloseParenPos - 1);
      Result := Trim(Result);
    end
    else
      Result := 'TObject';
  end
  else
    Result := 'TObject';
end;

function TPascalParser.ExtractClassName(const Line: string): string;
var
  L: string;
  Parts: TArray<string>;
begin
  Result := '';
  L := StripComments(Line);
  L := StripStringLiterals(L);

  if TRegEx.IsMatch(L, '=\s*(class|record|interface)(\s+helper)?\b', [roIgnoreCase]) then
  begin
    Parts := L.Split(['=']);
    if Length(Parts) > 0 then
    begin
      Result := Trim(Parts[0]);
      if Result.StartsWith('type ', True) then
        Result := Copy(Result, 6, Length(Result) - 5);
      Result := Trim(Result);
    end;
  end;
end;

function TPascalParser.IsClassDeclaration(const Line: string): Boolean;
var
  L: string;
begin
  L := LowerCase(StripComments(Line));
  L := StripStringLiterals(L);
  Result := TRegEx.IsMatch(L,
    '=\s*(class|record|interface)(\s+helper)?\b', [roIgnoreCase]);
end;

function TPascalParser.IsClassMethodDeclaration(const Line: string): Boolean;
var
  L: string;
begin
  L := LowerCase(StripComments(Line));
  L := StripStringLiterals(L);

  Result := (VCL2FMXIsPascalKeywordLine(L, 'class procedure') or
             VCL2FMXIsPascalKeywordLine(L, 'class function')) and
            (not L.Contains('= procedure')) and
            (not L.Contains('= function'));
end;

procedure TPascalParser.ParseUsesClause(StartIndex: Integer; var EndIndex: Integer; IsInterface: Boolean);
var
  i: Integer;
  Line: string;
  UsesLine: string;
  Units: TArray<string>;
  UnitName: string;
  UnitIndex: Integer;
begin
  i := StartIndex;
  UsesLine := '';

  while i < FLines.Count do
  begin
    Line := Trim(FLines[i]);
    UsesLine := UsesLine + ' ' + Line;

    if Line.EndsWith(';') then
    begin
      EndIndex := i;
      Inc(i);
      Break;
    end;

    Inc(i);
  end;

  UsesLine := UsesLine.Replace('uses', '', [rfIgnoreCase]);
  UsesLine := UsesLine.Replace(';', '', [rfReplaceAll]);

  Units := UsesLine.Split([',']);

  for UnitIndex := 0 to High(Units) do
  begin
    UnitName := Trim(Units[UnitIndex]);
    if UnitName <> '' then
    begin
      FCurrentUnit.UsesClause.Add(UnitName);
      if IsInterface then
        FCurrentUnit.InterfaceUses.Add(UnitName)
      else
        FCurrentUnit.ImplementationUses.Add(UnitName);
    end;
  end;

  EndIndex := i;
end;

procedure TPascalParser.ParseMethod(StartIndex: Integer; var EndIndex: Integer);
var
  CurrentLine: Integer;
  Line: string;
  CleanLine: string;
  Method: TPascalMethod;
  InBody: Boolean;
  SawBegin: Boolean;
  BlockDepth: Integer;
  ClassName: string;
  ContextClass: string;
  MethodName: string;
  VisibilityIndex: Integer;
  VisibilityLine: string;
begin
  Method := TPascalMethod.Create;
  try
    Method.StartLine := StartIndex;
    Method.SourceUnitName := FCurrentUnit.SourceUnitName;
    InBody := False;
    SawBegin := False;
    BlockDepth := 0;

    ContextClass := GetCurrentContext;

    Line := FLines[StartIndex];
    CleanLine := StripComments(Line);
    CleanLine := StripStringLiterals(CleanLine);

    Method.MethodType := ExtractMethodType(CleanLine);

    MethodName := ExtractMethodName(CleanLine, ClassName);

    if MethodName = '' then
    begin
      MethodName := 'UnknownMethod_' + IntToStr(StartIndex);
    end;

    Method.Name := MethodName;

    if ClassName <> '' then
      Method.PascalClassName := ClassName
    else
      Method.PascalClassName := ContextClass;

    if Method.PascalClassName <> '' then
    begin
      if Method.Name <> '' then
        Method.FFullName := Method.PascalClassName + '.' + Method.Name
      else
        Method.FFullName := Method.PascalClassName + '.UnknownMethod';
    end
    else
    begin
      if Method.Name <> '' then
        Method.FFullName := Method.Name
      else
        Method.FFullName := 'UnknownMethod';
    end;

    Method.Parameters := ExtractParameters(CleanLine);
    Method.ReturnType := ExtractReturnType(CleanLine);
    Method.IsClassMethod := IsClassMethodDeclaration(Line);

    Method.IsPublished := False;
    VisibilityIndex := StartIndex - 1;
    while VisibilityIndex >= 0 do
    begin
      VisibilityLine := Trim(FLines[VisibilityIndex]);
      if VisibilityLine = '' then
      begin
        Dec(VisibilityIndex);
        Continue;
      end;

      if IsClassVisibilityLine(VisibilityLine) then
      begin
        Method.IsPublished := VCL2FMXIsPascalKeywordLine(VisibilityLine, 'published');
        Break;
      end;

      if VCL2FMXIsPascalKeywordLine(VisibilityLine, 'implementation') or
         VCL2FMXIsPascalKeywordLine(VisibilityLine, 'interface') or
         SameText(VisibilityLine, 'end;') then
        Break;

      Dec(VisibilityIndex);
    end;

    Method.Body.Add(Line);

    if (FCurrentUnit.CurrentSection = psInterface) and IsMethodPrototypeLine(Line) then
    begin
      Method.EndLine := StartIndex;
      CurrentLine := StartIndex + 1;
      EndIndex := CurrentLine;
    end
    else
    begin
      CurrentLine := StartIndex + 1;
      while CurrentLine < FLines.Count do
      begin
        Line := FLines[CurrentLine];
        Method.Body.Add(Line);

        CleanLine := LowerCase(Trim(StripComments(Line)));
        CleanLine := StripStringLiterals(CleanLine);

        if (not SawBegin) and TRegEx.IsMatch(CleanLine, '^begin\b', [roIgnoreCase]) then
        begin
          InBody := True;
          SawBegin := True;
        end;

        if SawBegin then
        begin
          Inc(BlockDepth, TRegEx.Matches(CleanLine,
            '\b(begin|case|try|record|repeat)\b', [roIgnoreCase]).Count);
          Dec(BlockDepth, TRegEx.Matches(CleanLine,
            '\b(end|until)\b', [roIgnoreCase]).Count);

          if (InBody and (BlockDepth <= 0) and
              TRegEx.IsMatch(CleanLine, '\bend\s*;', [roIgnoreCase])) then
          begin
            Method.EndLine := CurrentLine;
            Inc(CurrentLine);
            EndIndex := CurrentLine;
            Break;
          end;
        end;

        if (not SawBegin) and IsMethodDeclaration(CleanLine) then
        begin
          Method.Body.Delete(Method.Body.Count - 1);
          Method.EndLine := CurrentLine - 1;
          EndIndex := CurrentLine;
          Break;
        end;

        if (not SawBegin) and VCL2FMXIsPascalKeywordLine(Line, 'implementation') then
        begin
          Method.Body.Delete(Method.Body.Count - 1);
          Method.EndLine := CurrentLine - 1;
          EndIndex := CurrentLine;
          Break;
        end;

        Inc(CurrentLine);
      end;

      if CurrentLine >= FLines.Count then
        EndIndex := CurrentLine;
    end;

    CollectMethodStructure(Method);

    FCurrentUnit.Methods.Add(Method);

    if (FCurrentUnit.CurrentClass <> nil) and (Method.PascalClassName <> '') then
      FCurrentUnit.CurrentClass.Methods.Add(Method);

    if Method.IsPublished then
      FCurrentUnit.PublishedMethods.Add(Method);

    if Method.HasGDICalls and not Method.UsesFMXCanvasSignature then
      FContext.AddIssue(
        csInfo,
        Format('Method %s uses VCL/GDI drawing APIs.', [Method.GetDisplayName]),
        'Graphics or GDI usage',
        '',
        'Review this method in the IDE and verify that the generated FMX Canvas code still matches the intended behavior.',
        Method.StartLine + 1
      );

    if Method.HasMessageCalls then
    begin
      if Method.HasWindowsSystemCommandHandling then
        FContext.AddIssue(
          csInfo,
          Format('Method %s uses Windows system command message handling.', [Method.GetDisplayName]),
          'Windows messages or message handlers',
          Trim(Method.Body.Text),
          'Windows system command handling needs FMX review. SC_CLOSE may map to Close or OnCloseQuery, but SC_MINIMIZE, SC_RESTORE, and SC_MAXIMIZE handlers often carry lifecycle or timer side effects that need an explicit FMX design decision.',
          Method.StartLine + 1
        )
      else
        FContext.AddIssue(
          csInfo,
          Format('Method %s uses Windows message-based behavior.', [Method.GetDisplayName]),
          'Windows messages or message handlers',
          Trim(Method.Body.Text),
          'Review this method in the IDE. FMX may need an event-based or platform-specific replacement for the original VCL message flow.',
          Method.StartLine + 1
        );

      if Method.HasWindowsSystemCommandSideEffects then
        FContext.AddIssue(
          csManualReview,
          Format('Method %s handles Windows system commands with side effects.', [Method.GetDisplayName]),
          'Windows system command side effects',
          Trim(Method.Body.Text),
          'Keep this as manual review unless a project-specific FMX lifecycle event, timer policy, or platform service replacement is chosen.',
          Method.StartLine + 1
        );
    end;

    if Method.HasSynchronizeCalls then
      FContext.AddIssue(
        csInfo,
        Format('Method %s marshals work back to the main thread.', [Method.GetDisplayName]),
        'Thread synchronization',
        '',
        'Review this method in the IDE and verify that the FMX thread marshaling still matches the original behavior.',
        Method.StartLine + 1
      );

  except
    on E: Exception do
    begin
      if (FCurrentUnit <> nil) and (FCurrentUnit.CurrentClass <> nil) and
         (FCurrentUnit.CurrentClass.Methods <> nil) then
        FCurrentUnit.CurrentClass.Methods.Remove(Method);
      if (FCurrentUnit <> nil) and (FCurrentUnit.PublishedMethods <> nil) then
        FCurrentUnit.PublishedMethods.Remove(Method);
      if (FCurrentUnit <> nil) and (FCurrentUnit.Methods <> nil) and
         (FCurrentUnit.Methods.IndexOf(Method) >= 0) then
        FCurrentUnit.Methods.Extract(Method).Free
      else
        Method.Free;
      raise;
    end;
  end;

  if Method.EndLine = 0 then
    Method.EndLine := EndIndex;
end;

procedure TPascalParser.ParseTypeSection(StartIndex: Integer; var EndIndex: Integer);
var
  i: Integer;
  Line: string;
  CleanLine: string;
  MemberLine: string;
  EndTokenMatch: TMatch;
  PreviousLine: string;
  HasInlineVisibility: Boolean;
  BoundaryMessage: string;
  BoundarySuggestion: string;
  ParenDepth: Integer;
  LineParenDepth: Integer;
begin
  i := StartIndex + 1;
  ParenDepth := 0;

  while i < FLines.Count do
  begin
    Line := Trim(FLines[i]);
    CleanLine := StripStringLiterals(StripComments(Line));
    LineParenDepth := ParenDepth +
      TRegEx.Matches(CleanLine, '\(').Count -
      TRegEx.Matches(CleanLine, '\)').Count;
    if LineParenDepth < 0 then
      LineParenDepth := 0;

    if (ParenDepth = 0) and
       (((FCurrentUnit.CurrentClass = nil) and
        (VCL2FMXIsPascalKeywordLine(Line, 'var') or
         VCL2FMXIsPascalKeywordLine(Line, 'const') or
         VCL2FMXIsPascalKeywordLine(Line, 'implementation') or
         VCL2FMXIsPascalKeywordLine(Line, 'procedure') or
         VCL2FMXIsPascalKeywordLine(Line, 'function') or
         VCL2FMXIsPascalKeywordLine(Line, 'constructor') or
         VCL2FMXIsPascalKeywordLine(Line, 'destructor'))) or
       ((FCurrentUnit.CurrentClass <> nil) and
        (VCL2FMXIsPascalKeywordLine(Line, 'var') or
         VCL2FMXIsPascalKeywordLine(Line, 'const') or
         VCL2FMXIsPascalKeywordLine(Line, 'implementation')))) then
    begin
      if FCurrentUnit.CurrentClass <> nil then
      begin
        BoundaryMessage :=
          'Pascal class declaration ended without a valid terminator before ' + Line;
        BoundarySuggestion :=
          'Review the class declaration terminator and rerun the conversion.';
        PreviousLine := StripStringLiterals(StripComments(Trim(FLines[i - 1])));
        HasInlineVisibility :=
          TRegEx.IsMatch(PreviousLine,
            '^(private|protected|public|published|strict\s+(private|protected))\s+',
            [roIgnoreCase]);
        if (i > StartIndex + 1) and
           not TRegEx.IsMatch(PreviousLine, '^end\s*;', [roIgnoreCase]) and
           not (HasInlineVisibility and
                TRegEx.IsMatch(PreviousLine, '\bend\s*;', [roIgnoreCase])) then
        begin
          BoundaryMessage := BoundaryMessage +
            '; the preceding class member may be missing a semicolon';
          BoundarySuggestion :=
            'Add the missing semicolon before end;, then rerun the conversion.';
        end;
        FContext.AddIssue(csError,
          BoundaryMessage,
          'Pascal class boundary',
          FLines[i],
          BoundarySuggestion,
          i + 1,
          True);
        CloseCurrentClass(i - 1);
      end;
      EndIndex := i;
      Exit;
    end;

    if IsClassDeclaration(Line) then
    begin
      ParseClassDeclaration(Line, i);
    end
    else if (LineParenDepth = 0) and
            TRegEx.IsMatch(Line, '^end\s*;', [roIgnoreCase]) and
            (FCurrentUnit.CurrentClass <> nil) then
      CloseCurrentClass(i)
    else if (LineParenDepth = 0) and
            TRegEx.IsMatch(CleanLine, '\bend\s*;', [roIgnoreCase]) and
            (FCurrentUnit.CurrentClass <> nil) then
    begin
      EndTokenMatch := TRegEx.Match(CleanLine, '\bend\s*;', [roIgnoreCase]);
      MemberLine := Trim(Copy(Line, 1, EndTokenMatch.Index));
      HasInlineVisibility := TRegEx.IsMatch(MemberLine,
        '^(private|protected|public|published|strict\s+(private|protected))\s+',
        [roIgnoreCase]);
      if HasInlineVisibility then
      begin
        MemberLine := TRegEx.Replace(MemberLine,
          '^(private|protected|public|published|strict\s+(private|protected))\s+',
          '', [roIgnoreCase]);
        MemberLine := Trim(MemberLine);
      end;
      if HasInlineVisibility then
      begin
        if MemberLine <> '' then
        begin
          if not MemberLine.TrimRight.EndsWith(';') then
            MemberLine := MemberLine + ';';
          ParseClassMember(MemberLine);
        end;
        CloseCurrentClass(i);
      end
      else if MemberLine = '' then
        CloseCurrentClass(i)
      else
      begin
        if not MemberLine.TrimRight.EndsWith(';') then
          MemberLine := MemberLine + ';';
        ParseClassMember(MemberLine);
        CloseCurrentClass(i);
      end;
    end
    else if FCurrentUnit.CurrentClass <> nil then
      ParseClassMember(Line);

    FCurrentUnit.Types.Add(FLines[i]);
    ParenDepth := LineParenDepth;
    Inc(i);
  end;

  EndIndex := i;
end;

procedure TPascalParser.ParseVarSection(StartIndex: Integer; var EndIndex: Integer);
var
  i: Integer;
  Line: string;
begin
  i := StartIndex + 1;

  while i < FLines.Count do
  begin
    Line := Trim(FLines[i]);

    if VCL2FMXIsPascalKeywordLine(Line, 'const') or
       VCL2FMXIsPascalKeywordLine(Line, 'implementation') or
       VCL2FMXIsPascalKeywordLine(Line, 'procedure') or
       VCL2FMXIsPascalKeywordLine(Line, 'function') or
       (VCL2FMXIsPascalKeywordLine(Line, 'type') and (FCurrentUnit.CurrentSection = psInterface)) then
    begin
      EndIndex := i;
      Exit;
    end;

    FCurrentUnit.Variables.Add(FLines[i]);
    Inc(i);
  end;

  EndIndex := i;
end;

procedure TPascalParser.ParseConstSection(StartIndex: Integer; var EndIndex: Integer);
var
  i: Integer;
  Line: string;
begin
  i := StartIndex + 1;

  while i < FLines.Count do
  begin
    Line := Trim(FLines[i]);

    if VCL2FMXIsPascalKeywordLine(Line, 'type') or
       VCL2FMXIsPascalKeywordLine(Line, 'var') or
       VCL2FMXIsPascalKeywordLine(Line, 'implementation') or
       VCL2FMXIsPascalKeywordLine(Line, 'procedure') or
       VCL2FMXIsPascalKeywordLine(Line, 'function') then
    begin
      EndIndex := i;
      Exit;
    end;

    FCurrentUnit.Constants.Add(FLines[i]);
    Inc(i);
  end;

  EndIndex := i;
end;

function TPascalParser.IsMethodDeclaration(const Line: string): Boolean;
var
  L: string;
begin
  L := LowerCase(StripComments(Line));
  L := StripStringLiterals(L);

  Result := (VCL2FMXIsPascalKeywordLine(L, 'procedure') or
             VCL2FMXIsPascalKeywordLine(L, 'function') or
             VCL2FMXIsPascalKeywordLine(L, 'constructor') or
             VCL2FMXIsPascalKeywordLine(L, 'destructor') or
             VCL2FMXIsPascalKeywordLine(L, 'class procedure') or
             VCL2FMXIsPascalKeywordLine(L, 'class function')) and
            (not L.Contains('= procedure')) and
            (not L.Contains('= function'));
end;

function TPascalParser.IsMethodPrototypeLine(const Line: string): Boolean;
var
  L: string;
begin
  L := Trim(StripComments(Line));
  L := StripStringLiterals(L);

  Result := (L <> '') and L.EndsWith(';') and
            not ContainsText(L, ' begin') and
            not SameText(L, 'end;');
end;

function TPascalParser.StripComments(const Line: string): string;
begin
  Result := VCL2FMXStripCommentsForAnalysis(Line, False);
end;

function TPascalParser.StripStringLiterals(const Line: string): string;
begin
  Result := VCL2FMXStripStringLiteralsForAnalysis(Line);
end;

function TPascalParser.ExtractMethodName(const Declaration: string; out ClassName: string): string;
var
  L: string;
  DotPos: Integer;
  SpacePos: Integer;
  ParenPos: Integer;
  SemicolonPos: Integer;
  Temp: string;
begin
  ClassName := '';

  if Trim(Declaration) = '' then
  begin
    Result := '';
    Exit;
  end;

  L := StripComments(Declaration);
  L := StripStringLiterals(L);
  L := Trim(L);

  if L.StartsWith('class ', True) then
    L := Copy(L, 7, Length(L) - 6);

  if L.StartsWith('procedure ', True) then
    L := Copy(L, 11, Length(L) - 10)
  else if L.StartsWith('function ', True) then
    L := Copy(L, 10, Length(L) - 9)
  else if L.StartsWith('constructor ', True) then
    L := Copy(L, 13, Length(L) - 12)
  else if L.StartsWith('destructor ', True) then
    L := Copy(L, 12, Length(L) - 11);

  L := Trim(L);

  if L = '' then
  begin
    Result := '';
    Exit;
  end;

  ParenPos := Pos('(', L);
  if ParenPos > 0 then
    DotPos := Pos('.', Copy(L, 1, ParenPos - 1))
  else
    DotPos := Pos('.', L);
  if DotPos > 0 then
  begin
    ClassName := Copy(L, 1, DotPos - 1);
    L := Copy(L, DotPos + 1, Length(L) - DotPos);
    L := Trim(L);
    ParenPos := Pos('(', L);
  end;

  SpacePos := Pos(' ', L);
  SemicolonPos := Pos(';', L);

  if (ParenPos > 0) and ((SpacePos = 0) or (ParenPos < SpacePos)) then
    Result := Copy(L, 1, ParenPos - 1)
  else if (SemicolonPos > 0) and ((SpacePos = 0) or (SemicolonPos < SpacePos)) then
    Result := Copy(L, 1, SemicolonPos - 1)
  else if SpacePos > 0 then
    Result := Copy(L, 1, SpacePos - 1)
  else
  begin
    Temp := L;
    if Temp.EndsWith(';') then
      Temp := Copy(Temp, 1, Length(Temp) - 1);
    if Temp.EndsWith(':') then
      Temp := Copy(Temp, 1, Length(Temp) - 1);
    Result := Temp;
  end;

  Result := Trim(Result);
  if Result.EndsWith(':') then
    Result := Trim(Copy(Result, 1, Length(Result) - 1));

  if Result = '' then
    Result := 'UnknownMethod';
end;

function TPascalParser.ExtractMethodType(const Declaration: string): string;
var
  L: string;
begin
  L := LowerCase(Trim(Declaration));
  if VCL2FMXIsPascalKeywordLine(L, 'class procedure') then
    Result := 'class procedure'
  else if VCL2FMXIsPascalKeywordLine(L, 'class function') then
    Result := 'class function'
  else if VCL2FMXIsPascalKeywordLine(L, 'procedure') then
    Result := 'procedure'
  else if VCL2FMXIsPascalKeywordLine(L, 'function') then
    Result := 'function'
  else if VCL2FMXIsPascalKeywordLine(L, 'constructor') then
    Result := 'constructor'
  else if VCL2FMXIsPascalKeywordLine(L, 'destructor') then
    Result := 'destructor'
  else
    Result := 'procedure';
end;

function TPascalParser.ExtractParameters(const Declaration: string): string;
var
  L: string;
  ParenPos: Integer;
  EndPos: Integer;
  Level: Integer;
  i: Integer;
begin
  L := StripComments(Declaration);
  L := StripStringLiterals(L);

  ParenPos := Pos('(', L);
  if ParenPos = 0 then
    Exit('');

  Level := 1;
  i := ParenPos + 1;
  while i <= Length(L) do
  begin
    if L[i] = '(' then
      Inc(Level)
    else if L[i] = ')' then
    begin
      Dec(Level);
      if Level = 0 then
      begin
        EndPos := i;
        Result := Copy(L, ParenPos + 1, EndPos - ParenPos - 1);
        Result := Trim(Result);
        Exit;
      end;
    end;
    Inc(i);
  end;

  Result := '';
end;

function TPascalParser.ExtractReturnType(const Declaration: string): string;
var
  L: string;
  ColonPos: Integer;
  SemiPos: Integer;
  AfterParen: string;
  ParenPos: Integer;
  ParenLevel: Integer;
  i: Integer;
begin
  L := StripComments(Declaration);
  L := StripStringLiterals(L);

  AfterParen := L;
  ParenPos := Pos('(', L);
  if ParenPos > 0 then
  begin
    ParenLevel := 1;
    i := ParenPos + 1;
    while i <= Length(L) do
    begin
      if L[i] = '(' then
        Inc(ParenLevel)
      else if L[i] = ')' then
      begin
        Dec(ParenLevel);
        if ParenLevel = 0 then
        begin
          AfterParen := Copy(L, i + 1, Length(L));
          Break;
        end;
      end;
      Inc(i);
    end;
  end;

  ColonPos := Pos(':', AfterParen);
  if ColonPos = 0 then
    Exit('');

  SemiPos := Pos(';', AfterParen, ColonPos + 1);
  if SemiPos = 0 then
    Result := Copy(AfterParen, ColonPos + 1, Length(AfterParen) - ColonPos)
  else
    Result := Copy(AfterParen, ColonPos + 1, SemiPos - ColonPos - 1);

  Result := Trim(Result);
end;

function TPascalParser.FindMethod(const MethodName: string): TPascalMethod;
var
  Method: TPascalMethod;
begin
  for Method in FCurrentUnit.Methods do
  begin
    if SameText(Method.FullName, MethodName) or
       SameText(Method.Name, MethodName) or
       SameText(Method.GetDisplayName, MethodName) then
      Exit(Method);
  end;
  Result := nil;
end;

function TPascalParser.FindMethodsByPattern(const Pattern: string): TList<TPascalMethod>;
var
  Method: TPascalMethod;
  Regex: TRegEx;
begin
  Result := TList<TPascalMethod>.Create;
  Regex := TRegEx.Create(Pattern, [roIgnoreCase]);

  for Method in FCurrentUnit.Methods do
  begin
    if Regex.IsMatch(Method.FullName) or
       Regex.IsMatch(Method.GetDisplayName) or
       Regex.IsMatch(Method.FullSignature) then
    begin
      Result.Add(Method);
    end;
  end;
end;

end.
