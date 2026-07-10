{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Advanced.WinAPI;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  System.RegularExpressions, System.StrUtils,
  Converter.Core.Types;

type
  TWinAPIConverter = class
  private
    FContext: TConversionContext;
    FAPIPatterns: TDictionary<string, string>;
    FPlatformIfdefs: TStringList;

    procedure InitializePatterns;
    function ConvertMessageAPI(const Line: string;
      Match: TMatch): string;
    function ConvertGDIAPI(const Line: string;
      Match: TMatch): string;
    function ConvertFileAPI(const Line: string;
      Match: TMatch): string;
    function ConvertRegistryAPI(const Line: string;
      Match: TMatch): string;
    function ConvertProcessAPI(const Line: string;
      Match: TMatch): string;
    function ConvertShellAPI(const Line: string;
      Match: TMatch): string;
  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    function ConvertWinAPICalls(const PascalCode: string): string;
    procedure AddPlatformConditionals(var PascalCode: TStringList);

    property PlatformIfdefs: TStringList read FPlatformIfdefs;
  end;

  TGraphicsConverter = class
  private
    FContext: TConversionContext;

    function ConvertColor(const VCLColor: string): string;
    function ConvertFont(const VCLFont: string): string;
    function IsValidColorConstant(const ConstName: string): Boolean;
    function FixPositioning(var Code: string): string;
    function FixScaling(var Code: string): string;
    function FixDivision(var Code: string): string;
    function FixProtectedAccess(var Code: string): string;
    function FixComponentPositioning(var Code: string): string;
    function RemoveVCLUnits(var Code: string): string;
  public
    constructor Create(AContext: TConversionContext);

    function ConvertGraphics(const PascalCode: string): string;
    function ConvertOnPaint(const MethodBody: TStringList): TStringList;
  end;

implementation

{ TWinAPIConverter }

constructor TWinAPIConverter.Create(AContext: TConversionContext);
begin
  FContext := AContext;
  FAPIPatterns := TDictionary<string, string>.Create;
  FPlatformIfdefs := TStringList.Create;

  InitializePatterns;
end;

destructor TWinAPIConverter.Destroy;
begin
  FAPIPatterns.Free;
  FPlatformIfdefs.Free;
  inherited;
end;

procedure TWinAPIConverter.InitializePatterns;
begin
  // Windows Messages
  FAPIPatterns.Add('SendMessage\s*\(', 'Message');
  FAPIPatterns.Add('PostMessage\s*\(', 'Message');
  FAPIPatterns.Add('DispatchMessage\s*\(', 'Message');
  FAPIPatterns.Add('PeekMessage\s*\(', 'Message');
  FAPIPatterns.Add('GetMessage\s*\(', 'Message');
  FAPIPatterns.Add('TranslateMessage\s*\(', 'Message');
  FAPIPatterns.Add('\.\s*Perform\s*\(', 'Message');

  // GDI Functions
  FAPIPatterns.Add('GetDC\s*\(', 'GDI');
  FAPIPatterns.Add('ReleaseDC\s*\(', 'GDI');
  FAPIPatterns.Add('BeginPaint\s*\(', 'GDI');
  FAPIPatterns.Add('EndPaint\s*\(', 'GDI');
  FAPIPatterns.Add('InvalidateRect\s*\(', 'GDI');
  FAPIPatterns.Add('UpdateWindow\s*\(', 'GDI');
  FAPIPatterns.Add('CreatePen\s*\(', 'GDI');
  FAPIPatterns.Add('CreateSolidBrush\s*\(', 'GDI');
  FAPIPatterns.Add('SelectObject\s*\(', 'GDI');
  FAPIPatterns.Add('DeleteObject\s*\(', 'GDI');
  FAPIPatterns.Add('GetStockObject\s*\(', 'GDI');
  FAPIPatterns.Add('SetBkMode\s*\(', 'GDI');
  FAPIPatterns.Add('SetTextColor\s*\(', 'GDI');

  // File Operations (Windows-specific)
  FAPIPatterns.Add('CreateFile\s*\(', 'File');
  FAPIPatterns.Add('ReadFile\s*\(', 'File');
  FAPIPatterns.Add('WriteFile\s*\(', 'File');
  FAPIPatterns.Add('GetFileSize\s*\(', 'File');
  FAPIPatterns.Add('SetFilePointer\s*\(', 'File');
  FAPIPatterns.Add('FindFirstFile\s*\(', 'File');
  FAPIPatterns.Add('FindNextFile\s*\(', 'File');

  // Registry
  FAPIPatterns.Add('RegOpenKeyEx\s*\(', 'Registry');
  FAPIPatterns.Add('RegCreateKeyEx\s*\(', 'Registry');
  FAPIPatterns.Add('RegQueryValueEx\s*\(', 'Registry');
  FAPIPatterns.Add('RegSetValueEx\s*\(', 'Registry');
  FAPIPatterns.Add('RegCloseKey\s*\(', 'Registry');
  FAPIPatterns.Add('RegDeleteKey\s*\(', 'Registry');

  // Process and Thread
  FAPIPatterns.Add('CreateProcess\s*\(', 'Process');
  FAPIPatterns.Add('OpenProcess\s*\(', 'Process');
  FAPIPatterns.Add('TerminateProcess\s*\(', 'Process');
  FAPIPatterns.Add('GetExitCodeProcess\s*\(', 'Process');
  FAPIPatterns.Add('CreateThread\s*\(', 'Thread');
  FAPIPatterns.Add('WaitForSingleObject\s*\(', 'Sync');

  // Shell
  FAPIPatterns.Add('ShellExecute\s*\(', 'Shell');
  FAPIPatterns.Add('SHGetFileInfo\s*\(', 'Shell');
  FAPIPatterns.Add('SHBrowseForFolder\s*\(', 'Shell');
end;

function TWinAPIConverter.ConvertWinAPICalls(const PascalCode: string): string;
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  I: Integer;
  Line: string;
  AnalysisLine: string;
  OriginalLine: string;
  TrimmedOriginalLine: string;
  Pattern: string;
  Category: string;
  Match: TMatch;
  Modified: Boolean;
  CommentContinuation: Boolean;
  CommentConditionalDepth: Integer;
  AwaitingConditionalBegin: Boolean;
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

  function IsRoutineDeclaration(const S: string): Boolean;
  begin
    Result := TRegEx.IsMatch(Trim(S),
      '^(class\s+)?(procedure|function|constructor|destructor)\b',
      [roIgnoreCase]);
  end;

  function IsCommentContinuationBoundary(const S: string): Boolean;
  var
    Trimmed: string;
  begin
    Trimmed := Trim(S);
    Result :=
      SameText(Trimmed, 'implementation') or
      SameText(Trimmed, 'initialization') or
      SameText(Trimmed, 'finalization') or
      SameText(Trimmed, 'end.') or
      IsRoutineDeclaration(Trimmed);
  end;

  function IsLikelyMessageAPICall(const S: string): Boolean;
  begin
    if IsRoutineDeclaration(S) then
      Exit(False);

    if TRegEx.IsMatch(S, '\b(SendMessage|PostMessage)\s*\(', [roIgnoreCase]) then
      Exit(TRegEx.IsMatch(S, '\b(WM_|CM_|CN_|EM_|LB_|CB_|LVM_|TVM_|TCM_|SB_|Handle\b|HWND\b)', [roIgnoreCase]));

    if TRegEx.IsMatch(S, '\.\s*Perform\s*\(', [roIgnoreCase]) then
      Exit(TRegEx.IsMatch(S, '\b(WM_|CM_|CN_|EM_|LB_|CB_|LVM_|TVM_|TCM_|SB_)', [roIgnoreCase]));

    Result := TRegEx.IsMatch(S,
      '\b(DispatchMessage|PeekMessage|GetMessage|TranslateMessage)\s*\(\s*(Msg|Message|TMsg\b|PMsg\b|@)',
      [roIgnoreCase]);
  end;
begin
  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  try
    Lines.Text := PascalCode;
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(PascalCode);
    CommentContinuation := False;
    CommentConditionalDepth := 0;
    AwaitingConditionalBegin := False;

    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];
      if I < AnalysisLines.Count then
        AnalysisLine := StripStringLiteralsForAnalysis(AnalysisLines[I])
      else
        AnalysisLine := StripStringLiteralsForAnalysis(Line);
      OriginalLine := Line;
      TrimmedOriginalLine := Trim(OriginalLine);
      Modified := False;

      if (Trim(AnalysisLine) = '') and not CommentContinuation then
        Continue;
      if CommentContinuation then
      begin
        if IsCommentContinuationBoundary(OriginalLine) then
        begin
          CommentContinuation := False;
          CommentConditionalDepth := 0;
          AwaitingConditionalBegin := False;
        end
        else
        begin
        if TrimmedOriginalLine <> '' then
          Line := '  // ' + TrimmedOriginalLine
        else
          Line := '  //';

        Lines[I] := Line;

        if AwaitingConditionalBegin then
        begin
          if SameText(TrimmedOriginalLine, 'begin') then
          begin
            CommentConditionalDepth := 1;
            AwaitingConditionalBegin := False;
          end
          else if Pos(';', OriginalLine) > 0 then
          begin
            CommentContinuation := False;
            AwaitingConditionalBegin := False;
          end;
        end
        else if CommentConditionalDepth > 0 then
        begin
          if SameText(TrimmedOriginalLine, 'begin') then
            Inc(CommentConditionalDepth)
          else if SameText(TrimmedOriginalLine, 'end;') or
                  SameText(TrimmedOriginalLine, 'end') then
          begin
            Dec(CommentConditionalDepth);
            if CommentConditionalDepth <= 0 then
            begin
              CommentConditionalDepth := 0;
              CommentContinuation := False;
            end;
          end;
        end
        else if Pos(';', OriginalLine) > 0 then
          CommentContinuation := False;

        Continue;
        end;
      end;

      for Pattern in FAPIPatterns.Keys do
      begin
        if TRegEx.IsMatch(AnalysisLine, Pattern, [roIgnoreCase]) then
        begin
          Category := FAPIPatterns[Pattern];
          if (Category = 'Message') and not IsLikelyMessageAPICall(AnalysisLine) then
            Continue;
          Match := TRegEx.Match(AnalysisLine, Pattern, [roIgnoreCase]);

          if Category = 'File' then
            Line := ConvertFileAPI(Line, Match)
          else if Category = 'Message' then
            Line := ConvertMessageAPI(Line, Match)
          else if Category = 'GDI' then
            Line := ConvertGDIAPI(Line, Match)
          else if Category = 'Registry' then
            Line := ConvertRegistryAPI(Line, Match)
          else if (Category = 'Process') or (Category = 'Thread') or (Category = 'Sync') then
            Line := ConvertProcessAPI(Line, Match)
          else if Category = 'Shell' then
            Line := ConvertShellAPI(Line, Match);

          Modified := True;
          FPlatformIfdefs.Add(Line);
          Break;
        end;
      end;

      if Modified then
      begin
        Lines[I] := Line;
        if (Pos('// Original:', Line) > 0) and (Pos(';', OriginalLine) = 0) then
        begin
          CommentContinuation := True;
          CommentConditionalDepth := 0;
          AwaitingConditionalBegin :=
            TRegEx.IsMatch(OriginalLine, '^\s*if\b', [roIgnoreCase]);
        end;
      end;
    end;

    Result := Lines.Text;
  finally
    AnalysisLines.Free;
    Lines.Free;
  end;
end;

function TWinAPIConverter.ConvertMessageAPI(const Line: string;
  Match: TMatch): string;
var
  APIName: string;
  WMConst: string;
  SCConst: string;
  WMMatch: TMatch;
  SCMatch: TMatch;
  Guidance: string;
  Detail: string;
  Indent: string;
  SafeRewrite: string;
  IsStandaloneCall: Boolean;

  function MessageGuidance(const AWMConst, ASCConst: string): string;
  begin
    if SameText(AWMConst, 'WM_SYSCOMMAND') then
    begin
      if SameText(ASCConst, 'SC_CLOSE') then
        Exit('For a form close request, use Close, ModalResult, or OnCloseQuery according to the original intent.')
      else if SameText(ASCConst, 'SC_MINIMIZE') then
        Exit('For minimize behavior, use the FMX form WindowState where supported, or platform-specific code when the target requires it.')
      else if SameText(ASCConst, 'SC_MAXIMIZE') then
        Exit('For maximize behavior, use the FMX form WindowState where supported, or platform-specific code when the target requires it.')
      else if SameText(ASCConst, 'SC_RESTORE') then
        Exit('For restore behavior, use the FMX form WindowState where supported, or platform-specific code when the target requires it.');

      Exit('WM_SYSCOMMAND has no single cross-platform FMX equivalent. Map the specific SC_* command to form state, close, or platform service logic.');
    end;

    if SameText(AWMConst, 'WM_VSCROLL') or SameText(AWMConst, 'WM_HSCROLL') then
      Exit('Replace scroll messages with the target FMX control''s viewport, scroll-box, caret, or item-index APIs.');

    if SameText(AWMConst, 'WM_CLOSE') then
      Exit('Use Close or OnCloseQuery rather than posting WM_CLOSE.');

    if StartsText('EM_', AWMConst) then
      Exit('Use FMX edit/memo text, selection, caret, and clipboard APIs instead of edit control messages.');

    if StartsText('LB_', AWMConst) or StartsText('CB_', AWMConst) then
      Exit('Use FMX list box or combo box item, selection, and data APIs instead of list/combo control messages.');

    if StartsText('LVM_', AWMConst) or StartsText('TVM_', AWMConst) or StartsText('TCM_', AWMConst) then
      Exit('Use FMX list view, tree view, tab control, or adapter APIs instead of common-control messages.');

    if StartsText('CN_', AWMConst) or StartsText('CM_', AWMConst) then
      Exit('Use FMX control events, notifications, and direct property changes instead of VCL control notifications.');

    if SameText(AWMConst, 'WM_MOVE') then
      Exit('Use FMX form position handling, such as OnPositionChanged or explicit Position.X/Y logic.');

    if SameText(AWMConst, 'WM_SIZE') then
      Exit('Use OnResize and FMX layout/alignment behavior instead of WM_SIZE.');

    if SameText(AWMConst, 'WM_SETFOCUS') or SameText(AWMConst, 'WM_KILLFOCUS') then
      Exit('Use FMX focus events such as OnEnter and OnExit.');

    if SameText(AWMConst, 'WM_KEYDOWN') or SameText(AWMConst, 'WM_KEYUP') or
       SameText(AWMConst, 'WM_CHAR') then
      Exit('Use FMX keyboard events such as OnKeyDown, OnKeyUp, and text-input handling.');

    if SameText(AWMConst, 'WM_USER') or ContainsText(AWMConst, 'WM_USER') then
      Exit('Use System.Messaging with a typed TMessage descendant for custom application messages.');

    Result := 'Use FMX events, direct method calls, System.Messaging, or platform-specific code according to the message intent.';
  end;

  function TryBuildSafeSystemCommandRewrite(out ARewrite: string): Boolean;
  begin
    Result := False;
    ARewrite := '';

    if not SameText(WMConst, 'WM_SYSCOMMAND') then
      Exit;

    if not IsStandaloneCall then
      Exit;

    if not SameText(SCConst, 'SC_CLOSE') then
      Exit;

    ARewrite := Indent + 'Close;';
    Result := True;
  end;
begin
  APIName := Trim(Match.Value);

  // Extract WM_ and SC_ constants if present.
  WMConst := '';
  WMMatch := TRegEx.Match(Line, '\b(?:WM_|CM_|CN_|EM_|LB_|CB_|LVM_|TVM_|TCM_)\w+', [roIgnoreCase]);
  if WMMatch.Success then
    WMConst := WMMatch.Value;

  SCConst := '';
  SCMatch := TRegEx.Match(Line, '\bSC_\w+', [roIgnoreCase]);
  if SCMatch.Success then
    SCConst := SCMatch.Value;

  Guidance := MessageGuidance(WMConst, SCConst);
  Detail := Trim(WMConst);
  if Trim(SCConst) <> '' then
    Detail := Trim(Detail + ' / ' + SCConst);
  if Detail = '' then
    Detail := 'Windows message API';

  Indent := TRegEx.Match(Line, '^\s*').Value;
  IsStandaloneCall := TRegEx.IsMatch(Line,
    '^\s*(SendMessage|PostMessage)\s*\(.*\)\s*;?\s*(//.*)?$',
    [roIgnoreCase]);

  if TryBuildSafeSystemCommandRewrite(SafeRewrite) then
  begin
    Result := SafeRewrite;
    FContext.AddIssue(csInfo,
      'Windows system command converted automatically: ' + Detail + '.',
      'Windows messaging',
      Trim(Line),
      Guidance,
      -1, False);
    Exit;
  end;

  if ContainsText(APIName, 'SendMessage') then
  begin
    if WMConst <> '' then
    begin
      if ContainsText(WMConst, 'WM_USER') then
        Result :=
          '  { FMX: Replace with TMessageManager - SendMessage removed }' + sLineBreak +
          '  { Original: ' + Trim(Line) + ' }' + sLineBreak +
          '  { TMessageManager.DefaultManager.SendMessage(Self, TMyMsg.Create(lParam)); }'
      else
        Result :=
          '  { FMX: ' + Detail + ' - ' + Guidance + ' }' + sLineBreak +
          '  { Original: ' + Trim(Line) + ' }';
    end
    else
    begin
      Result :=
        '  { FMX: Use property setter or direct method call instead of SendMessage }' + sLineBreak +
        '  { Original: ' + Trim(Line) + ' }';
    end;
  end
  else if ContainsText(APIName, 'PostMessage') then
  begin
    if WMConst <> '' then
      Result :=
        '  { FMX: ' + Detail + ' - ' + Guidance + ' }' + sLineBreak +
        '  { FMX: Preserve async behavior with TThread.Queue only if the original timing matters. }' + sLineBreak +
        '  { Original: ' + Trim(Line) + ' }' + sLineBreak +
        '  { TThread.Queue(nil, procedure begin TMessageManager.DefaultManager.SendMessage(Self, TMyMsg.Create(lParam)); end); }'
    else
      Result :=
        '  { FMX: Use TMessageManager.DefaultManager.SendMessage for async dispatch }' + sLineBreak +
        '  { Original: ' + Trim(Line) + ' }';
  end
  else if ContainsText(APIName, 'PeekMessage') or ContainsText(APIName, 'GetMessage') or
          ContainsText(APIName, 'TranslateMessage') or ContainsText(APIName, 'DispatchMessage') then
  begin
    Result :=
      '  { FMX: Message pump calls not needed - FMX has its own event loop }' + sLineBreak +
      '  { Original: ' + Trim(Line) + ' }';
  end
  else
  begin
    if WMConst <> '' then
      Result :=
        '  { FMX: ' + Detail + ' - ' + Guidance + ' }' + sLineBreak +
        '  { Original: ' + Trim(Line) + ' }'
    else
      Result :=
        '  { FMX: Use TMessageManager for cross-platform messaging }' + sLineBreak +
        '  { Original: ' + Trim(Line) + ' }';
  end;

  FContext.AddIssue(csManualReview,
    'Windows message API replaced - review ' + Detail + ' intent in generated code.',
    'Windows messaging',
    Trim(Line),
    Guidance,
    -1, False);
end;
function TWinAPIConverter.ConvertGDIAPI(const Line: string;
  Match: TMatch): string;
var
  APIName: string;
  Indent: string;
  IsStandaloneCall: Boolean;
begin
  APIName := Match.Value;
  Indent := TRegEx.Match(Line, '^\s*').Value;
  IsStandaloneCall := TRegEx.IsMatch(Line,
    '^\s*\w+\s*\(.*\)\s*;?\s*(//.*)?$',
    [roIgnoreCase]);

  // If a previous pass already produced FMX canvas code, keep it untouched.
  if TRegEx.IsMatch(Line,
    '\b(Canvas\.(BeginScene|EndScene|FillText|DrawLine|DrawRect|FillRect|DrawEllipse|FillEllipse)|TAlphaColor|TAlphaColorRec)\b',
    [roIgnoreCase]) then
  begin
    Result := Line;
    Exit;
  end;

  if APIName.Contains('InvalidateRect') and IsStandaloneCall then
  begin
    Result := Indent + 'Repaint;';
    FContext.AddIssue(csInfo,
      'GDI invalidation call converted automatically to FMX Repaint.');
    Exit;
  end;

  if APIName.Contains('UpdateWindow') and IsStandaloneCall then
  begin
    Result := Indent + 'Repaint;';
    FContext.AddIssue(csInfo,
      'GDI UpdateWindow call converted automatically to FMX Repaint.');
    Exit;
  end;

  if APIName.Contains('GetDC') or APIName.Contains('BeginPaint') then
  begin
    Result := '  // FMX manual review: move this drawing code to an FMX OnPaint handler that uses the Canvas parameter' + #13#10 +
              '  // Original: ' + Line.Trim();
  end
  else if APIName.Contains('ReleaseDC') or APIName.Contains('EndPaint') then
  begin
    Result := '  // FMX manual review: remove this paired Windows paint/DC cleanup after moving drawing to FMX OnPaint' + #13#10 +
              '  // Original: ' + Line.Trim();
  end
  else if APIName.Contains('CreatePen') or APIName.Contains('CreateSolidBrush') or
          APIName.Contains('SelectObject') or APIName.Contains('DeleteObject') or
          APIName.Contains('GetStockObject') then
  begin
    Result := '  // FMX manual review: replace GDI pen/brush/object code with Canvas.Stroke and Canvas.Fill settings' + #13#10 +
              '  // Original: ' + Line.Trim();
  end
  else if APIName.Contains('SetBkMode') then
  begin
    Result := '  // FMX manual review: replace SetBkMode with FMX text/fill drawing choices in Canvas.FillText' + #13#10 +
              '  // Original: ' + Line.Trim();
  end
  else if APIName.Contains('SetTextColor') then
  begin
    Result := '  // FMX manual review: replace SetTextColor with Canvas.Fill.Color before Canvas.FillText' + #13#10 +
              '  // Original: ' + Line.Trim();
  end
  else
    Result := '  // FMX manual review: replace remaining GDI call with FMX Canvas or platform-specific drawing code' + #13#10 +
              '  // Original: ' + Line.Trim();

  FContext.AddIssue(csManualReview,
    'GDI drawing API requires manual FMX Canvas conversion.',
    'Graphics or GDI usage',
    Trim(Line),
    'Move drawing into an FMX OnPaint handler and use Canvas.Stroke, Canvas.Fill, DrawLine, DrawRect, FillRect, and FillText as appropriate.',
    -1, False);
end;
function TWinAPIConverter.ConvertFileAPI(const Line: string;
  Match: TMatch): string;
var
  APIName: string;
  IsSerialCreateFile: Boolean;
  IsNamedPipeCreateFile: Boolean;
begin
  APIName := Match.Value;
  IsSerialCreateFile :=
    APIName.Contains('CreateFile') and
    (ContainsText(Line, '\\.\') or
     TRegEx.IsMatch(Line, '\b(?:ComPort|CommPort|PortPath|SerialPort|SerialHandle|GpsPort|GPSPort)\b', [roIgnoreCase]));
  IsNamedPipeCreateFile :=
    APIName.Contains('CreateFile') and
    (ContainsText(Line, '\pipe\') or
     TRegEx.IsMatch(Line, '\b(?:PipeName|NamedPipe|PipeHandle|ToPipe|FromPipe|ReadPipe|WritePipe)\b', [roIgnoreCase]));

  // Preserve common Windows stream/pipe reads for Windows-targeted FMX apps.
  if APIName.Contains('ReadFile') then
  begin
    Result := Line;
    FContext.AddIssue(csInfo,
      'Windows ReadFile call preserved for Windows FMX output');
    Exit;
  end;

  if APIName.Contains('WriteFile') then
  begin
    Result := Line;
    FContext.AddIssue(csInfo,
      'Windows WriteFile call preserved for Windows FMX output');
    Exit;
  end;

  if IsSerialCreateFile then
  begin
    Result := Line;
    FContext.AddIssue(csInfo,
      'Windows serial-port CreateFile call preserved for Windows FMX output');
    Exit;
  end;

  if IsNamedPipeCreateFile then
  begin
    Result := Line;
    FContext.AddIssue(csInfo,
      'Windows named-pipe CreateFile call preserved for Windows FMX output');
    Exit;
  end;

  Result := '  // FMX: Use TFile, TStream, or TPath from System.IOUtils after manual review' + #13#10 +
            '  // Original: ' + Line.Trim();

  FContext.AddIssue(csInfo, 'Windows file API downgraded to manual review');
end;

function TWinAPIConverter.ConvertRegistryAPI(const Line: string;
  Match: TMatch): string;
begin
  Result := '  // FMX: Use TPlatformServices for cross-platform settings' + #13#10 +
            '  // Original: ' + Line.Trim() + #13#10 +
            '  {$IFDEF MSWINDOWS}' + #13#10 +
            '  // Windows-specific registry code' + #13#10 +
            '  {$ELSE}' + #13#10 +
            '  // Use cross-platform preferences API' + #13#10 +
            '  {$ENDIF}';

  FContext.AddIssue(csInfo, 'Registry access wrapped in platform conditionals');
end;

function TWinAPIConverter.ConvertProcessAPI(const Line: string;
  Match: TMatch): string;
var
  APIName: string;
begin
  APIName := Match.Value;

  // Preserve common Windows process execution and wait calls for
  // Windows-targeted FMX utilities that intentionally shell out.
  if APIName.Contains('CreateProcess') or
     APIName.Contains('WaitForSingleObject') or
     APIName.Contains('TerminateProcess') or
     APIName.Contains('GetExitCodeProcess') then
  begin
    Result := Line;
    FContext.AddIssue(csInfo,
      'Windows process/sync call preserved for Windows FMX output');
    Exit;
  end;

  Result := '  // FMX: Use TTask, TThread, or platform services after manual review' + #13#10 +
            '  // Original: ' + Line.Trim();
  FContext.AddIssue(csInfo,
    'Windows process/thread API downgraded to manual review');
end;

function TWinAPIConverter.ConvertShellAPI(const Line: string;
  Match: TMatch): string;
begin
  if Line.Contains('ShellExecute') then
  begin
    Result := Line;
    FContext.AddIssue(csInfo,
      'Windows shell launch preserved for Windows FMX output');
    Exit;
  end
  else
    Result := '  // FMX: Use cross-platform shell APIs' + #13#10 +
              '  // Original: ' + Line.Trim();

  FContext.AddIssue(csInfo, 'Shell API - verify cross-platform behavior');
end;

procedure TWinAPIConverter.AddPlatformConditionals(var PascalCode: TStringList);
var
  I: Integer;
  BlockStart: Integer;
  BlockEnd: Integer;

  function IsWinAPIReviewStartLine(const S: string): Boolean;
  var
    Trimmed: string;
  begin
    Trimmed := Trim(S);
    Result := Trimmed.StartsWith('// FMX:') and
      (ContainsText(Trimmed, 'Windows') or ContainsText(Trimmed, 'Registry'));
  end;

  function IsReviewCommentLine(const S: string): Boolean;
  var
    Trimmed: string;
  begin
    Trimmed := Trim(S);
    Result := Trimmed.StartsWith('// Original:') or
      (Trimmed.StartsWith('// FMX:') and
       (ContainsText(Trimmed, 'Windows') or ContainsText(Trimmed, 'Registry') or
        ContainsText(Trimmed, 'Original')));
  end;
begin
  I := 0;

  while I < PascalCode.Count do
  begin
    if IsWinAPIReviewStartLine(PascalCode[I]) then
    begin
      BlockStart := I;
      BlockEnd := I;
      while (BlockEnd + 1 < PascalCode.Count) and
            IsReviewCommentLine(PascalCode[BlockEnd + 1]) do
        Inc(BlockEnd);

      PascalCode.Insert(BlockStart, '{$IFDEF MSWINDOWS}');
      PascalCode.Insert(BlockEnd + 2, '{$ENDIF}');
      I := BlockEnd + 3;
      Continue;
    end;

    Inc(I);
  end;
end;

{ TGraphicsConverter }

constructor TGraphicsConverter.Create(AContext: TConversionContext);
begin
  FContext := AContext;
end;

function TGraphicsConverter.RemoveVCLUnits(var Code: string): string;
begin
  // Uses clauses are normalized later by the structure-aware uses rewriter.
  // A whole-file regex here would also remove unit names from comments.
  Result := Code;
end;

function TGraphicsConverter.IsValidColorConstant(const ConstName: string): Boolean;
var
  I: Integer;
  KnownColors: array[0..39] of string;
begin
  KnownColors[0] := 'clBlack';
  KnownColors[1] := 'clWhite';
  KnownColors[2] := 'clRed';
  KnownColors[3] := 'clGreen';
  KnownColors[4] := 'clBlue';
  KnownColors[5] := 'clYellow';
  KnownColors[6] := 'clBtnFace';
  KnownColors[7] := 'clWindow';
  KnownColors[8] := 'clHighlight';
  KnownColors[9] := 'clIvory';
  KnownColors[10] := 'clCream';
  KnownColors[11] := 'clMaroon';
  KnownColors[12] := 'clNavy';
  KnownColors[13] := 'clTeal';
  KnownColors[14] := 'clOlive';
  KnownColors[15] := 'clPurple';
  KnownColors[16] := 'clSilver';
  KnownColors[17] := 'clGray';
  KnownColors[18] := 'clFuchsia';
  KnownColors[19] := 'clLime';
  KnownColors[20] := 'clAqua';
  KnownColors[21] := 'clSkyBlue';
  KnownColors[22] := 'clCoral';
  KnownColors[23] := 'clGold';
  KnownColors[24] := 'clLavender';
  KnownColors[25] := 'clMintCream';
  KnownColors[26] := 'clPeachPuff';
  KnownColors[27] := 'clPlum';
  KnownColors[28] := 'clSalmon';
  KnownColors[29] := 'clSeaGreen';
  KnownColors[30] := 'clViolet';
  KnownColors[31] := 'clWheat';
  KnownColors[32] := 'clBeige';
  KnownColors[33] := 'clMint';
  KnownColors[34] := 'clPeach';
  KnownColors[35] := 'clBackground';
  KnownColors[36] := 'clActiveCaption';
  KnownColors[37] := 'clInactiveCaption';
  KnownColors[38] := 'clInfoBk';
  KnownColors[39] := 'clNone';

  Result := False;
  for I := 0 to 39 do
  begin
    if SameText(KnownColors[I], ConstName) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TGraphicsConverter.FixComponentPositioning(var Code: string): string;
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  i: Integer;
  Line: string;
begin
  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  try
    Lines.Text := Code;
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Code);

    for i := 0 to Lines.Count - 1 do
    begin
      if (i < AnalysisLines.Count) and (Trim(AnalysisLines[i]) = '') then
        Continue;
      Line := Lines[i];

      Line := StringReplace(Line, 'AForm.Position.X', 'AForm.Left', [rfReplaceAll]);
      Line := StringReplace(Line, 'AForm.Position.Y', 'AForm.Top', [rfReplaceAll]);

      // Fix AForm.Left assignments
      if (Pos('aform.left', LowerCase(Line)) > 0) and (Pos(':=', Line) > 0) then
      begin
        if ContainsText(Line, 'div') then
          Line := TRegEx.Replace(Line, '\bdiv\b', '/', [roIgnoreCase]);
      end;

      // Keep FMX form centering on Left/Top and normalize division.
      if TRegEx.IsMatch(Line, '\bAForm\.(Left|Top)\b', [roIgnoreCase]) and
         ContainsText(Line, 'div') then
      begin
        Line := TRegEx.Replace(Line, '\bdiv\b', '/', [roIgnoreCase]);
      end;

      // Fix Width/Height property case
      Line := StringReplace(Line, '.width', '.Width', [rfReplaceAll]);
      Line := StringReplace(Line, '.height', '.Height', [rfReplaceAll]);

      Lines[i] := Line;
    end;

    Result := Lines.Text;
  finally
    AnalysisLines.Free;
    Lines.Free;
  end;
end;

function TGraphicsConverter.FixProtectedAccess(var Code: string): string;
var
  Lines: TStringList;
  i: Integer;
  Line: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := Code;

    for i := 0 to Lines.Count - 1 do
    begin
      Line := Lines[i];

      Lines[i] := Line;
    end;

    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function TGraphicsConverter.FixDivision(var Code: string): string;
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  i: Integer;
  Line: string;
  EqPos: Integer;
  RightSide: string;
  IsFloatAssignment: Boolean;
  HasFloatOperand: Boolean;
begin
  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  try
    Lines.Text := Code;
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Code);

    for i := 0 to Lines.Count - 1 do
    begin
      if (i < AnalysisLines.Count) and (Trim(AnalysisLines[i]) = '') then
        Continue;
      Line := Lines[i];

      IsFloatAssignment := TRegEx.IsMatch(Line,
        '(\bPosition\.(X|Y)|\.(Left|Top|Width|Height)|\bFont\.Size)\s*:=',
        [roIgnoreCase]);

      if IsFloatAssignment then
      begin
        HasFloatOperand :=
          TRegEx.IsMatch(Line,
            '(?:Screen\.(?:Width|Height|WorkAreaWidth|WorkAreaHeight)|' +
            '[A-Za-z_][A-Za-z0-9_\.]*\.(?:Width|Height|Left|Top|Size|Value|Opacity))',
            [roIgnoreCase]) or
          TRegEx.IsMatch(Line,
            '[A-Za-z_][A-Za-z0-9_\.]*\.Position\.(?:X|Y)\b',
            [roIgnoreCase]);

        if HasFloatOperand and ContainsText(Line, 'div') then
        begin
          Line := TRegEx.Replace(Line, '\bdiv\b', '/', [roIgnoreCase]);
        end;

        EqPos := Pos(':=', Line);
        if EqPos > 0 then
        begin
          RightSide := Trim(Copy(Line, EqPos + 2, Length(Line)));
          var IsInteger := True;
          for var j := 1 to Length(RightSide) do
          begin
            if not CharInSet(RightSide[j], ['0'..'9']) then
            begin
              IsInteger := False;
              Break;
            end;
          end;
          if IsInteger then
            Line := Copy(Line, 1, EqPos + 1) + ' ' + RightSide + '.0';
        end;
      end;

      Lines[i] := Line;
    end;

    Result := Lines.Text;
  finally
    AnalysisLines.Free;
    Lines.Free;
  end;
end;

function TGraphicsConverter.FixPositioning(var Code: string): string;
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  i: Integer;
  Line: string;
begin
  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  try
    Lines.Text := Code;
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Code);

    for i := 0 to Lines.Count - 1 do
    begin
      if (i < AnalysisLines.Count) and (Trim(AnalysisLines[i]) = '') then
        Continue;
      Line := Lines[i];

      Line := StringReplace(Line, 'AForm.Position.X :=', 'AForm.Left :=', [rfReplaceAll]);
      Line := StringReplace(Line, 'AForm.Position.Y :=', 'AForm.Top :=', [rfReplaceAll]);

      if Pos('Color :=', Line) > 0 then
      begin
        Line := StringReplace(Line, 'TColor(', 'TAlphaColor(', [rfReplaceAll]);
      end;

      Lines[i] := Line;
    end;

    Result := Lines.Text;
  finally
    AnalysisLines.Free;
    Lines.Free;
  end;
end;

function TGraphicsConverter.FixScaling(var Code: string): string;
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  i: Integer;
  Line: string;
  Match: TMatch;
  InsertIdx: Integer;
  HelperNeeded: Boolean;

  procedure EnsureScaleByHelper;
  var
    J: Integer;
  begin
    if not HelperNeeded then
      Exit;

    if ContainsText(Lines.Text, 'procedure GeneratedFMXScaleBy(') then
      Exit;

    InsertIdx := -1;
    for J := 0 to Lines.Count - 1 do
    begin
      if SameText(Trim(Lines[J]), 'implementation') then
      begin
        InsertIdx := J + 1;
        Break;
      end;
    end;

    if InsertIdx < 0 then
      Exit;

    while (InsertIdx < Lines.Count) and (Trim(Lines[InsertIdx]) = '') do
      Inc(InsertIdx);

    if (InsertIdx < Lines.Count) and
       TRegEx.IsMatch(Trim(Lines[InsertIdx]), '^uses\b', [roIgnoreCase]) then
    begin
      while (InsertIdx < Lines.Count) and (Pos(';', Lines[InsertIdx]) = 0) do
        Inc(InsertIdx);
      if InsertIdx < Lines.Count then
        Inc(InsertIdx);
    end;

    Lines.Insert(InsertIdx, '');
    Lines.Insert(InsertIdx + 1, 'procedure GeneratedFMXScaleBy(const AForm: TForm; const ANumerator, ADenominator: Single);');
    Lines.Insert(InsertIdx + 2, 'var');
    Lines.Insert(InsertIdx + 3, '  LScale: Single;');
    Lines.Insert(InsertIdx + 4, 'begin');
    Lines.Insert(InsertIdx + 5, '  if (AForm = nil) or (Abs(ADenominator) < 0.0001) then');
    Lines.Insert(InsertIdx + 6, '    Exit;');
    Lines.Insert(InsertIdx + 7, '');
    Lines.Insert(InsertIdx + 8, '  LScale := ANumerator / ADenominator;');
    Lines.Insert(InsertIdx + 9, '  AForm.Width := AForm.Width * LScale;');
    Lines.Insert(InsertIdx + 10, '  AForm.Height := AForm.Height * LScale;');
    Lines.Insert(InsertIdx + 11, 'end;');
    Lines.Insert(InsertIdx + 12, '');
  end;
begin
  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  try
    Lines.Text := Code;
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(Code);
    HelperNeeded := False;

    for i := 0 to Lines.Count - 1 do
    begin
      if (i < AnalysisLines.Count) and (Trim(AnalysisLines[i]) = '') then
        Continue;
      Line := Lines[i];

      Match := TRegEx.Match(Line,
        '^(\s*)([A-Za-z_][A-Za-z0-9_\.]*)\.ScaleBy\s*\(\s*(.*?)\s*,\s*(.*?)\s*\)\s*;\s*(//.*)?$',
        [roIgnoreCase]);
      if Match.Success then
      begin
        Line := Match.Groups[1].Value + 'GeneratedFMXScaleBy(' +
          Match.Groups[2].Value + ', ' +
          Match.Groups[3].Value + ', ' +
          Match.Groups[4].Value + ');';
        HelperNeeded := True;
      end;

      Lines[i] := Line;
    end;

    EnsureScaleByHelper;
    Result := Lines.Text;
  finally
    AnalysisLines.Free;
    Lines.Free;
  end;
end;
function TGraphicsConverter.ConvertGraphics(const PascalCode: string): string;
var
  Lines: TStringList;
  AnalysisLines: TStringList;
  I, J: Integer;
  Line: string;
  Words: TArray<string>;
  W: string;
begin
  Lines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  try
    Lines.Text := PascalCode;
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(PascalCode);

    for I := 0 to Lines.Count - 1 do
    begin
      if (I < AnalysisLines.Count) and (Trim(AnalysisLines[I]) = '') then
        Continue;

      Line := Lines[I];
      if Pos('cl', Line) > 0 then
      begin
        Words := Line.Split([' ', ':', '=', ',', ';', '.', '(', ')', '[', ']', '+', '-']);
        for J := 0 to High(Words) do
        begin
          W := Trim(Words[J]);
          if W.StartsWith('cl', True) and (Length(W) > 2) and
             IsValidColorConstant(W) then
            Line := StringReplace(Line, W, ConvertColor(W),
              [rfReplaceAll, rfIgnoreCase]);
        end;
      end;

      if Pos('Font.', Line) > 0 then
        Line := ConvertFont(Line);

      Lines[I] := Line;
    end;

    Result := Lines.Text;
    Result := RemoveVCLUnits(Result);
    Result := FixComponentPositioning(Result);
    Result := FixPositioning(Result);
    Result := FixProtectedAccess(Result);
    Result := FixDivision(Result);
    Result := FixScaling(Result);
  finally
    AnalysisLines.Free;
    Lines.Free;
  end;
end;
function TGraphicsConverter.ConvertColor(const VCLColor: string): string;
var
  ColorConst: string;
  StartPos, EndPos: Integer;
  TempResult: string;
  RawValue: Cardinal;
  R, G, B: Cardinal;
  IntValue: Integer;
begin
  Result := VCLColor;

  if TryStrToInt(Trim(Result), IntValue) then
  begin
    RawValue := Cardinal(IntValue);
    B := RawValue and $FF;
    G := (RawValue shr 8) and $FF;
    R := (RawValue shr 16) and $FF;
    Exit(Format('$FF%.2X%.2X%.2X', [R, G, B]));
  end;

  StartPos := Pos('$', Result);
  if StartPos > 0 then
  begin
    try
      EndPos := StartPos + 1;
      while (EndPos <= Length(Result)) and
            CharInSet(UpCase(Result[EndPos]), ['0'..'9', 'A'..'F']) do
        Inc(EndPos);

      RawValue := StrToInt(Copy(Result, StartPos, EndPos - StartPos));
      if RawValue <= $FFFFFF then
      begin
        B := RawValue and $FF;
        G := (RawValue shr 8) and $FF;
        R := (RawValue shr 16) and $FF;
        Result := StringReplace(Result,
          Copy(Result, StartPos, EndPos - StartPos),
          Format('$FF%.2X%.2X%.2X', [R, G, B]),
          []);
      end;
      Exit;
    except
      // Fall back to named color handling below.
    end;
  end;

  StartPos := Pos('cl', Result);
  if StartPos > 0 then
  begin
    EndPos := StartPos + 2;
    while (EndPos <= Length(Result)) and
          CharInSet(Result[EndPos], ['a'..'z', 'A'..'Z']) do
      Inc(EndPos);
    ColorConst := Copy(Result, StartPos, EndPos - StartPos);

    if IsValidColorConstant(ColorConst) then
    begin
      TempResult := Result;

      if ColorConst = 'clBlack' then
        TempResult := StringReplace(TempResult, ColorConst, 'claBlack', [rfReplaceAll])
      else if ColorConst = 'clWhite' then
        TempResult := StringReplace(TempResult, ColorConst, 'claWhite', [rfReplaceAll])
      else if ColorConst = 'clRed' then
        TempResult := StringReplace(TempResult, ColorConst, 'claRed', [rfReplaceAll])
      else if ColorConst = 'clGreen' then
        TempResult := StringReplace(TempResult, ColorConst, 'claGreen', [rfReplaceAll])
      else if ColorConst = 'clBlue' then
        TempResult := StringReplace(TempResult, ColorConst, 'claBlue', [rfReplaceAll])
      else if ColorConst = 'clYellow' then
        TempResult := StringReplace(TempResult, ColorConst, 'claYellow', [rfReplaceAll])
      else if ColorConst = 'clBtnFace' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFF0F0F0', [rfReplaceAll])
      else if ColorConst = 'clWindow' then
        TempResult := StringReplace(TempResult, ColorConst, 'claWhite', [rfReplaceAll])
      else if ColorConst = 'clHighlight' then
        TempResult := StringReplace(TempResult, ColorConst, '$FF0078D7', [rfReplaceAll])
      else if ColorConst = 'clIvory' then
        TempResult := StringReplace(TempResult, ColorConst, 'claIvory', [rfReplaceAll])
      else if ColorConst = 'clCream' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFFFFBF0', [rfReplaceAll])
      else if ColorConst = 'clMaroon' then
        TempResult := StringReplace(TempResult, ColorConst, 'claMaroon', [rfReplaceAll])
      else if ColorConst = 'clNavy' then
        TempResult := StringReplace(TempResult, ColorConst, 'claNavy', [rfReplaceAll])
      else if ColorConst = 'clTeal' then
        TempResult := StringReplace(TempResult, ColorConst, 'claTeal', [rfReplaceAll])
      else if ColorConst = 'clOlive' then
        TempResult := StringReplace(TempResult, ColorConst, 'claOlive', [rfReplaceAll])
      else if ColorConst = 'clPurple' then
        TempResult := StringReplace(TempResult, ColorConst, 'claPurple', [rfReplaceAll])
      else if ColorConst = 'clSilver' then
        TempResult := StringReplace(TempResult, ColorConst, 'claSilver', [rfReplaceAll])
      else if ColorConst = 'clGray' then
        TempResult := StringReplace(TempResult, ColorConst, 'claGray', [rfReplaceAll])
      else if ColorConst = 'clMoneyGreen' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFC0DCC0', [rfReplaceAll])
      else if ColorConst = 'clFuchsia' then
        TempResult := StringReplace(TempResult, ColorConst, 'claFuchsia', [rfReplaceAll])
      else if ColorConst = 'clLime' then
        TempResult := StringReplace(TempResult, ColorConst, 'claLime', [rfReplaceAll])
      else if ColorConst = 'clAqua' then
        TempResult := StringReplace(TempResult, ColorConst, 'claAqua', [rfReplaceAll])
      else if ColorConst = 'clSkyBlue' then
        TempResult := StringReplace(TempResult, ColorConst, '$FF87CEEB', [rfReplaceAll])
      else if ColorConst = 'clCoral' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFFF7F50', [rfReplaceAll])
      else if ColorConst = 'clGold' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFFFD700', [rfReplaceAll])
      else if ColorConst = 'clLavender' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFE6E6FA', [rfReplaceAll])
      else if ColorConst = 'clMintCream' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFF5FFFA', [rfReplaceAll])
      else if ColorConst = 'clPeachPuff' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFFFDAB9', [rfReplaceAll])
      else if ColorConst = 'clPlum' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFDDA0DD', [rfReplaceAll])
      else if ColorConst = 'clSalmon' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFFA8072', [rfReplaceAll])
      else if ColorConst = 'clSeaGreen' then
        TempResult := StringReplace(TempResult, ColorConst, '$FF2E8B57', [rfReplaceAll])
      else if ColorConst = 'clViolet' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFEE82EE', [rfReplaceAll])
      else if ColorConst = 'clWheat' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFF5DEB3', [rfReplaceAll])
      else if ColorConst = 'clBeige' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFF5F5DC', [rfReplaceAll])
      else if ColorConst = 'clMint' then
        TempResult := StringReplace(TempResult, ColorConst, '$FF98FB98', [rfReplaceAll])
      else if ColorConst = 'clPeach' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFFFDAB9', [rfReplaceAll])
      else if ColorConst = 'clBackground' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFFFFFFF', [rfReplaceAll])
      else if ColorConst = 'clActiveCaption' then
      begin
        TempResult := StringReplace(TempResult, ColorConst,
          '$FF0078D7', [rfReplaceAll]);
        FContext.AddIssue(csManualReview,
          'Theme-dependent VCL color clActiveCaption used; generated fallback color requires review.');
      end
      else if ColorConst = 'clInactiveCaption' then
      begin
        TempResult := StringReplace(TempResult, ColorConst,
          '$FFF0F0F0', [rfReplaceAll]);
        FContext.AddIssue(csManualReview,
          'Theme-dependent VCL color clInactiveCaption used; generated fallback color requires review.');
      end
      else if ColorConst = 'clInfoBk' then
        TempResult := StringReplace(TempResult, ColorConst, '$FFE1FFFF', [rfReplaceAll])
      else if ColorConst = 'clNone' then
        TempResult := StringReplace(TempResult, ColorConst, '$0', [rfReplaceAll])
      else
      begin
        FContext.AddIssue(csManualReview,
          'Unknown VCL color constant preserved for manual review: ' + ColorConst);
      end;

      if TempResult <> Result then
        Result := TempResult;
    end;
  end;
end;

function TGraphicsConverter.ConvertFont(const VCLFont: string): string;
begin
  Result := VCLFont;

  if Pos('Font.Name', Result) > 0 then
    Result := StringReplace(Result, 'Font.Name', 'Font.Family', [rfReplaceAll]);

  if Pos('Font.Size', Result) > 0 then
    Result := StringReplace(Result, 'Font.Size', 'Font.Size', [rfReplaceAll]);

  if Pos('Font.Style', Result) > 0 then
  begin
    Result := StringReplace(Result, 'Font.Style', 'Font.Style', [rfReplaceAll]);
    if Pos('fsBold', Result) > 0 then
      Result := StringReplace(Result, 'fsBold', 'TFontStyle.fsBold', [rfReplaceAll]);
    if Pos('fsItalic', Result) > 0 then
      Result := StringReplace(Result, 'fsItalic', 'TFontStyle.fsItalic', [rfReplaceAll]);
    if Pos('fsUnderline', Result) > 0 then
      Result := StringReplace(Result, 'fsUnderline', 'TFontStyle.fsUnderline', [rfReplaceAll]);
  end;

  if Pos('Font.Color', Result) > 0 then
    Result := StringReplace(Result, 'Font.Color', 'Font.Color', [rfReplaceAll]);
end;

function TGraphicsConverter.ConvertOnPaint(const MethodBody: TStringList): TStringList;
var
  I: Integer;
  Line: string;
  InCanvas: Boolean;
  Op: string;
begin
  Result := TStringList.Create;
  InCanvas := False;

  for I := 0 to MethodBody.Count - 1 do
  begin
    Line := MethodBody[I];

    if Pos('Canvas.', Line) > 0 then
    begin
      if not InCanvas then
      begin
        Result.Add('  // Converted VCL Canvas operations to FMX');
        Result.Add('  with Canvas do');
        Result.Add('  begin');
        InCanvas := True;
      end;

      Op := Copy(Line, Pos('Canvas.', Line) + 7, Length(Line));

      if Pos('Rectangle', Op) > 0 then
        Op := StringReplace(Op, 'Rectangle', 'DrawRect(', [rfReplaceAll])
      else if Pos('Ellipse', Op) > 0 then
        Op := StringReplace(Op, 'Ellipse', 'DrawEllipse(', [rfReplaceAll])
      else if Pos('TextOut', Op) > 0 then
        Op := StringReplace(Op, 'TextOut', 'DrawText(', [rfReplaceAll])
      else if Pos('LineTo', Op) > 0 then
        Op := 'DrawLine(' + StringReplace(Op, 'LineTo', '', [rfReplaceAll]);

      Result.Add('    ' + Op);
    end
    else
    begin
      if InCanvas then
      begin
        Result.Add('  end;');
        InCanvas := False;
      end;
      Result.Add(Line);
    end;
  end;

  if InCanvas then
    Result.Add('  end;');
end;

end.
