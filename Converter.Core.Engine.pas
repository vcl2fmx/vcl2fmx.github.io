{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

unit Converter.Core.Engine;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.Math,
  System.DateUtils,
  System.NetEncoding,
  System.Generics.Collections,
  System.RegularExpressions,
    FMX.Forms,
    FMX.Memo,
    System.Types,
  Converter.Core.Types,
  Converter.Core.FileManager,
  Converter.Core.Integration,
  Converter.Project.Generator;

type
  TConverterEngine = class
  private
    FContext: TConversionContext;
    FFileManager: TFileManager;
    FOrchestrator: TConversionOrchestrator;
    FProjectGenerator: TProjectGenerator;

    FCancelled: Boolean;
    FFilesProcessed: Integer;
    FFilesConverted: Integer;
    FFilesErrors: Integer;
    FFilesSkipped: Integer;

    FConversionLog: TStringList;
    FStartTime: TDateTime;
    FEndTime: TDateTime;
    FScreenMemo: TMemo;

    procedure ProcessPasFile(const AFileName: string);
    procedure ProcessDfmFile(const AFileName: string);
    procedure AuditDfmFmxFidelity(const AFileName, ASourceDfm,
      AGeneratedFmx: string);
    procedure ScanPascalIncludeDirectives(const AFileName, ACode: string);
    procedure CopyPascalIncludeFile(const ASourcePasFile, AIncludePath,
      AIncludeName: string; ALine: Integer);
    procedure GenerateReport;
    procedure AuditGeneratedOutput;
    procedure AuditGeneratedFile(const AFileName: string);
    procedure BuildCrossUnitSemanticIndex;
    procedure ExportMappingPackAuthoringSuggestions;
    procedure UILog(const Msg: string; const ForceScreen: Boolean = True); overload;
    procedure UILog(const ScreenMsg, LogMsg: string;
      const ForceScreen: Boolean = True); overload;
    procedure LogToFile(const Msg: string);
    procedure RebuildServicesForContext(AContext: TConversionContext);
    function TryReadWithEncoding(const AFileName: string; out Code: string): Boolean;
    function SeverityToString(Severity: TConversionSeverity): string;

  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    function Convert(AContext: TConversionContext): Boolean;
    procedure Cancel;

    property ScreenMemo: TMemo read FScreenMemo write FScreenMemo;
    property FilesProcessed: Integer read FFilesProcessed;
    property FilesConverted: Integer read FFilesConverted;
    property FilesWithErrors: Integer read FFilesErrors;
    property FilesSkipped: Integer read FFilesSkipped;
    property StartTime: TDateTime read FStartTime;
    property EndTime: TDateTime read FEndTime;
  end;

implementation

constructor TConverterEngine.Create(AContext: TConversionContext);
begin
  inherited Create;
  RebuildServicesForContext(AContext);
  FCancelled := False;
  FScreenMemo := nil;
  FFilesProcessed := 0;
  FFilesConverted := 0;
  FFilesErrors := 0;
  FFilesSkipped := 0;
  FConversionLog := TStringList.Create;
end;

destructor TConverterEngine.Destroy;
begin
  FConversionLog.Free;
  FProjectGenerator.Free;
  FOrchestrator.Free;
  FFileManager.Free;
  inherited;
end;

procedure TConverterEngine.RebuildServicesForContext(AContext: TConversionContext);
begin
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('Conversion context is not assigned');

  if AContext = FContext then
    Exit;

  FProjectGenerator.Free;
  FOrchestrator.Free;
  FFileManager.Free;

  FContext := AContext;
  FFileManager := TFileManager.Create(FContext);
  FOrchestrator := TConversionOrchestrator.Create(FContext);
  FProjectGenerator := TProjectGenerator.Create(FContext);
end;

function TConverterEngine.SeverityToString(Severity: TConversionSeverity): string;
begin
  case Severity of
    csInfo: Result := 'INFO';
    csWarning: Result := 'WARNING';
    csManualReview: Result := 'MANUAL REVIEW';
    csError: Result := 'ERROR';
    csCritical: Result := 'CRITICAL';
  else
    Result := 'UNKNOWN';
  end;
end;

procedure TConverterEngine.UILog(const Msg: string; const ForceScreen: Boolean = True);
begin
  UILog(Msg, Msg, ForceScreen);
end;

procedure TConverterEngine.UILog(const ScreenMsg, LogMsg: string;
  const ForceScreen: Boolean = True);
var
  ScreenMemo: TMemo;
begin
  ScreenMemo := FScreenMemo;
  if ScreenMemo <> nil then
  begin
    if TThread.CurrentThread.ThreadID = MainThreadID then
    begin
      ScreenMemo.Lines.Add(ScreenMsg);
      ScreenMemo.GoToTextEnd;
    end
    else
      TThread.Synchronize(nil,
        procedure
        begin
          ScreenMemo.Lines.Add(ScreenMsg);
          ScreenMemo.GoToTextEnd;
        end);
  end;

  // Also log to file
  LogToFile(LogMsg);
end;

procedure TConverterEngine.LogToFile(const Msg: string);
begin
  FConversionLog.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), Msg]));
end;

function TConverterEngine.TryReadWithEncoding(const AFileName: string; out Code: string): Boolean;
var
  EncodingName: string;
begin
  UILog(Format('  Reading %s...', [ExtractFileName(AFileName)]));
  Result := VCL2FMXTryReadTextFile(AFileName, Code, EncodingName);
  if Result then
    UILog(Format('  Encoding: %s', [EncodingName]))
  else
    UILog('  FAILED: Could not read file with supported encodings');
end;
procedure TConverterEngine.AuditGeneratedFile(const AFileName: string);
var
  Lines: TStringList;
  Ext: string;
  I: Integer;
  Line: string;
  CodeLine: string;
  Trimmed: string;
  OriginalTrimmed: string;
  LastSignificantLine: string;
  InBraceComment: Boolean;
  InParenComment: Boolean;
  TailInBraceComment: Boolean;
  TailInParenComment: Boolean;
  EncodingName: string;

  procedure AddGeneratedReview(const AProblemType, AMessage, ASuggestedFix: string;
    AIsBlocking: Boolean = False);
  var
    Issue: TConversionIssue;
  begin
    Issue := TConversionIssue.Create(csManualReview, AMessage);
    Issue.FileName := AFileName;
    Issue.LineNumber := I + 1;
    Issue.ProblemType := AProblemType;
    Issue.OriginalCode := TrimRight(Line);
    Issue.SuggestedFix := ASuggestedFix;
    Issue.IsBlocking := AIsBlocking;
    FContext.AddIssue(Issue);
  end;

  function IsPascalCommentLine(const S: string): Boolean;
  begin
    Result := StartsText('//', S) or StartsText('{', S) or StartsText('(*', S);
  end;

  function StripPascalCommentsFromLine(const S: string;
    var AInBraceComment, AInParenComment: Boolean): string;
  var
    P: Integer;
    Ch: Char;
  begin
    Result := '';
    P := 1;
    while P <= Length(S) do
    begin
      if AInBraceComment then
      begin
        if S[P] = '}' then
          AInBraceComment := False;
        Inc(P);
        Continue;
      end;

      if AInParenComment then
      begin
        if (S[P] = '*') and (P < Length(S)) and (S[P + 1] = ')') then
        begin
          AInParenComment := False;
          Inc(P, 2);
        end
        else
          Inc(P);
        Continue;
      end;

      if (S[P] = '/') and (P < Length(S)) and (S[P + 1] = '/') then
        Break;

      if S[P] = '{' then
      begin
        AInBraceComment := True;
        Inc(P);
        Continue;
      end;

      if (S[P] = '(') and (P < Length(S)) and (S[P + 1] = '*') then
      begin
        AInParenComment := True;
        Inc(P, 2);
        Continue;
      end;

      Ch := S[P];
      Result := Result + Ch;
      Inc(P);
    end;
  end;

  function StripCommentPrefix(const S, Prefix: string): string;
  begin
    Result := Trim(S);
    while StartsText(Prefix, Result) do
      Result := Trim(Copy(Result, Length(Prefix) + 1, MaxInt));
  end;

  function LooksLikeCommentedPascalCode(const S: string): Boolean;
  var
    ReviewText: string;
  begin
    ReviewText := Trim(LowerCase(S));
    Result :=
      (ReviewText = '') or
      StartsText('procedure ', ReviewText) or
      StartsText('function ', ReviewText) or
      StartsText('constructor ', ReviewText) or
      StartsText('destructor ', ReviewText) or
      StartsText('class procedure ', ReviewText) or
      StartsText('class function ', ReviewText) or
      StartsText('begin', ReviewText) or
      StartsText('end', ReviewText) or
      StartsText('if ', ReviewText) or
      StartsText('else', ReviewText) or
      StartsText('try', ReviewText) or
      StartsText('except', ReviewText) or
      StartsText('finally', ReviewText) or
      StartsText('case ', ReviewText) or
      StartsText('for ', ReviewText) or
      StartsText('while ', ReviewText) or
      StartsText('repeat', ReviewText) or
      StartsText('until ', ReviewText) or
      StartsText('with ', ReviewText) or
      StartsText('inherited', ReviewText) or
      StartsText('exit', ReviewText) or
      TRegEx.IsMatch(ReviewText, '^[a-z_][a-z0-9_]*\s*:', [roIgnoreCase]) or
      ContainsText(ReviewText, ':=') or
      ContainsText(ReviewText, '(') or
      ContainsText(ReviewText, ')') or
      ContainsText(ReviewText, ';');
  end;

  function UsesIntegerDivOnFmxSizeValue(const S: string): Boolean;
  var
    AssignPos: Integer;
    RHS: string;
  begin
    AssignPos := Pos(':=', S);
    if AssignPos > 0 then
      RHS := Copy(S, AssignPos + 2, MaxInt)
    else
      RHS := S;

    Result := TRegEx.IsMatch(RHS,
      '(\.\s*(Width|Height)|\bClientWidth\b|\bClientHeight\b)[^;]*\bdiv\b|' +
      '\bdiv\b[^;]*(\.\s*(Width|Height)|\bClientWidth\b|\bClientHeight\b)',
      [roIgnoreCase]);
  end;

  function GetPerformReplacementSuggestion(const S: string): string;
  begin
    if TRegEx.IsMatch(S, '\bEM_SETSEL\b', [roIgnoreCase]) then
      Result := 'Replace EM_SETSEL with FMX memo selection code. For TMemo, review CaretPosition and selection APIs in the IDE; for TEdit, use SelStart/SelLength where available.'
    else if TRegEx.IsMatch(S, '\bEM_LINESCROLL\b|\bEM_SCROLLCARET\b', [roIgnoreCase]) then
      Result := 'Replace EM_LINESCROLL/EM_SCROLLCARET with FMX memo scrolling behavior. Prefer moving the caret/selection into view or using the memo viewport/scroll-box support exposed by the target FMX control.'
    else if TRegEx.IsMatch(S, '\bEM_LINEFROMCHAR\b|\bEM_LINEINDEX\b', [roIgnoreCase]) then
      Result := 'Replace EM_LINEFROMCHAR/EM_LINEINDEX with an FMX helper that derives the line from memo text and caret position; VCL line-message return values do not carry over directly.'
    else if TRegEx.IsMatch(S, '\bLB_SELECTSTRING\b', [roIgnoreCase]) then
      Result := 'Replace LB_SELECTSTRING with an FMX list search: loop through Items, compare text, and assign ItemIndex when a match is found.'
    else if TRegEx.IsMatch(S, '\bWM_SYSCOMMAND\b', [roIgnoreCase]) then
      Result := 'Replace WM_SYSCOMMAND Perform calls by mapping the specific SC_* command to FMX form logic such as Close, WindowState, OnCloseQuery, or platform-specific code.'
    else
      Result := 'Replace this VCL Perform(...) message dispatch with the equivalent FMX control API, event, or platform-specific code for the specific message being sent.';
  end;
  procedure AddGeneratedCommentReviewIfNeeded(const ATrimmed: string);
  var
    ReviewText: string;
  begin
    if StartsText('// FMX manual review:', ATrimmed) then
    begin
      ReviewText := StripCommentPrefix(ATrimmed, '// FMX manual review:');

      if SameText(ReviewText, 'TLayout has no TextSettings') then
        AddGeneratedReview(
          'Unsupported text-settings target',
          'Generated code attempted to map text settings onto TLayout, which does not expose TextSettings in FMX.',
          'Review this generated code manually and move the text styling to an FMX text control if needed.',
          False)
      else if not LooksLikeCommentedPascalCode(ReviewText) then
        AddGeneratedReview(
          'Generated manual-review note',
          'Generated code includes a converter manual-review note: ' + ReviewText,
          'Review this note in the IDE and complete the missing FMX behavior manually where needed.',
          False);
    end;
  end;

begin
  if not TFile.Exists(AFileName) then
    Exit;

  Ext := LowerCase(ExtractFileExt(AFileName));
  if not MatchText(Ext, ['.pas', '.dpr', '.fmx']) then
    Exit;

  Lines := TStringList.Create;
  try
    if not VCL2FMXTryReadTextFile(AFileName, CodeLine, EncodingName) then
    begin
      FContext.AddIssue(csWarning,
        'Generated file could not be audited because it could not be read: ' +
          ExtractFileName(AFileName),
        'Generated output audit read failure',
        '',
        'Open the generated file in the IDE and verify it manually.',
        -1,
        False);
      Exit;
    end;
    Lines.Text := CodeLine;
    InBraceComment := False;
    InParenComment := False;
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];
      OriginalTrimmed := Trim(Line);
      CodeLine := Line;
      if MatchText(Ext, ['.pas', '.dpr']) then
        CodeLine := StripPascalCommentsFromLine(Line, InBraceComment, InParenComment);
      Trimmed := Trim(CodeLine);
      if (OriginalTrimmed = '') and (Trimmed = '') then
        Continue;

      if MatchText(Ext, ['.pas', '.dpr']) then
      begin
        if IsPascalCommentLine(OriginalTrimmed) then
        begin
          AddGeneratedCommentReviewIfNeeded(OriginalTrimmed);
          Continue;
        end;

        if Trimmed = '' then
          Continue;

        if TRegEx.IsMatch(Trimmed, ':\s*TBitBtn\b', [roIgnoreCase]) then
          AddGeneratedReview(
            'Leftover VCL declaration in generated Pascal',
            'Generated Pascal still declares a VCL TBitBtn.',
            'Replace the declaration with TButton or the FMX equivalent before compiling.',
            True);

        if TRegEx.IsMatch(Trimmed, '\bVcl\.', [roIgnoreCase]) then
          AddGeneratedReview(
            'Leftover VCL unit reference in generated Pascal',
            'Generated Pascal still references a Vcl.* unit namespace.',
            'Replace the remaining Vcl.* reference with the correct FMX or System unit before compiling.',
            True);

        if TRegEx.IsMatch(Trimmed, '^\{\$R\s+\*\.DFM\}', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL form resource directive in generated Pascal',
            'Generated Pascal still references {$R *.DFM}.',
            'Change this resource directive to {$R *.fmx} or rerun after correcting the converter rewrite path.',
            True);

        if TRegEx.IsMatch(Trimmed, '^\s*(?:class\s+)?(?:procedure|function)\b.*\bmessage\b.*;', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL message-handler declaration still present',
            'Generated Pascal still declares a VCL-style message-handler method.',
            'Replace this message-based handler with an FMX-safe event or manual-review implementation before compiling.',
            True);

        if TRegEx.IsMatch(Trimmed, ':\s*TTrayIcon\b', [roIgnoreCase]) then
          AddGeneratedReview(
            'Unsupported component still emitted in generated Pascal',
            'Generated Pascal still declares TTrayIcon.',
            'Remove or replace this tray icon code manually. FMX has no standard tray icon component.',
            True);

        if TRegEx.IsMatch(Trimmed, ':\s*TApdComPort\b', [roIgnoreCase]) then
          AddGeneratedReview(
            'Unsupported component still emitted in generated Pascal',
            'Generated Pascal still declares TApdComPort.',
            'Replace this third-party serial component with a manual FMX or WinAPI-based implementation.',
            True);

        if ContainsText(Trimmed, 'Application.ShowMainForm') then
          AddGeneratedReview(
            'VCL-only project startup code',
            'Generated code still contains Application.ShowMainForm, which is not valid FMX startup logic here.',
            'Remove this line and review the project startup flow manually.',
            True);

        if ContainsText(Trimmed, 'Application.BringToFront') then
          AddGeneratedReview(
            'VCL-only application call',
            'Generated code still calls Application.BringToFront.',
            'Replace this with an FMX-safe form activation path or handle it manually.',
            True);

        if TRegEx.IsMatch(Trimmed, '\.\s*Perform\s*\(', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL-only runtime method',
            'Generated code still calls Perform(...), which is a VCL message-dispatch pattern.',
            GetPerformReplacementSuggestion(Trimmed),
            True);

        if TRegEx.IsMatch(Trimmed, '\.\s*Invalidate\s*;', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL-only repaint call',
            'Generated code still calls Invalidate on a control.',
            'Replace this with an FMX repaint/update call that the target control actually supports.',
            True);

        if TRegEx.IsMatch(Trimmed, '\b\w*TrayIcon\w*\.', [roIgnoreCase]) then
          AddGeneratedReview(
            'Unsupported tray icon usage still present',
            'Generated Pascal still contains runtime tray icon usage.',
            'Remove or redesign the tray behavior manually before relying on this output.',
            True);

        if TRegEx.IsMatch(Trimmed, '^\s*(?:Self|AForm)\.Color\s*:=', [roIgnoreCase]) then
          AddGeneratedReview(
            'Leftover VCL color assignment',
            'Generated Pascal still assigns to Color directly.',
            'Review whether this should become Fill.Color, TextSettings.FontColor, or another FMX color property.',
            True);

        if TRegEx.IsMatch(Trimmed, '\bBorderStyle\s*:=\s*bs\w+', [roIgnoreCase]) then
          AddGeneratedReview(
            'Leftover VCL border-style enum',
            'Generated Pascal still assigns a VCL BorderStyle enum value.',
            'Map this to the FMX form/control border model or update the enum usage manually.',
            True);

        if TRegEx.IsMatch(Trimmed, '\bWindowState\s*:=\s*ws\w+', [roIgnoreCase]) then
          AddGeneratedReview(
            'Potential VCL window-state enum usage',
            'Generated Pascal still assigns an unqualified VCL-style WindowState value.',
            'Review this assignment and replace it with the correct FMX window-state usage if needed.',
            True);

        if TRegEx.IsMatch(Trimmed, '\.\s*(Stretch|Proportional)\s*:=', [roIgnoreCase]) then
          AddGeneratedReview(
            'Leftover VCL image property',
            'Generated Pascal still uses a VCL image sizing property.',
            'Review this image behavior and map it to FMX TImage.WrapMode or other FMX image settings manually.',
            True);

        if TRegEx.IsMatch(Trimmed, '\.\s*Picture(\b|[\.\s:=])', [roIgnoreCase]) then
          AddGeneratedReview(
            'Leftover VCL image API',
            'Generated Pascal still uses the VCL Picture API.',
            'Replace this with FMX TImage.Bitmap operations before relying on this output.',
            True);

        if UsesIntegerDivOnFmxSizeValue(Trimmed) then
          AddGeneratedReview(
            'Potential integer division on FMX size values',
            'Generated Pascal uses div with width/height values that are often floating-point in FMX.',
            'Review this expression and consider using / with Round/Trunc where needed.',
            False);
      end
      else if SameText(Ext, '.fmx') then
      begin
        if TRegEx.IsMatch(Trimmed, '^StyleElements\s*=', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL-only streamed property',
            'Generated FMX stream still contains StyleElements.',
            'Remove this property or replace it with an FMX styling approach.',
            True);

        if TRegEx.IsMatch(Trimmed, '^Style\s*=', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL-only streamed property',
            'Generated FMX stream still contains a VCL Style property.',
            'Remove or manually map this property to an FMX equivalent.',
            True);

        if TRegEx.IsMatch(Trimmed, '^Stroke\.Style\s*=', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL-only streamed property',
            'Generated FMX stream still contains Stroke.Style.',
            'Replace this with Stroke.Kind or the correct FMX stroke property.',
            True);

        if TRegEx.IsMatch(Trimmed, '^Shape\s*=', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL-only streamed property',
            'Generated FMX stream still contains the VCL Shape property.',
            'Replace this by using the correct FMX shape class and remove the VCL Shape setting.',
            True);

        if TRegEx.IsMatch(Trimmed, '^DoubleBuffered\s*=', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL-only streamed property',
            'Generated FMX stream still contains DoubleBuffered.',
            'Remove this VCL buffering property or review the control behavior manually.',
            True);

        if TRegEx.IsMatch(Trimmed, '^ParentDoubleBuffered\s*=', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL-only streamed property',
            'Generated FMX stream still contains ParentDoubleBuffered.',
            'Remove this VCL buffering property or review the control behavior manually.',
            True);

        if TRegEx.IsMatch(Trimmed, '^DesignSize\s*=', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL-only streamed property',
            'Generated FMX stream still contains DesignSize.',
            'Remove this VCL designer-only property and review the layout manually.',
            True);

        if TRegEx.IsMatch(Trimmed, '^RoundedCorners\s*=', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL-only streamed property',
            'Generated FMX stream still contains RoundedCorners.',
            'Review the form chrome or visual styling manually in FMX.',
            True);

        if TRegEx.IsMatch(Trimmed, '^TickStyle\s*=', [roIgnoreCase]) then
          AddGeneratedReview(
            'VCL-only streamed property',
            'Generated FMX stream still contains TickStyle.',
            'Remove this VCL property or restyle the FMX trackbar manually.',
            True);

        if TRegEx.IsMatch(Trimmed, '^Layout\s*=\s*tl', [roIgnoreCase]) then
          AddGeneratedReview(
            'Unmapped VCL text-layout property',
            'Generated FMX stream still contains a VCL Layout value.',
            'Map this to an FMX vertical text alignment property such as TextSettings.VertAlign.',
            True);

        if TRegEx.IsMatch(Trimmed, '^object\s+\w+\s*:\s*TTrayIcon\b', [roIgnoreCase]) then
          AddGeneratedReview(
            'Unsupported component still emitted in generated FMX',
            'Generated FMX stream still declares TTrayIcon.',
            'Remove this streamed component and handle tray behavior manually.',
            True);

        if TRegEx.IsMatch(Trimmed, '^object\s+\w+\s*:\s*TApdComPort\b', [roIgnoreCase]) then
          AddGeneratedReview(
            'Unsupported component still emitted in generated FMX',
            'Generated FMX stream still declares TApdComPort.',
            'Remove this streamed component and replace serial communications manually.',
            True);
      end;
    end;

    if MatchText(Ext, ['.pas', '.dpr']) then
    begin
      LastSignificantLine := '';
      TailInBraceComment := False;
      TailInParenComment := False;
      for I := Lines.Count - 1 downto 0 do
      begin
        Line := Lines[I];
        Trimmed := Trim(StripPascalCommentsFromLine(Line, TailInBraceComment, TailInParenComment));
        if Trimmed = '' then
          Continue;
        LastSignificantLine := Trimmed;
        Break;
      end;

      if (LastSignificantLine <> '') and (not SameText(LastSignificantLine, 'end.')) then
        AddGeneratedReview(
          'Generated Pascal ends unexpectedly',
          'Generated Pascal does not end with end., which usually means the file was truncated or a rewrite left the unit/program incomplete.',
          'Inspect the tail of this generated file, restore the missing closing code, and rerun after correcting the underlying converter rule.',
          True);
    end;
  finally
    Lines.Free;
  end;
end;

procedure TConverterEngine.AuditGeneratedOutput;
var
  Files: TStringDynArray;
  FileName: string;
  FileWriteTime: TDateTime;
begin
  if (FContext = nil) or (FContext.Options.OutputPath = '') or
     (not DirectoryExists(FContext.Options.OutputPath)) then
    Exit;

  Files := TDirectory.GetFiles(FContext.Options.OutputPath, '*.*', TSearchOption.soAllDirectories);
  for FileName in Files do
    if MatchText(LowerCase(ExtractFileExt(FileName)), ['.pas', '.dpr', '.fmx']) then
    begin
      FileWriteTime := TFile.GetLastWriteTime(FileName);

      // Reused output folders can contain stale files from earlier conversions.
      // Only audit files touched during the current run so the report reflects
      // the current project output instead of unrelated leftovers.
      if (FStartTime > 0) and (FileWriteTime < IncSecond(FStartTime, -1)) then
        Continue;

      AuditGeneratedFile(FileName);
    end;
end;

procedure TConverterEngine.ExportMappingPackAuthoringSuggestions;
var
  Issue: TConversionIssue;
  Suggestions: TStringList;
  OutputFile: string;
  Match: TMatch;
  ComponentName: string;
  VclClassName: string;
  FirstItem: Boolean;

  function JsonEscape(const Value: string): string;
  begin
    Result := StringReplace(Value, '\', '\\', [rfReplaceAll]);
    Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
    Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
    Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
    Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  end;

  function IsSuggestionIssue(const AIssue: TConversionIssue): Boolean;
  begin
    Result := SameText(AIssue.ProblemType, 'Mapping assistance') or
      SameText(AIssue.ProblemType, 'Unsupported component') or
      SameText(AIssue.ProblemType, 'Mapping pack detection only') or
      SameText(AIssue.ProblemType, 'Mapping pack manual review') or
      SameText(AIssue.ProblemType, 'Low-confidence mapping pack rule');
  end;
begin
  if (FContext = nil) or (FContext.Options.OutputPath = '') then
    Exit;

  Suggestions := TStringList.Create;
  try
    Suggestions.Add('[');
    FirstItem := True;

    for Issue in FContext.Issues do
    begin
      if not IsSuggestionIssue(Issue) then
        Continue;

      ComponentName := '';
      VclClassName := '';
      Match := TRegEx.Match(Issue.OriginalCode,
        '\bobject\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([A-Za-z_][A-Za-z0-9_]*)',
        [roIgnoreCase]);
      if Match.Success then
      begin
        ComponentName := Match.Groups[1].Value;
        VclClassName := Match.Groups[2].Value;
      end;

      if not FirstItem then
        Suggestions.Add('  ,');
      FirstItem := False;
      Suggestions.Add('  {');
      Suggestions.Add('    "vcl_class": "' + JsonEscape(VclClassName) + '",');
      Suggestions.Add('    "component_name": "' + JsonEscape(ComponentName) + '",');
      Suggestions.Add('    "problem_type": "' + JsonEscape(Issue.ProblemType) + '",');
      Suggestions.Add('    "source_file": "' + JsonEscape(Issue.FileName) + '",');
      Suggestions.Add('    "line": ' + IntToStr(Issue.LineNumber) + ',');
      Suggestions.Add('    "original_code": "' + JsonEscape(Issue.OriginalCode) + '",');
      Suggestions.Add('    "suggested_authoring_action": "' + JsonEscape(Issue.SuggestedFix) + '"');
      Suggestions.Add('  }');
    end;

    Suggestions.Add(']');

    if FirstItem then
      Exit;

    OutputFile := TPath.Combine(FContext.Options.OutputPath,
      'MappingPack_Authoring_Suggestions.json');
    TFile.WriteAllText(OutputFile, Suggestions.Text, TEncoding.UTF8);
    FContext.AddIssue(csInfo,
      'Mapping-pack authoring suggestions exported: ' + OutputFile,
      'Mapping-pack authoring suggestions',
      OutputFile,
      'Use this JSON as a starting point when adding reusable component mapping-pack rules. Validate each suggested rule with contracts before trusting it.',
      -1,
      False);
  finally
    Suggestions.Free;
  end;
end;
procedure TConverterEngine.BuildCrossUnitSemanticIndex;
var
  Files: TStringDynArray;
  FileName: string;
  Code: string;
  EncodingName: string;
  CleanCode: string;
  Matches: TMatchCollection;
  Match: TMatch;
  SearchOption: TSearchOption;

  function IsExcludedSemanticFile(const AFileName: string): Boolean;
  var
    RelativePath: string;
    SourceRoot: string;
    Parts: TArray<string>;
    PartIndex: Integer;
  begin
    Result := False;
    if (FContext = nil) or (FContext.Options.SourcePath = '') then
      Exit;

    SourceRoot := IncludeTrailingPathDelimiter(TPath.GetFullPath(FContext.Options.SourcePath));
    RelativePath := ExtractRelativePath(SourceRoot, TPath.GetFullPath(AFileName));
    Parts := RelativePath.Split(['\', '/']);
    for PartIndex := 0 to High(Parts) do
      if VCL2FMXIsBuildArtifactFolder(Parts[PartIndex]) then
        Exit(True);
  end;

  procedure AddUnique(AList: TStringList; const AValue: string);
  begin
    if (Trim(AValue) <> '') and (AList.IndexOf(AValue) = -1) then
      AList.Add(AValue);
  end;
begin
  if (FContext = nil) or (FContext.Options.SourcePath = '') or
     (not DirectoryExists(FContext.Options.SourcePath)) then
    Exit;

  FContext.SemanticClassIndex.Clear;
  FContext.SemanticMethodIndex.Clear;

  if FContext.Options.ProcessSubdirectories then
    SearchOption := TSearchOption.soAllDirectories
  else
    SearchOption := TSearchOption.soTopDirectoryOnly;

  Files := TDirectory.GetFiles(FContext.Options.SourcePath, '*.pas', SearchOption);
  for FileName in Files do
  begin
    if IsExcludedSemanticFile(FileName) then
      Continue;

    if not VCL2FMXTryReadTextFile(FileName, Code, EncodingName) then
      Continue;

    CleanCode := VCL2FMXStripCommentsForAnalysis(Code);

    Matches := TRegEx.Matches(CleanCode,
      '\b([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(class|record|interface|class\s+helper|record\s+helper)\b',
      [roIgnoreCase]);
    for Match in Matches do
      AddUnique(FContext.SemanticClassIndex, Match.Groups[1].Value);

    Matches := TRegEx.Matches(CleanCode,
      '\b(?:class\s+procedure|class\s+function|procedure|function|constructor|destructor)\s+([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\b',
      [roIgnoreCase]);
    for Match in Matches do
      AddUnique(FContext.SemanticMethodIndex,
        Match.Groups[1].Value + '.' + Match.Groups[2].Value);
  end;

  FContext.AddIssue(csInfo,
    Format('Cross-unit semantic index built: %d classes, %d methods.',
      [FContext.SemanticClassIndex.Count, FContext.SemanticMethodIndex.Count]),
    'Pascal semantic index',
    '',
    'The converter used this project-wide index to reduce false positives when checking declarations and implementations across units.',
    -1,
    False);
end;
function TConverterEngine.Convert(AContext: TConversionContext): Boolean;
var
  FileName: string;
  TotalFiles: Integer;
  i: Integer;
  HasBlockingIssues: Boolean;
  HasManualReviewIssues: Boolean;
begin
  Result := False;

  RebuildServicesForContext(AContext);
  FCancelled := False;
  FFilesProcessed := 0;
  FFilesConverted := 0;
  FFilesErrors := 0;
  FFilesSkipped := 0;
  FStartTime := Now;
  FContext.StartTime := FStartTime;
  FContext.ClearIssues;
  FConversionLog.Clear;

  if FScreenMemo = nil then
    LogToFile('WARNING: ScreenMemo not assigned - UI updates disabled')
  else
    UILog('Screen memo connected');

  UILog('');
  UILog('VCL TO FMX CONVERSION STARTED');
  UILog(StringOfChar('=', 40));
  UILog(Format('Source: %s', [FContext.Options.SourcePath]));
  UILog(Format('Output: %s', [FContext.Options.OutputPath]));
  UILog('');

  try
    FFileManager.Reset;
    BuildCrossUnitSemanticIndex;

    if not FFileManager.PrepareOutput then
    begin
      Exit;
    end;

    TotalFiles := FFileManager.FileCount;

    UILog(Format('Found %d files to process', [TotalFiles]));
    UILog('');

    i := 0;
    while FFileManager.HasMoreFiles and not FCancelled do
    begin
      FileName := FFileManager.GetNextFile;
      Inc(FFilesProcessed);
      Inc(i);


      UILog(Format('[%d/%d] Processing: %s', [i, TotalFiles, ExtractFileName(FileName)]));

      try
        if SameText(ExtractFileExt(FileName), '.pas') then
        begin
          ProcessPasFile(FileName);
        end
        else if SameText(ExtractFileExt(FileName), '.dfm') then
        begin
          ProcessDfmFile(FileName);
        end;
      except
        on E: Exception do
        begin
          Inc(FFilesErrors);
          UILog(Format('  FAILED: %s', [ExtractFileName(FileName)]),
            Format('  FAILED: %s - %s', [ExtractFileName(FileName), E.Message]));
          FContext.AddIssue(csError,
            'File conversion failed: ' + E.Message,
            'File conversion failure',
            '',
            'Open the source file referenced in this report entry, review the exception text, and rerun after correcting the blocker.',
            -1,
            True);
        end;
      end;
    end;

    UILog('');
    if FContext.Options.DryRunPreview then
    begin
      UILog('Dry-run preview: project generation skipped');
      FContext.AddIssue(csInfo,
        'Dry-run preview skipped project file generation.',
        'Dry-run preview',
        '',
        'Run conversion again with dry-run disabled to write converted project artifacts.',
        -1,
        False);
    end
    else
    begin
      UILog('Generating project files...');

      FProjectGenerator.GenerateProject;
      AuditGeneratedOutput;

      UILog('Project files generated');
    end;

    ExportMappingPackAuthoringSuggestions;

    FEndTime := Now;
    if FContext.Options.CreateReport then
      GenerateReport;
    HasBlockingIssues := (FFilesErrors > 0) or FContext.HasBlockingIssues;
    HasManualReviewIssues := FContext.HasManualReviewIssues;

    if HasBlockingIssues then
    begin
      UILog('Conversion completed with blocking issues. Open the report, fix blocking items first, then review the generated output in the IDE.');
      Result := False;
    end
    else if HasManualReviewIssues then
    begin
      UILog('Conversion completed with manual review required. Open the report, review the grouped manual-review items, and verify the generated code in the IDE.');
      Result := True;
    end
    else
    begin
      UILog('Conversion completed cleanly. Open the report for a final sanity check before using the output.');
      Result := True;
    end;

  except
    on E: Exception do
    begin
      FEndTime := Now;
      UILog(Format('FATAL ERROR: %s', [E.Message]));
      FContext.AddIssue(csError,
        'Fatal conversion error: ' + E.Message,
        'Conversion session failed',
        '',
        'Review the fatal error text, correct the blocking condition, and rerun the converter.',
        -1,
        True);
    end;
  end;
end;

procedure TConverterEngine.CopyPascalIncludeFile(const ASourcePasFile, AIncludePath,
  AIncludeName: string; ALine: Integer);
var
  SourceRoot: string;
  SourceFull: string;
  IncludeFull: string;
  RelativeInclude: string;
  OutputFile: string;
  OutputDir: string;
begin
  if (FContext = nil) or (FContext.Options.OutputPath = '') then
    Exit;

  IncludeFull := TPath.GetFullPath(AIncludePath);
  if not TFile.Exists(IncludeFull) then
    Exit;

  if FContext.Options.SourcePath <> '' then
  begin
    SourceRoot := IncludeTrailingPathDelimiter(TPath.GetFullPath(FContext.Options.SourcePath));
    if not StartsText(SourceRoot, IncludeFull) then
    begin
      FContext.AddIssue(csWarning,
        'Pascal include file was found outside the source folder and was not copied: ' + AIncludeName,
        'Pascal include outside source folder',
        IncludeFull,
        'Copy this include file manually if the generated FMX project still depends on it.',
        ALine,
        False);
      Exit;
    end;
    RelativeInclude := Copy(IncludeFull, Length(SourceRoot) + 1, MaxInt);
  end
  else
  begin
    SourceFull := IncludeTrailingPathDelimiter(TPath.GetFullPath(ExtractFilePath(ASourcePasFile)));
    if StartsText(SourceFull, IncludeFull) then
      RelativeInclude := Copy(IncludeFull, Length(SourceFull) + 1, MaxInt)
    else
      RelativeInclude := TPath.GetFileName(IncludeFull);
  end;

  if (RelativeInclude = '') or TPath.IsPathRooted(RelativeInclude) or
     (Pos('..' + PathDelim, RelativeInclude) > 0) or StartsText('..', RelativeInclude) then
  begin
    FContext.AddIssue(csWarning,
      'Pascal include file could not be safely mapped to the output folder: ' + AIncludeName,
      'Pascal include copy skipped',
      IncludeFull,
      'Copy this include file manually if the generated FMX project still depends on it.',
      ALine,
      False);
    Exit;
  end;

  OutputFile := TPath.Combine(FContext.Options.OutputPath, RelativeInclude);
  OutputDir := ExtractFilePath(OutputFile);
  try
    if (OutputDir <> '') and not DirectoryExists(OutputDir) then
      ForceDirectories(OutputDir);
    TFile.Copy(IncludeFull, OutputFile, True);
    FContext.AddIssue(csInfo,
      'Pascal include file copied to output: ' + RelativeInclude,
      'Pascal include copied',
      IncludeFull,
      'The include directive was preserved and the include file was copied beside the generated output. Review/convert the include contents manually if needed.',
      ALine,
      False);
  except
    on E: Exception do
      FContext.AddIssue(csWarning,
        'Pascal include file could not be copied to output: ' + AIncludeName,
        'Pascal include copy failure',
        IncludeFull,
        'Copy this include file manually. Error: ' + E.Message,
        ALine,
        False);
  end;
end;
procedure TConverterEngine.ScanPascalIncludeDirectives(const AFileName, ACode: string);
const
  MAX_INCLUDE_DEPTH = 16;
var
  IncludeStack: TStringList;

  function CleanIncludeName(const RawName: string): string;
  begin
    Result := Trim(RawName);
    if ((Result.StartsWith('''') and Result.EndsWith('''')) or
        (Result.StartsWith('"') and Result.EndsWith('"'))) and
       (Length(Result) >= 2) then
      Result := Copy(Result, 2, Length(Result) - 2);
    Result := Trim(StringReplace(Result, '/', PathDelim, [rfReplaceAll]));
  end;

  function IsPathUnderSourceRoot(const APath: string): Boolean;
  var
    SourceRoot: string;
    FullPath: string;
  begin
    Result := True;
    if (FContext = nil) or (FContext.Options.SourcePath = '') then
      Exit;

    SourceRoot := IncludeTrailingPathDelimiter(TPath.GetFullPath(FContext.Options.SourcePath));
    FullPath := TPath.GetFullPath(APath);
    Result := StartsText(SourceRoot, FullPath);
  end;

  function ResolveIncludePath(const BaseFile, RawName: string; out ResolvedPath: string): Boolean;
  var
    Candidate: string;
    CleanName: string;
  begin
    Result := False;
    ResolvedPath := '';
    CleanName := CleanIncludeName(RawName);
    if CleanName = '' then
      Exit;

    if TPath.IsPathRooted(CleanName) then
    begin
      Candidate := TPath.GetFullPath(CleanName);
      if TFile.Exists(Candidate) then
      begin
        ResolvedPath := Candidate;
        Exit(True);
      end;
      ResolvedPath := Candidate;
      Exit(False);
    end;

    Candidate := TPath.GetFullPath(TPath.Combine(ExtractFilePath(BaseFile), CleanName));
    if TFile.Exists(Candidate) then
    begin
      ResolvedPath := Candidate;
      Exit(True);
    end;

    if FContext.Options.SourcePath <> '' then
    begin
      Candidate := TPath.GetFullPath(TPath.Combine(FContext.Options.SourcePath, CleanName));
      if TFile.Exists(Candidate) then
      begin
        ResolvedPath := Candidate;
        Exit(True);
      end;
    end;

    ResolvedPath := CleanName;
  end;

  procedure AddIncludeIssue(ASeverity: TConversionSeverity; const AMessage,
    AProblemType, AOriginalCode, ASuggestedFix: string; ALine: Integer;
    AIsBlocking: Boolean);
  begin
    FContext.AddIssue(ASeverity, AMessage, AProblemType, AOriginalCode,
      ASuggestedFix, ALine, AIsBlocking);
  end;

  function StripCommentsForIncludeDirectives(const Code: string): string;
type
  TCommentState = (csNone, csLine, csBrace, csParenStar);
var
  I: Integer;
  State: TCommentState;
  InString: Boolean;
  Ch: Char;

  procedure AppendBlankFor(const AChar: Char);
  begin
    if (AChar = #10) or (AChar = #13) then
      Result := Result + AChar
    else
      Result := Result + ' ';
  end;

  procedure CopyBraceDirective;
  begin
    while I <= Length(Code) do
    begin
      Result := Result + Code[I];
      if Code[I] = '}' then
      begin
        Inc(I);
        Break;
      end;
      Inc(I);
    end;
  end;

  procedure CopyParenStarDirective;
  begin
    while I <= Length(Code) do
    begin
      if (Code[I] = '*') and (I < Length(Code)) and (Code[I + 1] = ')') then
      begin
        Result := Result + '*)';
        Inc(I, 2);
        Break;
      end;
      Result := Result + Code[I];
      Inc(I);
    end;
  end;

begin
  Result := '';
  State := csNone;
  InString := False;
  I := 1;

  while I <= Length(Code) do
  begin
    Ch := Code[I];

    case State of
      csLine:
        begin
          AppendBlankFor(Ch);
          if (Ch = #10) or (Ch = #13) then
            State := csNone;
          Inc(I);
          Continue;
        end;
      csBrace:
        begin
          AppendBlankFor(Ch);
          if Ch = '}' then
            State := csNone;
          Inc(I);
          Continue;
        end;
      csParenStar:
        begin
          if (Ch = '*') and (I < Length(Code)) and (Code[I + 1] = ')') then
          begin
            Result := Result + '  ';
            Inc(I, 2);
            State := csNone;
            Continue;
          end;
          AppendBlankFor(Ch);
          Inc(I);
          Continue;
        end;
    end;

    if InString then
    begin
      Result := Result + Ch;
      if Ch = '''' then
      begin
        if (I < Length(Code)) and (Code[I + 1] = '''') then
        begin
          Result := Result + Code[I + 1];
          Inc(I, 2);
          Continue;
        end;
        InString := False;
      end;
      Inc(I);
      Continue;
    end;

    if Ch = '''' then
    begin
      InString := True;
      Result := Result + Ch;
      Inc(I);
      Continue;
    end;

    if (Ch = '/') and (I < Length(Code)) and (Code[I + 1] = '/') then
    begin
      State := csLine;
      Result := Result + '  ';
      Inc(I, 2);
      Continue;
    end;

    if (Ch = '{') and (I < Length(Code)) and (Code[I + 1] = '$') then
    begin
      CopyBraceDirective;
      Continue;
    end;

    if Ch = '{' then
    begin
      State := csBrace;
      AppendBlankFor(Ch);
      Inc(I);
      Continue;
    end;

    if (Ch = '(') and (I < Length(Code)) and (Code[I + 1] = '*') then
    begin
      if (I + 2 <= Length(Code)) and (Code[I + 2] = '$') then
      begin
        CopyParenStarDirective;
        Continue;
      end;

      State := csParenStar;
      Result := Result + '  ';
      Inc(I, 2);
      Continue;
    end;

    Result := Result + Ch;
    Inc(I);
  end;
end;

  procedure ScanCodeForIncludes(const BaseFile, Code: string; Depth: Integer); forward;

  procedure AnalyzeIncludeFile(const BaseFile, IncludePath, IncludeName,
    DirectiveText: string; DirectiveLine, Depth: Integer);
  var
    FullIncludePath: string;
    IncludeText: string;
    EncodingName: string;
    IncludeLines: TStringList;
    IncludeAnalysisLines: TStringList;
    J: Integer;
    AnalysisLine: string;
    ReportedVCL: Boolean;
    ReportedWinapiMessages: Boolean;
    ReportedMessageHandler: Boolean;
    ReportedMessageAPI: Boolean;
  begin
    FullIncludePath := TPath.GetFullPath(IncludePath);

    if Depth > MAX_INCLUDE_DEPTH then
    begin
      AddIncludeIssue(csWarning,
        'Pascal include nesting depth limit reached: ' + IncludeName,
        'Pascal include depth guard',
        DirectiveText,
        'Review nested include files manually; automatic analysis stops at a safe depth limit.',
        DirectiveLine,
        False);
      Exit;
    end;

    if not IsPathUnderSourceRoot(FullIncludePath) then
    begin
      AddIncludeIssue(csWarning,
        'Pascal include file is outside the source folder and was not analyzed: ' + IncludeName,
        'Pascal include outside source folder',
        FullIncludePath,
        'Move the include under the source tree or review it manually before compiling the generated FMX project.',
        DirectiveLine,
        False);
      Exit;
    end;

    if IncludeStack.IndexOf(AnsiLowerCase(FullIncludePath)) >= 0 then
    begin
      AddIncludeIssue(csWarning,
        'Recursive Pascal include loop detected: ' + IncludeName,
        'Pascal include recursion',
        FullIncludePath,
        'Break the recursive include chain or review it manually; automatic include analysis skipped the recursive edge.',
        DirectiveLine,
        False);
      Exit;
    end;

    CopyPascalIncludeFile(BaseFile, FullIncludePath, IncludeName, DirectiveLine);

    if not VCL2FMXTryReadTextFile(FullIncludePath, IncludeText, EncodingName) then
    begin
      AddIncludeIssue(csWarning,
        'Pascal include file could not be read for analysis: ' + TPath.GetFileName(FullIncludePath),
        'Pascal include read failure',
        FullIncludePath,
        'Open this include file manually and review it for VCL units, message handlers, and Windows-specific code before compiling the generated FMX project.',
        DirectiveLine,
        False);
      Exit;
    end;

    IncludeStack.Add(AnsiLowerCase(FullIncludePath));
    IncludeLines := TStringList.Create;
    IncludeAnalysisLines := TStringList.Create;
    try
      IncludeLines.Text := IncludeText;
      IncludeAnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(IncludeText);
      ReportedVCL := False;
      ReportedWinapiMessages := False;
      ReportedMessageHandler := False;
      ReportedMessageAPI := False;

      for J := 0 to IncludeAnalysisLines.Count - 1 do
      begin
        AnalysisLine := Trim(IncludeAnalysisLines[J]);
        if AnalysisLine = '' then
          Continue;

        if (not ReportedVCL) and
           TRegEx.IsMatch(AnalysisLine, '\bVcl\.', [roIgnoreCase]) then
        begin
          AddIncludeIssue(csManualReview,
            'Included Pascal file contains VCL namespace references: ' + TPath.GetFileName(FullIncludePath),
            'Pascal include VCL reference',
            Format('%s:%d -> %s', [FullIncludePath, J + 1, Trim(IncludeLines[J])]),
            'Manually include/review this file and replace Vcl.* units or types with FMX/System equivalents before compiling the generated project.',
            DirectiveLine,
            True);
          ReportedVCL := True;
        end;

        if (not ReportedWinapiMessages) and
           TRegEx.IsMatch(AnalysisLine, '\bWinapi\.Messages\b|(^|[^A-Za-z0-9_])Messages([^A-Za-z0-9_]|$)', [roIgnoreCase]) then
        begin
          AddIncludeIssue(csWarning,
            'Included Pascal file references Winapi.Messages: ' + TPath.GetFileName(FullIncludePath),
            'Pascal include Winapi.Messages reference',
            Format('%s:%d -> %s', [FullIncludePath, J + 1, Trim(IncludeLines[J])]),
            'Manually review this include file. Windows message units usually require FMX events, System.Messaging, or platform-specific replacement code.',
            DirectiveLine,
            False);
          ReportedWinapiMessages := True;
        end;

        if (not ReportedMessageHandler) and
           TRegEx.IsMatch(AnalysisLine, '^\s*(?:class\s+)?(?:procedure|function)\b.*\bmessage\b.*;', [roIgnoreCase]) then
        begin
          AddIncludeIssue(csManualReview,
            'Included Pascal file declares a VCL message handler: ' + TPath.GetFileName(FullIncludePath),
            'Pascal include message handler',
            Format('%s:%d -> %s', [FullIncludePath, J + 1, Trim(IncludeLines[J])]),
            'Manually include/review this file and replace VCL message handlers with FMX events, System.Messaging, or platform-specific code.',
            DirectiveLine,
            True);
          ReportedMessageHandler := True;
        end;

        if (not ReportedMessageAPI) and
           TRegEx.IsMatch(AnalysisLine, '\b(SendMessage|PostMessage|DispatchMessage|PeekMessage|GetMessage)\s*\(|\.\s*Perform\s*\(|\b(WM_|CM_|CN_|EM_|LB_|CB_|LVM_|TVM_|TCM_|TWM[A-Za-z0-9_]*|TCM[A-Za-z0-9_]*)', [roIgnoreCase]) then
        begin
          AddIncludeIssue(csManualReview,
            'Included Pascal file contains Windows message API usage: ' + TPath.GetFileName(FullIncludePath),
            'Pascal include Windows messaging',
            Format('%s:%d -> %s', [FullIncludePath, J + 1, Trim(IncludeLines[J])]),
            'Manually include/review this file and replace Windows message APIs with FMX control APIs, events, System.Messaging, or platform-specific code.',
            DirectiveLine,
            False);
          ReportedMessageAPI := True;
        end;
      end;

      ScanCodeForIncludes(FullIncludePath, IncludeText, Depth + 1);
    finally
      if IncludeStack.Count > 0 then
        IncludeStack.Delete(IncludeStack.Count - 1);
      IncludeAnalysisLines.Free;
      IncludeLines.Free;
    end;
  end;

  procedure ScanCodeForIncludes(const BaseFile, Code: string; Depth: Integer);
var
  Lines: TStringList;
  OriginalLines: TStringList;
  I: Integer;
  Match: TMatch;
  IncludeName: string;
  IncludePath: string;
  OriginalLine: string;
begin
  Lines := TStringList.Create;
  OriginalLines := TStringList.Create;
  try
    OriginalLines.Text := Code;
    Lines.Text := StripCommentsForIncludeDirectives(Code);
    for I := 0 to Lines.Count - 1 do
    begin
      Match := TRegEx.Match(Lines[I],
        '\{\$\s*(?:I|INCLUDE)\s+([^}]+)\}|\(\*\$\s*(?:I|INCLUDE)\s+(.+?)\*\)',
        [roIgnoreCase]);
      while Match.Success do
      begin
        IncludeName := Match.Groups[1].Value;
        if IncludeName = '' then
          IncludeName := Match.Groups[2].Value;
        IncludeName := CleanIncludeName(IncludeName);
        if I < OriginalLines.Count then
          OriginalLine := Trim(OriginalLines[I])
        else
          OriginalLine := Trim(Lines[I]);

        AddIncludeIssue(csWarning,
          'Pascal include directive found: ' + IncludeName,
          'Pascal include directive',
          OriginalLine,
          'The converter analyzes {$I}/{$INCLUDE} files, preserves the directive, and copies source-tree include files to the generated output. It does not inline include text by default.',
          I + 1,
          False);

        if not ResolveIncludePath(BaseFile, IncludeName, IncludePath) then
        begin
          AddIncludeIssue(csWarning,
            'Pascal include file could not be found for analysis: ' + IncludeName,
            'Pascal include file missing',
            OriginalLine,
            'Locate this include file manually and review it for VCL units, message handlers, and Windows-specific code before compiling the generated FMX project.',
            I + 1,
            False);
          Match := Match.NextMatch;
          Continue;
        end;

        AnalyzeIncludeFile(BaseFile, IncludePath, IncludeName, OriginalLine, I + 1, Depth);
        Match := Match.NextMatch;
      end;
    end;
  finally
    OriginalLines.Free;
    Lines.Free;
  end;
end;

begin
  IncludeStack := TStringList.Create;
  try
    IncludeStack.CaseSensitive := False;
    IncludeStack.Add(AnsiLowerCase(TPath.GetFullPath(AFileName)));
    ScanCodeForIncludes(AFileName, ACode, 1);
  finally
    IncludeStack.Free;
  end;
end;
procedure TConverterEngine.ProcessPasFile(const AFileName: string);
var
  Code: string;
  OriginalCode: string;
  ConvertedOK: Boolean;

  function LastSignificantPascalLine(const ACode: string): string;
  var
    Lines: TStringList;
    I: Integer;
    S: string;
  begin
    Result := '';
    Lines := TStringList.Create;
    try
      Lines.Text := ACode;
      for I := Lines.Count - 1 downto 0 do
      begin
        S := Trim(TRegEx.Replace(Lines[I], '//.*$', ''));
        if S = '' then
          Continue;
        if StartsText('{', S) or StartsText('(*', S) then
          Continue;
        Result := S;
        Break;
      end;
    finally
      Lines.Free;
    end;
  end;

  procedure RestoreFinalEndDotIfLost;
  var
    SourceTail: string;
    ConvertedTail: string;
  begin
    SourceTail := LastSignificantPascalLine(OriginalCode);
    ConvertedTail := LastSignificantPascalLine(Code);
    if SameText(SourceTail, 'end.') and
       (ConvertedTail <> '') and
       (not SameText(ConvertedTail, 'end.')) then
    begin
      Code := TrimRight(Code) + sLineBreak + 'end.' + sLineBreak;
      FContext.AddIssue(csWarning,
        'Generated Pascal final end. was restored for ' + ExtractFileName(AFileName),
        'Pascal structure safeguard',
        ConvertedTail,
        'The source unit ended with end. but the converted unit did not. The converter restored the final terminator; review the tail of this generated file in the IDE.',
        -1,
        False);
    end;
  end;
begin
  UILog(Format('Processing Pascal file: %s', [ExtractFileName(AFileName)]),
    Format('Processing Pascal: %s', [ExtractFileName(AFileName)]));
  ConvertedOK := False;
  FContext.CurrentFile := AFileName;

  if not TryReadWithEncoding(AFileName, Code) then
  begin
    Inc(FFilesSkipped);
    UILog('  FAILED: Could not read file');
    Exit;
  end;
  OriginalCode := Code;
  ScanPascalIncludeDirectives(AFileName, OriginalCode);

  try
    FOrchestrator.ConvertPascal(AFileName, Code);
    RestoreFinalEndDotIfLost;
    Inc(FFilesConverted);
    ConvertedOK := True;
    UILog('  Converted');
  except
    on E: Exception do
    begin
      Inc(FFilesErrors);
      UILog('  FAILED', Format('  FAILED: %s', [E.Message]));
      FContext.AddIssue(csWarning,
        'Pascal conversion could not complete: ' + E.Message,
        'Pascal conversion failure',
        '',
        'Open the Pascal unit in the IDE, inspect the failing construct, and rerun after correcting the blocker.',
        -1,
        True);
    end;
  end;

  if ConvertedOK then
  begin
    if not FFileManager.SaveConvertedFile(AFileName, Code) then
    begin
      Inc(FFilesErrors);
      UILog('  FAILED: Converted Pascal file was not saved');
    end;
  end
  else
  begin
    UILog('  SKIPPED SAVE: Pascal conversion did not produce safe output');
    FContext.AddIssue(csWarning,
      'Pascal file was not saved because conversion did not complete safely: ' +
        ExtractFileName(AFileName),
      'Pascal save skipped',
      '',
      'Review the earlier conversion issue for this file before using any generated output.',
      -1,
      True);
  end;
end;

procedure TConverterEngine.AuditDfmFmxFidelity(const AFileName, ASourceDfm,
  AGeneratedFmx: string);
var
  SourceLines: TStringList;
  I: Integer;
  Match: TMatch;
  EventName: string;
  HandlerName: string;
  ExpectedAssignment: string;
  CurrentObjectName: string;
  CurrentObjectClass: string;
  PropName: string;
  PropValue: string;

  function DfmTextLiteralToVisibleText(const AValue: string): string;
  var
    P: Integer;
    CodeStart: Integer;
    CodeText: string;
    CodeValue: Integer;
  begin
    Result := '';
    P := 1;
    while P <= Length(AValue) do
    begin
      if AValue[P] = '''' then
      begin
        Inc(P);
        while P <= Length(AValue) do
        begin
          if AValue[P] = '''' then
          begin
            if (P < Length(AValue)) and (AValue[P + 1] = '''') then
            begin
              Result := Result + '''';
              Inc(P, 2);
              Continue;
            end;
            Inc(P);
            Break;
          end;

          Result := Result + AValue[P];
          Inc(P);
        end;
      end
      else if AValue[P] = '#' then
      begin
        Inc(P);
        CodeStart := P;
        while (P <= Length(AValue)) and CharInSet(AValue[P], ['0'..'9']) do
          Inc(P);
        CodeText := Copy(AValue, CodeStart, P - CodeStart);
        if TryStrToInt(CodeText, CodeValue) then
          Result := Result + Char(CodeValue);
      end
      else
        Inc(P);
    end;
  end;

  function GeneratedContainsPropertyValue(const AGeneratedFmx, APropName,
    APropValue: string): Boolean;
  var
    VisibleValue: string;
    TrimmedVisibleValue: string;
  begin
    Result := ContainsText(AGeneratedFmx, APropValue);
    if Result then
      Exit;

    VisibleValue := DfmTextLiteralToVisibleText(APropValue);
    TrimmedVisibleValue := Trim(VisibleValue);
    if TrimmedVisibleValue = '' then
      Exit(False);

    Result :=
      ContainsText(AGeneratedFmx, APropName + ' = ' + QuotedStr(TrimmedVisibleValue)) or
      ContainsText(AGeneratedFmx, 'Text = ' + QuotedStr(TrimmedVisibleValue)) or
      ContainsText(AGeneratedFmx, 'Caption = ' + QuotedStr(TrimmedVisibleValue)) or
      ((Length(TrimmedVisibleValue) >= 4) and ContainsText(AGeneratedFmx, TrimmedVisibleValue));
  end;

  function IsUsefulPropertyValue(const AObjectName, APropName,
    APropValue: string): Boolean;
  var
    CleanValue: string;
  begin
    CleanValue := Trim(APropValue);
    if CleanValue = '' then
      Exit(False);
    if SameText(APropName, 'Caption') and
       SameText(CleanValue, QuotedStr(AObjectName)) then
      Exit(False);
    Result := True;
  end;
begin
  if Trim(ASourceDfm) = '' then
    Exit;

  SourceLines := TStringList.Create;
  try
    SourceLines.Text := ASourceDfm;
    CurrentObjectName := '';
    CurrentObjectClass := '';

    for I := 0 to SourceLines.Count - 1 do
    begin
      Match := TRegEx.Match(SourceLines[I],
        '^\s*(?:object|inherited|inline)\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([A-Za-z_][A-Za-z0-9_]*)',
        [roIgnoreCase]);
      if Match.Success then
      begin
        CurrentObjectName := Match.Groups[1].Value;
        CurrentObjectClass := Match.Groups[2].Value;
        if not ContainsText(AGeneratedFmx, CurrentObjectName) then
          FContext.AddIssue(csWarning,
            Format('DFM/FMXL fidelity check: source object %s (%s) was not found by name in the generated FMX.',
              [CurrentObjectName, CurrentObjectClass]),
            'DFM/FMXL object fidelity check',
            Trim(SourceLines[I]),
            'Review the generated form. If this object was intentionally redesigned or folded into another FMX control, no action is needed; otherwise add or refine the component mapping rule.',
            I + 1,
            False);
        Continue;
      end;

      Match := TRegEx.Match(SourceLines[I],
        '^\s*(Caption|Text)\s*=\s*(.+?)\s*$', [roIgnoreCase]);
      if Match.Success and (CurrentObjectName <> '') then
      begin
        PropName := Match.Groups[1].Value;
        PropValue := Match.Groups[2].Value;
        if IsUsefulPropertyValue(CurrentObjectName, PropName, PropValue) and
           (not GeneratedContainsPropertyValue(AGeneratedFmx, PropName, PropValue)) then
          FContext.AddIssue(csWarning,
            Format('DFM/FMXL property fidelity check: %s.%s value %s was not found in the generated FMX.',
              [CurrentObjectName, PropName, PropValue]),
            'DFM/FMXL property fidelity check',
            Trim(SourceLines[I]),
            'Review the generated form. If the text/caption still matters visually or at runtime, map it to the appropriate FMX property or child text control.',
            I + 1,
            False);
        Continue;
      end;

      Match := TRegEx.Match(SourceLines[I],
        '^\s*(On[A-Za-z0-9_]+)\s*=\s*([A-Za-z_][A-Za-z0-9_]*)\s*$',
        [roIgnoreCase]);
      if not Match.Success then
        Continue;

      EventName := Match.Groups[1].Value;
      HandlerName := Match.Groups[2].Value;
      ExpectedAssignment := EventName + ' = ' + HandlerName;

      if (Pos(ExpectedAssignment, AGeneratedFmx) = 0) and
         (not ContainsText(AGeneratedFmx, HandlerName)) then
        FContext.AddIssue(csWarning,
          Format('DFM/FMXL fidelity check: event handler %s.%s was present in the source DFM but was not emitted in the generated FMX.',
            [ExtractFileName(AFileName), ExpectedAssignment]),
          'DFM/FMXL fidelity check',
          Trim(SourceLines[I]),
          'Reconnect this event manually in the FMX designer or add a converter rule if this event is reusable across projects.',
          I + 1,
          False);
    end;
  finally
    SourceLines.Free;
  end;
end;
procedure TConverterEngine.ProcessDfmFile(const AFileName: string);
var
  Code: string;
  SourceDfm: string;
  EncodingName: string;
  ConvertedOK: Boolean;
begin
  UILog(Format('Processing DFM file: %s', [ExtractFileName(AFileName)]),
    Format('Processing DFM: %s', [ExtractFileName(AFileName)]));
  ConvertedOK := False;
  SourceDfm := '';
  EncodingName := '';
  FContext.CurrentFile := AFileName;

  if TFile.Exists(AFileName) and
     (TFile.GetSize(AFileName) > VCL2FMX_MAX_TEXT_DFM_BYTES) then
  begin
    Inc(FFilesErrors);
    UILog('  FAILED: DFM file is too large for safe automatic parsing');
    FContext.AddIssue(csError,
      'DFM file is too large for safe automatic parsing: ' +
        ExtractFileName(AFileName),
      'DFM size guard',
      '',
      'Open this DFM in Delphi and split or simplify the form before reconverting.',
      -1,
      True);
    Exit;
  end;

  Code := '';
  VCL2FMXTryReadTextFile(AFileName, SourceDfm, EncodingName);
  UILog('  Detecting DFM stream format...');
  try
    FOrchestrator.ConvertDFM(AFileName, Code);
    if Trim(Code) = '' then
      raise EConvertError.Create('DFM conversion returned empty output');
    AuditDfmFmxFidelity(AFileName, SourceDfm, Code);
    Inc(FFilesConverted);
    ConvertedOK := True;
    UILog('  Converted');
  except
    on E: Exception do
    begin
      Inc(FFilesErrors);
      UILog('  FAILED', Format('  FAILED: %s', [E.Message]));
      FContext.AddIssue(csError,
        'DFM conversion could not complete: ' + E.Message,
        'DFM conversion failure',
        '',
        'Open the source DFM, inspect the failing object or property, and rerun after correcting the blocker.',
        -1,
        True);
    end;
  end;

  if ConvertedOK then
  begin
    if not FFileManager.SaveConvertedFile(AFileName, Code) then
    begin
      Inc(FFilesErrors);
      UILog('  FAILED: Converted DFM file was not saved');
    end;
  end
  else
  begin
    UILog('  SKIPPED SAVE: DFM conversion did not produce safe output');
    FContext.AddIssue(csError,
      'DFM file was not saved because conversion did not complete safely: ' +
        ExtractFileName(AFileName),
      'DFM save skipped',
      '',
      'Review the earlier DFM conversion issue for this file before using any generated output.',
      -1,
      True);
  end;
end;

procedure TConverterEngine.GenerateReport;
var
  ReportFile: string;
  HtmlReportFile: string;
  Report: TStringList;
  Html: TStringList;
  Issue: TConversionIssue;
  InfoCount, WarnCount, ManualCount, ErrorCount, BlockingCount: Integer;
  DryRunPreviewCount: Integer;
  Duration: TDateTime;
  Secs: Integer;
  RunTimeText: string;
  ManualIndex: Integer;
  StatusText: string;
  NextStepText: string;
  SeenBlockingKeys: TStringList;
  ManualGroups: TStringList;
  AffectedFiles: TStringList;
  VisibleIssueCount: Integer;
  HasDetailedIssues: Boolean;
  HasBlockingOutcome: Boolean;

  procedure AddIndentedBlock(const Header, Text: string);
  var
    Block: TStringList;
    I: Integer;
  begin
    if Trim(Text) = '' then
      Exit;
    Report.Add(Header);
    Block := TStringList.Create;
    try
      Block.Text := StringReplace(Text, #13#10, sLineBreak, [rfReplaceAll]);
      for I := 0 to Block.Count - 1 do
        Report.Add('  ' + Block[I]);
    finally
      Block.Free;
    end;
  end;

  function IssueGroupKey(const AIssue: TConversionIssue): string;
  begin
    if SameText(AIssue.ProblemType, 'Mapping pack detection only') then
      Exit(IntToStr(Ord(AIssue.Severity)) + '|' +
        UpperCase(Trim(AIssue.ProblemType)) + '|' +
        BoolToStr(AIssue.IsBlocking, True));

    Result := IntToStr(Ord(AIssue.Severity)) + '|' +
      UpperCase(Trim(AIssue.ProblemType)) + '|' +
      UpperCase(Trim(AIssue.Message)) + '|' +
      UpperCase(Trim(AIssue.SuggestedFix)) + '|' +
      BoolToStr(AIssue.IsBlocking, True);
  end;

  function IsActionableInfo(const AIssue: TConversionIssue): Boolean;
  begin
    if AIssue.Severity <> csInfo then
      Exit(False);

    if SameText(AIssue.ProblemType, 'Dry-run preview') then
      Exit(False);

    Result := ((Trim(AIssue.ProblemType) <> '') or
       (Trim(AIssue.SuggestedFix) <> '') or
       AIssue.IsBlocking);
  end;

  function IsDryRunPreviewIssue(const AIssue: TConversionIssue): Boolean;
  begin
    Result := SameText(AIssue.ProblemType, 'Dry-run preview');
  end;
  function ShouldIncludeInDetailedIssues(const AIssue: TConversionIssue): Boolean;
  begin
    Result := (AIssue.Severity <> csManualReview) and
      ((AIssue.Severity <> csInfo) or IsActionableInfo(AIssue));
  end;

  procedure TrackAffectedFile(const AIssue: TConversionIssue);
  var
    FileKey: string;
  begin
    if Trim(AIssue.FileName) = '' then
      Exit;

    FileKey := UpperCase(Trim(AIssue.FileName));
    if AffectedFiles.IndexOf(FileKey) = -1 then
      AffectedFiles.Add(FileKey);
  end;

  function IssueRiskCategory(const AIssue: TConversionIssue): string;
  begin
    if AIssue.IsBlocking or (AIssue.Severity in [csError, csCritical]) then
      Exit('Compile or conversion blocker');

    if ContainsText(AIssue.ProblemType, 'Graphics') or
       ContainsText(AIssue.ProblemType, 'GDI') or
       ContainsText(AIssue.Message, 'Canvas') or
       ContainsText(AIssue.Message, 'drawing') then
      Exit('Visual review risk');

    if ContainsText(AIssue.ProblemType, 'Windows') or
       ContainsText(AIssue.ProblemType, 'message') or
       ContainsText(AIssue.Message, 'Windows') or
       ContainsText(AIssue.Message, 'message') then
      Exit('Runtime behavior risk');

    if ContainsText(AIssue.ProblemType, 'Data') or
       ContainsText(AIssue.ProblemType, 'LiveBindings') then
      Exit('Data binding review risk');

    if AIssue.Severity = csManualReview then
      Exit('Manual code review');
    if AIssue.Severity = csWarning then
      Exit('Warning review');

    Result := 'Information';
  end;

  function HasRiskCategory(const ARiskText: string): Boolean;
  var
    RiskIssue: TConversionIssue;
  begin
    Result := False;
    for RiskIssue in FContext.Issues do
      if SameText(IssueRiskCategory(RiskIssue), ARiskText) then
        Exit(True);
  end;

  function BuildNextStepText: string;
  begin
    if HasBlockingOutcome then
      Result := 'Open the report, resolve blocking items and file-level conversion failures first, then reopen the generated project in the IDE.'
    else if ManualCount > 0 then
      Result := 'Open the grouped manual-review section, inspect each affected file in the IDE, and apply the required FMX decisions before relying on the output.'
    else if VisibleIssueCount > 0 then
      Result := 'Open the report for a quick sanity check, review the remaining warnings, and then compile the generated project in the IDE.'
    else
      Result := 'Open the report for a final sanity check, then compile and smoke-test the generated project in the IDE.';
  end;

  procedure AddManualIssueToGroup(const AIssue: TConversionIssue);
  var
    Key: string;
    Index: Integer;
    GroupItems: TList<TConversionIssue>;
  begin
    Key := IssueGroupKey(AIssue);
    Index := ManualGroups.IndexOf(Key);
    if Index = -1 then
    begin
      GroupItems := TList<TConversionIssue>.Create;
      ManualGroups.AddObject(Key, GroupItems);
    end
    else
      GroupItems := TList<TConversionIssue>(ManualGroups.Objects[Index]);

    GroupItems.Add(AIssue);
  end;

  function BuildOccurrenceText(const AIssues: TList<TConversionIssue>): string;
  var
    GroupIssue: TConversionIssue;
    Occurrences: TStringList;
    Occurrence: string;
    LastFile: string;
    FirstCode: string;
    StartLine: Integer;
    EndLine: Integer;
    BlockLineCount: Integer;
    HasBlock: Boolean;

    function UsesCollapsedLineRanges: Boolean;
    begin
      Result := False;
    end;

    procedure FlushBlock;
    begin
      if not HasBlock then
        Exit;

      if StartLine = EndLine then
        Occurrence := Format('%s:%d', [LastFile, StartLine])
      else
        Occurrence := Format('%s:%d-%d (%d lines)',
          [LastFile, StartLine, EndLine, BlockLineCount]);

      if Trim(FirstCode) <> '' then
        Occurrence := Occurrence + ' -> ' + Trim(FirstCode);

      if Occurrences.IndexOf(Occurrence) = -1 then
        Occurrences.Add(Occurrence);

      HasBlock := False;
      LastFile := '';
      FirstCode := '';
      StartLine := -1;
      EndLine := -1;
      BlockLineCount := 0;
    end;
  begin
    Result := '';
    Occurrences := TStringList.Create;
    try
      if UsesCollapsedLineRanges then
      begin
        HasBlock := False;
        LastFile := '';
        FirstCode := '';
        StartLine := -1;
        EndLine := -1;
        BlockLineCount := 0;

        for GroupIssue in AIssues do
        begin
          if (Trim(GroupIssue.FileName) = '') or
             (GroupIssue.LineNumber <= 0) or
             (Trim(GroupIssue.OriginalCode) = '') then
            Continue;

          if HasBlock and SameText(GroupIssue.FileName, LastFile) and
             (GroupIssue.LineNumber <= EndLine + 1) then
          begin
            EndLine := Max(EndLine, GroupIssue.LineNumber);
            Inc(BlockLineCount);
            Continue;
          end;

          FlushBlock;
          HasBlock := True;
          LastFile := GroupIssue.FileName;
          FirstCode := GroupIssue.OriginalCode;
          StartLine := GroupIssue.LineNumber;
          EndLine := GroupIssue.LineNumber;
          BlockLineCount := 1;
        end;

        FlushBlock;
      end
      else
      begin
        for GroupIssue in AIssues do
        begin
          Occurrence := '';
          if GroupIssue.FileName <> '' then
            Occurrence := GroupIssue.FileName;
          if GroupIssue.LineNumber > 0 then
            Occurrence := Occurrence + ':' + IntToStr(GroupIssue.LineNumber);
          if Trim(GroupIssue.OriginalCode) <> '' then
            Occurrence := Occurrence + ' -> ' + Trim(GroupIssue.OriginalCode);
          if Occurrence = '' then
            Occurrence := GroupIssue.Message;

          if Occurrences.IndexOf(Occurrence) = -1 then
            Occurrences.Add(Occurrence);
        end;
      end;

      Result := TrimRight(Occurrences.Text);
    finally
      Occurrences.Free;
    end;
  end;

  function ManualOccurrenceCount(const AIssues: TList<TConversionIssue>): Integer;
  var
    OccurrenceText: string;
    Occurrences: TStringList;
  begin
    OccurrenceText := BuildOccurrenceText(AIssues);
    if Trim(OccurrenceText) = '' then
      Exit(0);

    Occurrences := TStringList.Create;
    try
      Occurrences.Text := OccurrenceText;
      Result := Occurrences.Count;
    finally
      Occurrences.Free;
    end;
  end;

  function ManualAffectedLineCount(const AIssues: TList<TConversionIssue>): Integer;
  var
    GroupIssue: TConversionIssue;
    LinesSeen: TStringList;
    Key: string;
  begin
    Result := 0;
    if (AIssues.Count = 0) or
       not SameText(AIssues[0].ProblemType, 'Windows messages or message handlers') then
      Exit;

    LinesSeen := TStringList.Create;
    try
      for GroupIssue in AIssues do
      begin
        if (Trim(GroupIssue.FileName) = '') or
           (GroupIssue.LineNumber <= 0) or
           (Trim(GroupIssue.OriginalCode) = '') then
          Continue;

        Key := UpperCase(Trim(GroupIssue.FileName)) + ':' + IntToStr(GroupIssue.LineNumber);
        if LinesSeen.IndexOf(Key) = -1 then
          LinesSeen.Add(Key);
      end;
      Result := LinesSeen.Count;
    finally
      LinesSeen.Free;
    end;
  end;

  function BuildManualDetailText(const AIssues: TList<TConversionIssue>): string;
  var
    FirstIssue: TConversionIssue;
  begin
    if AIssues.Count = 0 then
      Exit('');

    FirstIssue := AIssues[0];
    if SameText(FirstIssue.ProblemType, 'Mapping pack detection only') and
       (AIssues.Count > 1) then
      Result := Format('%d mapping-pack detect-only components were found; no FMX replacements were generated.',
        [AIssues.Count])
    else
      Result := FirstIssue.Message;
  end;

  function BuildSuggestedFixText(const AIssues: TList<TConversionIssue>): string;
  var
    GroupIssue: TConversionIssue;
    Fixes: TStringList;
  begin
    Result := '';
    Fixes := TStringList.Create;
    try
      for GroupIssue in AIssues do
        if (Trim(GroupIssue.SuggestedFix) <> '') and
           (Fixes.IndexOf(Trim(GroupIssue.SuggestedFix)) = -1) then
          Fixes.Add(Trim(GroupIssue.SuggestedFix));

      Result := TrimRight(Fixes.Text);
    finally
      Fixes.Free;
    end;

    if Result = '' then
      Result := 'Review this item in the IDE, choose the closest FMX equivalent, and apply manual fixes before relying on the generated output.';
  end;

  procedure FreeManualGroups;
  var
    I: Integer;
  begin
    for I := 0 to ManualGroups.Count - 1 do
      ManualGroups.Objects[I].Free;
  end;

  function HtmlEncode(const Value: string): string;
  begin
    Result := TNetEncoding.HTML.Encode(Value);
  end;

  function SeverityCssClass(Severity: TConversionSeverity): string;
  begin
    case Severity of
      csInfo: Result := 'info';
      csWarning: Result := 'warning';
      csManualReview: Result := 'manual';
      csError, csCritical: Result := 'error';
    else
      Result := 'neutral';
    end;
  end;

  function UsageTargetText(const Usage: TMappingPackUsage): string;
  begin
    if Trim(Usage.FMXClassName) <> '' then
      Result := Usage.FMXClassName
    else
      Result := 'No FMX output generated';
  end;

  function UsageLocationText(const Usage: TMappingPackUsage): string;
  begin
    Result := Usage.SourceFile;
    if Usage.LineNumber > 0 then
      Result := Result + ':' + IntToStr(Usage.LineNumber);
  end;

  function FormatRunTime(Seconds: Integer): string;
  var
    Minutes: Integer;
    RemainingSeconds: Integer;
  begin
    if (Seconds = 0) and ((FFilesProcessed > 0) or (FFilesConverted > 0)) then
      Exit('< 1 second');

    Minutes := Seconds div 60;
    RemainingSeconds := Seconds mod 60;

    if Minutes > 0 then
    begin
      if RemainingSeconds = 0 then
        Result := Format('%d min', [Minutes])
      else
        Result := Format('%d min %d sec', [Minutes, RemainingSeconds]);
    end
    else if Seconds = 1 then
      Result := '1 sec'
    else
      Result := Format('%d sec', [Seconds]);
  end;

  procedure AddUsageTextSection(const Title, EmptyText: string;
    const ActionFilter: string; GeneratedOnly: Boolean; DetectOnly: Boolean);
  var
    Usage: TMappingPackUsage;
    Index: Integer;
    IncludeUsage: Boolean;
  begin
    Report.Add('');
    Report.Add(Title);
    Report.Add(StringOfChar('-', 40));
    Index := 0;
    for Usage in FContext.MappingPackUsages do
    begin
      IncludeUsage := True;
      if ActionFilter <> '' then
        IncludeUsage := SameText(Usage.Action, ActionFilter);
      if GeneratedOnly then
        IncludeUsage := IncludeUsage and Usage.GeneratedOutput;
      if DetectOnly then
        IncludeUsage := IncludeUsage and SameText(Usage.Action, 'detect_only');

      if not IncludeUsage then
        Continue;

      Inc(Index);
      Report.Add(Format('%d. %s: %s -> %s',
        [Index, Usage.ComponentName, Usage.VCLClassName,
         UsageTargetText(Usage)]));
      Report.Add(Format('   Action: %s  Confidence: %d%%',
        [Usage.Action, Usage.Confidence]));
      if Trim(Usage.PackName) <> '' then
        Report.Add('   Pack: ' + Usage.PackName);
      if Trim(Usage.Vendor) <> '' then
        Report.Add('   Vendor: ' + Usage.Vendor);
      if Trim(UsageLocationText(Usage)) <> '' then
        Report.Add('   Location: ' + UsageLocationText(Usage));
      if Trim(Usage.Notes) <> '' then
        Report.Add('   Notes: ' + Usage.Notes);
    end;

    if Index = 0 then
      Report.Add(EmptyText);
  end;

  procedure AddUsageHtmlSection(const Title, Note, EmptyText: string;
    const ActionFilter: string; GeneratedOnly: Boolean; DetectOnly: Boolean);
  var
    Usage: TMappingPackUsage;
    AddedAny: Boolean;
    IncludeUsage: Boolean;
  begin
    AddedAny := False;
    for Usage in FContext.MappingPackUsages do
    begin
      IncludeUsage := True;
      if ActionFilter <> '' then
        IncludeUsage := SameText(Usage.Action, ActionFilter);
      if GeneratedOnly then
        IncludeUsage := IncludeUsage and Usage.GeneratedOutput;
      if DetectOnly then
        IncludeUsage := IncludeUsage and SameText(Usage.Action, 'detect_only');
      if IncludeUsage then
      begin
        AddedAny := True;
        Break;
      end;
    end;
    if not AddedAny then
      Exit;

    Html.Add('    <div class="section">');
    Html.Add('      <h2>' + HtmlEncode(Title) + '</h2>');
    Html.Add('      <p class="section-note">' + HtmlEncode(Note) + '</p>');
    Html.Add('      <div class="usage-list">');
    AddedAny := False;
    for Usage in FContext.MappingPackUsages do
    begin
      IncludeUsage := True;
      if ActionFilter <> '' then
        IncludeUsage := SameText(Usage.Action, ActionFilter);
      if GeneratedOnly then
        IncludeUsage := IncludeUsage and Usage.GeneratedOutput;
      if DetectOnly then
        IncludeUsage := IncludeUsage and SameText(Usage.Action, 'detect_only');

      if not IncludeUsage then
        Continue;

      AddedAny := True;
      Html.Add('        <div class="usage-card">');
      Html.Add('          <div class="usage-title">' + HtmlEncode(Usage.ComponentName) +
        '<span>' + HtmlEncode(Usage.Action) + ' | ' + IntToStr(Usage.Confidence) + '%</span></div>');
      Html.Add('          <div class="usage-map">' + HtmlEncode(Usage.VCLClassName) +
        ' -> ' + HtmlEncode(UsageTargetText(Usage)) + '</div>');
      Html.Add('          <div class="usage-meta">');
      if Trim(Usage.PackName) <> '' then
        Html.Add('            <span>Pack: ' + HtmlEncode(Usage.PackName) + '</span>');
      if Trim(Usage.Vendor) <> '' then
        Html.Add('            <span>Vendor: ' + HtmlEncode(Usage.Vendor) + '</span>');
      Html.Add('          </div>');
      if Trim(UsageLocationText(Usage)) <> '' then
        Html.Add('          <div class="usage-path">' + HtmlEncode(UsageLocationText(Usage)) + '</div>');
      if Trim(Usage.Notes) <> '' then
        Html.Add('          <div class="usage-notes">' + HtmlEncode(Usage.Notes) + '</div>');
      Html.Add('        </div>');
    end;

    if not AddedAny then
      Html.Add('        <div class="empty-state">' + HtmlEncode(EmptyText) + '</div>');

    Html.Add('      </div>');
    Html.Add('    </div>');
  end;

  procedure AddMappingsUsedTextSection;
  var
    Usage: TMappingPackUsage;
    Index: Integer;
  begin
    Report.Add('');
    Report.Add('MAPPINGS USED');
    Report.Add(StringOfChar('-', 40));
    Index := 0;
    for Usage in FContext.MappingPackUsages do
    begin
      Inc(Index);
      Report.Add(Format('%d. %s: %s -> %s (%s, %d%%)',
        [Index, Usage.ComponentName, Usage.VCLClassName,
         UsageTargetText(Usage), Usage.Action, Usage.Confidence]));
    end;
    if Index = 0 then
      Report.Add('No mapping-pack rules were used during this run.');
  end;

  procedure AddMappingsUsedHtmlSection;
  var
    Usage: TMappingPackUsage;
    AddedAny: Boolean;
  begin
    if FContext.MappingPackUsages.Count = 0 then
      Exit;

    Html.Add('    <div class="section">');    Html.Add('      <h2>Mappings used</h2>');
    Html.Add('      <p class="section-note">Compact list of mapping-pack rules that fired during this conversion run.</p>');
    Html.Add('      <div class="compact-list">');
    AddedAny := False;
    for Usage in FContext.MappingPackUsages do
    begin
      AddedAny := True;
      Html.Add('        <div>' +
        HtmlEncode(Format('%s: %s -> %s (%s, %d%%)',
          [Usage.ComponentName, Usage.VCLClassName, UsageTargetText(Usage),
           Usage.Action, Usage.Confidence])) + '</div>');
    end;
    if not AddedAny then
      Html.Add('        <div>No mapping-pack rules were used during this run.</div>');
    Html.Add('      </div>');
    Html.Add('    </div>');
  end;
begin
  ReportFile := TPath.Combine(FContext.Options.OutputPath, 'VCL_to_FMX_Conversion_Report.txt');
  HtmlReportFile := TPath.Combine(FContext.Options.OutputPath, 'VCL_to_FMX_Conversion_Report.html');
  Report := TStringList.Create;
  Html := TStringList.Create;
  SeenBlockingKeys := TStringList.Create;
  ManualGroups := TStringList.Create;
  AffectedFiles := TStringList.Create;
  try
    SeenBlockingKeys.Sorted := True;
    SeenBlockingKeys.Duplicates := dupIgnore;
    AffectedFiles.Sorted := True;
    AffectedFiles.Duplicates := dupIgnore;

    Duration := FEndTime - FStartTime;
    Secs := Round(Duration * 24 * 60 * 60);
    RunTimeText := FormatRunTime(Secs);

    Report.Add('');
    Report.Add(StringOfChar('=', 50));
    Report.Add('CONVERSION SUMMARY');
    Report.Add(StringOfChar('=', 50));
    Report.Add('');
    Report.Add('Total time: ' + RunTimeText);
    Report.Add(Format('Files processed: %d', [FFilesProcessed]));
    Report.Add(Format('Files converted: %d', [FFilesConverted]));
    Report.Add(Format('Files with errors: %d', [FFilesErrors]));
    Report.Add(Format('Files skipped: %d', [FFilesSkipped]));
    Report.Add(Format('Mapping packs loaded: %d', [FContext.LoadedMappingPacks.Count]));
    Report.Add('');
    Report.Add('OUTPUT FILES');
    Report.Add(StringOfChar('-', 40));
    Report.Add('Output folder: ' + FContext.Options.OutputPath);
    Report.Add('Text report: ' + ReportFile);
    Report.Add('HTML report: ' + HtmlReportFile);
    Report.Add('Converted Pascal files are written beside converted source names in the output folder.');
    Report.Add('Converted FMX files are written beside converted source names in the output folder.');

    Report.Add('');
    InfoCount := 0;
    WarnCount := 0;
    ManualCount := 0;
    ErrorCount := 0;
    BlockingCount := 0;
    DryRunPreviewCount := 0;

    for Issue in FContext.Issues do
    begin
      if IsDryRunPreviewIssue(Issue) then
        Inc(DryRunPreviewCount);

      case Issue.Severity of
        csInfo:
          if IsActionableInfo(Issue) then
            Inc(InfoCount);
        csWarning: Inc(WarnCount);
        csManualReview:
          AddManualIssueToGroup(Issue);
        csError, csCritical: Inc(ErrorCount);
      end;

      if (Issue.Severity = csManualReview) or ShouldIncludeInDetailedIssues(Issue) then
        TrackAffectedFile(Issue);

      if Issue.IsBlocking or (Issue.Severity in [csError, csCritical]) then
        if SeenBlockingKeys.IndexOf(IssueGroupKey(Issue)) = -1 then
        begin
          SeenBlockingKeys.Add(IssueGroupKey(Issue));
          Inc(BlockingCount);
        end;
    end;

    ManualCount := ManualGroups.Count;

    VisibleIssueCount := WarnCount + ManualCount + ErrorCount;
    HasBlockingOutcome := (FFilesErrors > 0) or (BlockingCount > 0);
    NextStepText := BuildNextStepText;

    Report.Add(Format('Total issues: %d', [VisibleIssueCount]));
    if InfoCount > 0 then
      Report.Add(Format('Informational notices: %d', [InfoCount]));
    if DryRunPreviewCount > 0 then
      Report.Add(Format('Dry-run preview notices: %d', [DryRunPreviewCount]));
    Report.Add(Format('Distinct files needing attention: %d', [AffectedFiles.Count]));

    if HasBlockingOutcome then
      StatusText := 'Blocking issues present'
    else if ManualCount > 0 then
      StatusText := 'Manual review required'
    else
      StatusText := 'Clean conversion';

    Report.Add(Format('Final status: %s', [StatusText]));
    Report.Add(Format('Manual fixes required: %d', [ManualCount]));
    Report.Add(Format('Blocking items: %d', [BlockingCount]));
    Report.Add(Format('Files with conversion errors: %d', [FFilesErrors]));
    Report.Add('Recommended next step: ' + NextStepText);
    Report.Add('');
    Report.Add('Review note: Generated output should be reviewed in the IDE. Projects with manual-review or blocking items may not run until those items are fixed or mitigated.');

    Report.Add('');
    Report.Add('CONVERSION HEALTH');
    Report.Add(StringOfChar('-', 40));
    if HasBlockingOutcome then
      Report.Add('Compile readiness: blocked until conversion errors or blocking items are resolved.')
    else if ManualCount > 0 then
      Report.Add('Compile readiness: possible, but manual-review items may still block reliable behavior.')
    else
      Report.Add('Compile readiness: no blocking or manual-review categories were detected by the converter.');
    Report.Add('Runtime behavior review: ' + IfThen(HasRiskCategory('Runtime behavior risk'), 'Yes', 'No'));
    Report.Add('Visual review: ' + IfThen(HasRiskCategory('Visual review risk'), 'Yes', 'No'));
    Report.Add('Data binding review: ' + IfThen(HasRiskCategory('Data binding review risk'), 'Yes', 'No'));
    Report.Add('Manual code review: ' + IfThen(ManualCount > 0, 'Yes', 'No'));

    Report.Add('');
    Report.Add('MAPPING PACKS LOADED');
    Report.Add(StringOfChar('-', 40));
    if FContext.LoadedMappingPacks.Count = 0 then
      Report.Add('No mapping packs were loaded for this run.')
    else
      for ManualIndex := 0 to FContext.LoadedMappingPacks.Count - 1 do
        Report.Add(Format('%d. %s', [ManualIndex + 1,
          FContext.LoadedMappingPacks[ManualIndex]]));

    AddUsageTextSection('THIRD-PARTY COMPONENTS CONVERTED',
      'No third-party mapping-pack components were fully converted.',
      'convert', True, False);
    AddUsageTextSection('THIRD-PARTY COMPONENTS PARTIALLY CONVERTED',
      'No third-party mapping-pack components were partially converted.',
      'partial', True, False);
    AddUsageTextSection('THIRD-PARTY COMPONENTS DETECTED ONLY',
      'No detect-only third-party mapping-pack components were found.',
      'detect_only', False, True);
    AddMappingsUsedTextSection;

    Report.Add('');
    Report.Add('UNKNOWN THIRD-PARTY COMPONENTS');
    Report.Add(StringOfChar('-', 40));
    Report.Add('None detected.');

    if DryRunPreviewCount > 0 then
    begin
      Report.Add('');
      Report.Add('DRY-RUN PREVIEW');
      Report.Add(StringOfChar('-', 40));
      Report.Add('Preview mode did not write converted source, form, or project files. These notices are not counted as conversion issues.');
      for Issue in FContext.Issues do
        if IsDryRunPreviewIssue(Issue) then
          Report.Add('- ' + Issue.Message);
    end;
    Report.Add('');
    Report.Add('DETAILED ISSUES');
    Report.Add(StringOfChar('-', 40));

    for Issue in FContext.Issues do
    begin
      if not ShouldIncludeInDetailedIssues(Issue) then
        Continue;
      Report.Add(Format('[%s] %s', [SeverityToString(Issue.Severity), Issue.Message]));
      if Issue.FileName <> '' then
        Report.Add('  File: ' + Issue.FileName);
      if Issue.LineNumber > 0 then
        Report.Add('  Line: ' + IntToStr(Issue.LineNumber));
      if Issue.IsBlocking then
        Report.Add('  Blocking: Yes');
      if Issue.ProblemType <> '' then
        Report.Add('  Problem type: ' + Issue.ProblemType);
      Report.Add('  Risk category: ' + IssueRiskCategory(Issue));
      if Trim(Issue.OriginalCode) <> '' then
        Report.Add('  Original: ' + StringReplace(Trim(Issue.OriginalCode), sLineBreak, ' | ', [rfReplaceAll]));
      if Issue.SuggestedFix <> '' then
        Report.Add('  Recommendation: ' + Issue.SuggestedFix);
      Report.Add('');
    end;

    if ManualCount > 0 then
    begin
      Report.Add('MANUAL REVIEW ITEMS');
      Report.Add(StringOfChar('-', 40));
      Report.Add('');
      for ManualIndex := 0 to ManualGroups.Count - 1 do
      begin
        Issue := TList<TConversionIssue>(ManualGroups.Objects[ManualIndex])[0];
        Report.Add(Format('%d. %s', [ManualIndex + 1,
          IfThen(Issue.ProblemType <> '', Issue.ProblemType, 'Manual review required')]));
        if Issue.IsBlocking then
          Report.Add('Blocking: Yes');
        Report.Add('Risk category: ' + IssueRiskCategory(Issue));
        Report.Add('Occurrences: ' + IntToStr(ManualOccurrenceCount(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex]))));
        if ManualAffectedLineCount(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex])) >
           ManualOccurrenceCount(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex])) then
          Report.Add('Affected lines: ' + IntToStr(ManualAffectedLineCount(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex]))));
        Report.Add('Detail: ' + BuildManualDetailText(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex])));
        AddIndentedBlock('Affected locations:', BuildOccurrenceText(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex])));
        AddIndentedBlock('Recommended solution:', BuildSuggestedFixText(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex])));
        Report.Add('');
      end;
    end;

    Report.Add('');
    Report.Add('ISSUE SUMMARY');
    Report.Add(StringOfChar('-', 30));
    Report.Add(Format('Informational: %d', [InfoCount]));
    Report.Add(Format('Warnings: %d', [WarnCount]));
    Report.Add(Format('Manual review required: %d', [ManualCount]));
    Report.Add(Format('Errors: %d', [ErrorCount]));
    Report.Add(Format('Blocking items: %d', [BlockingCount]));

    if FConversionLog.Count > 0 then
    begin
      Report.Add('');
      Report.Add('CONVERSION LOG');
      Report.Add(StringOfChar('-', 80));
      Report.AddStrings(FConversionLog);
    end;

    Report.SaveToFile(ReportFile, TEncoding.UTF8);

    UILog(Format('Report saved to: %s', [ReportFile]));

    Html.Add('<!DOCTYPE html>');
    Html.Add('<html lang="en">');
    Html.Add('<head>');
    Html.Add('  <meta charset="utf-8">');
    Html.Add('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    Html.Add('  <title>VCL to FMX Conversion Report</title>');
    Html.Add('  <style>');
    Html.Add('    :root {');
    Html.Add('      color-scheme: light;');
    Html.Add('      --page-bg: #eef5fd;');
    Html.Add('      --card-bg: #ffffff;');
    Html.Add('      --hero-a: #2f6fcd;');
    Html.Add('      --hero-b: #5d95e2;');
    Html.Add('      --text: #13314f;');
    Html.Add('      --muted: #58708d;');
    Html.Add('      --line: #d6e4f3;');
    Html.Add('      --info: #2f6fcd;');
    Html.Add('      --warning: #c98a19;');
    Html.Add('      --manual: #b25f2c;');
    Html.Add('      --error: #c24141;');
    Html.Add('    }');
    Html.Add('    * { box-sizing: border-box; }');
    Html.Add('    body {');
    Html.Add('      margin: 0;');
    Html.Add('      padding: 24px;');
    Html.Add('      font-family: "Segoe UI", Tahoma, sans-serif;');
    Html.Add('      color: var(--text);');
    Html.Add('      background: linear-gradient(180deg, #f6faff 0%, var(--page-bg) 100%);');
    Html.Add('    }');
    Html.Add('    .page {');
    Html.Add('      max-width: 1180px;');
    Html.Add('      margin: 0 auto;');
    Html.Add('    }');
    Html.Add('    .hero {');
    Html.Add('      border-radius: 24px;');
    Html.Add('      padding: 28px 32px;');
    Html.Add('      color: #ffffff;');
    Html.Add('      background: linear-gradient(135deg, var(--hero-a) 0%, var(--hero-b) 100%);');
    Html.Add('      box-shadow: 0 20px 40px rgba(30, 72, 123, 0.15);');
    Html.Add('    }');
    Html.Add('    .eyebrow {');
    Html.Add('      font-size: 12px;');
    Html.Add('      text-transform: uppercase;');
    Html.Add('      letter-spacing: 0.12em;');
    Html.Add('      opacity: 0.8;');
    Html.Add('    }');
    Html.Add('    h1 {');
    Html.Add('      margin: 10px 0 8px;');
    Html.Add('      font-size: 34px;');
    Html.Add('      line-height: 1.15;');
    Html.Add('    }');
    Html.Add('    .hero p {');
    Html.Add('      margin: 0;');
    Html.Add('      max-width: 900px;');
    Html.Add('      color: rgba(255,255,255,0.92);');
    Html.Add('    }');
    Html.Add('    .status-chip {');
    Html.Add('      display: inline-block;');
    Html.Add('      margin-top: 18px;');
    Html.Add('      padding: 8px 14px;');
    Html.Add('      border-radius: 999px;');
    Html.Add('      background: rgba(255,255,255,0.18);');
    Html.Add('      font-weight: 600;');
    Html.Add('    }');
    Html.Add('    .meta {');
    Html.Add('      display: grid;');
    Html.Add('      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));');
    Html.Add('      gap: 14px;');
    Html.Add('      margin-top: 16px;');
    Html.Add('    }');
    Html.Add('    .meta-card, .section, .manual-card {');
    Html.Add('      background: var(--card-bg);');
    Html.Add('      border: 1px solid var(--line);');
    Html.Add('      border-radius: 20px;');
    Html.Add('      box-shadow: 0 12px 28px rgba(17, 49, 79, 0.06);');
    Html.Add('    }');
    Html.Add('    .meta-card {');
    Html.Add('      padding: 16px 18px;');
    Html.Add('    }');
    Html.Add('    .meta-card .label {');
    Html.Add('      font-size: 12px;');
    Html.Add('      color: var(--muted);');
    Html.Add('      text-transform: uppercase;');
    Html.Add('      letter-spacing: 0.08em;');
    Html.Add('    }');
    Html.Add('    .meta-card .value {');
    Html.Add('      margin-top: 8px;');
    Html.Add('      font-size: 25px;');
    Html.Add('      font-weight: 700;');
    Html.Add('    }');
    Html.Add('    .section {');
    Html.Add('      margin-top: 16px;');
    Html.Add('      padding: 18px 22px;');
    Html.Add('    }');
    Html.Add('    .section h2 {');
    Html.Add('      margin: 0 0 8px;');
    Html.Add('      font-size: 22px;');
    Html.Add('    }');
    Html.Add('    .section p.section-note {');
    Html.Add('      margin: 0 0 14px;');
    Html.Add('      color: var(--muted);');
    Html.Add('    }');
    Html.Add('    details.disclosure > summary {');
    Html.Add('      cursor: pointer;');
    Html.Add('      list-style: none;');
    Html.Add('      display: flex;');
    Html.Add('      align-items: baseline;');
    Html.Add('      justify-content: space-between;');
    Html.Add('      gap: 12px;');
    Html.Add('    }');
    Html.Add('    details.disclosure > summary::-webkit-details-marker { display: none; }');
    Html.Add('    details.disclosure > summary h2 { margin: 0; }');
    Html.Add('    details.disclosure > summary span { color: var(--muted); font-size: 13px; font-weight: 600; }');
    Html.Add('    details.disclosure[open] > summary { margin-bottom: 14px; }');
    Html.Add('    table {');
    Html.Add('      width: 100%;');
    Html.Add('      border-collapse: collapse;');
    Html.Add('    }');
    Html.Add('    th, td {');
    Html.Add('      padding: 12px 10px;');
    Html.Add('      text-align: left;');
    Html.Add('      vertical-align: top;');
    Html.Add('      border-top: 1px solid var(--line);');
    Html.Add('      font-size: 14px;');
    Html.Add('      overflow-wrap: anywhere;');
    Html.Add('    }');
    Html.Add('    th.row-index {');
    Html.Add('      width: 42px;');
    Html.Add('      min-width: 42px;');
    Html.Add('      white-space: nowrap;');
    Html.Add('      text-align: right;');
    Html.Add('      overflow-wrap: normal;');
    Html.Add('      word-break: normal;');
    Html.Add('    }');
    Html.Add('    th {');
    Html.Add('      font-size: 12px;');
    Html.Add('      text-transform: uppercase;');
    Html.Add('      letter-spacing: 0.08em;');
    Html.Add('      color: var(--muted);');
    Html.Add('      border-top: none;');
    Html.Add('      padding-top: 0;');
    Html.Add('    }');
    Html.Add('    .severity {');
      Html.Add('      display: inline-block;');
    Html.Add('      min-width: 76px;');
    Html.Add('      padding: 5px 10px;');
    Html.Add('      border-radius: 999px;');
    Html.Add('      font-size: 11px;');
    Html.Add('      font-weight: 700;');
    Html.Add('      color: #ffffff;');
    Html.Add('      text-align: center;');
    Html.Add('      white-space: nowrap;');
    Html.Add('    }');
    Html.Add('    .issues-table th:first-child, .issues-table td:first-child {');
    Html.Add('      width: 100px;');
    Html.Add('      min-width: 100px;');
    Html.Add('    }');
    Html.Add('    .severity.info { background: var(--info); }');
    Html.Add('    .severity.warning { background: var(--warning); }');
    Html.Add('    .severity.manual { background: var(--manual); }');
    Html.Add('    .severity.error { background: var(--error); }');
    Html.Add('    .severity.neutral { background: #7a8ea7; }');
    Html.Add('    .issue-list {');
    Html.Add('      display: grid;');
    Html.Add('      gap: 10px;');
    Html.Add('    }');
    Html.Add('    .issue-card {');
    Html.Add('      border-top: 1px solid var(--line);');
    Html.Add('      padding: 12px 0 10px;');
    Html.Add('    }');
    Html.Add('    .issue-card:first-child { border-top: none; padding-top: 0; }');
    Html.Add('    .issue-card-header {');
    Html.Add('      display: flex;');
    Html.Add('      flex-wrap: wrap;');
    Html.Add('      gap: 10px;');
    Html.Add('      align-items: center;');
    Html.Add('      margin-bottom: 8px;');
    Html.Add('    }');
    Html.Add('    .issue-card-header strong { font-size: 14px; }');
    Html.Add('    .issue-card-header span.meta { color: var(--muted); font-size: 12px; font-weight: 600; }');
    Html.Add('    .issue-message { line-height: 1.35; max-width: 920px; }');
    Html.Add('    .issue-path {');
    Html.Add('      margin-top: 8px;');
    Html.Add('      color: var(--muted);');
    Html.Add('      font-family: "Consolas", "Courier New", monospace;');
    Html.Add('      font-size: 12px;');
    Html.Add('      overflow-wrap: anywhere;');
    Html.Add('    }');
    Html.Add('    .issue-fix { margin-top: 8px; color: var(--muted); line-height: 1.35; }');
    Html.Add('    .manual-list {');
    Html.Add('      display: grid;');
    Html.Add('      gap: 12px;');
    Html.Add('    }');
    Html.Add('    .manual-card {');
    Html.Add('      padding: 14px 18px;');
    Html.Add('    }');
    Html.Add('    .manual-card h3 {');
    Html.Add('      margin: 0 0 10px;');
    Html.Add('      font-size: 18px;');
    Html.Add('    }');
    Html.Add('    .usage-list {');
    Html.Add('      display: grid;');
    Html.Add('      gap: 12px;');
    Html.Add('    }');
    Html.Add('    .usage-card {');
    Html.Add('      border-top: 1px solid var(--line);');
    Html.Add('      padding: 14px 0 16px;');
    Html.Add('    }');
    Html.Add('    .usage-card:first-child { border-top: none; padding-top: 0; }');
    Html.Add('    .usage-title {');
    Html.Add('      display: flex;');
    Html.Add('      flex-wrap: wrap;');
    Html.Add('      gap: 10px;');
    Html.Add('      align-items: baseline;');
    Html.Add('      justify-content: space-between;');
    Html.Add('      font-weight: 700;');
    Html.Add('      font-size: 15px;');
    Html.Add('    }');
    Html.Add('    .usage-title span {');
    Html.Add('      color: var(--muted);');
    Html.Add('      font-size: 13px;');
    Html.Add('      font-weight: 600;');
    Html.Add('    }');
    Html.Add('    .usage-map {');
    Html.Add('      margin-top: 6px;');
    Html.Add('      font-family: "Consolas", "Courier New", monospace;');
    Html.Add('      font-size: 13px;');
    Html.Add('    }');
    Html.Add('    .usage-meta {');
    Html.Add('      display: flex;');
    Html.Add('      flex-wrap: wrap;');
    Html.Add('      gap: 12px;');
    Html.Add('      margin-top: 8px;');
    Html.Add('      color: var(--muted);');
    Html.Add('      font-size: 13px;');
    Html.Add('    }');
    Html.Add('    .usage-path {');
    Html.Add('      margin-top: 10px;');
    Html.Add('      padding: 9px 10px;');
    Html.Add('      border-radius: 8px;');
    Html.Add('      background: #f7fbff;');
    Html.Add('      border: 1px solid #e4eef8;');
    Html.Add('      font-family: "Consolas", "Courier New", monospace;');
    Html.Add('      font-size: 12px;');
    Html.Add('      overflow-wrap: anywhere;');
    Html.Add('    }');
    Html.Add('    .usage-notes {');
    Html.Add('      margin-top: 10px;');
    Html.Add('      color: var(--muted);');
    Html.Add('      line-height: 1.35;');
    Html.Add('    }');
    Html.Add('    .compact-list {');
    Html.Add('      display: grid;');
    Html.Add('      gap: 8px;');
    Html.Add('      font-family: "Consolas", "Courier New", monospace;');
    Html.Add('      font-size: 13px;');
    Html.Add('    }');
    Html.Add('    .compact-list div {');
    Html.Add('      padding-top: 8px;');
    Html.Add('      border-top: 1px solid var(--line);');
    Html.Add('      overflow-wrap: anywhere;');
    Html.Add('    }');
    Html.Add('    .compact-list div:first-child { border-top: none; padding-top: 0; }');
    Html.Add('    .mapping-pack-list {');
    Html.Add('      border-top: 1px solid var(--line);');
    Html.Add('    }');
    Html.Add('    .mapping-pack-row {');
    Html.Add('      display: grid;');
    Html.Add('      grid-template-columns: 48px minmax(0, 1fr);');
    Html.Add('      column-gap: 12px;');
    Html.Add('      align-items: start;');
    Html.Add('      padding: 12px 0;');
    Html.Add('      border-bottom: 1px solid var(--line);');
    Html.Add('    }');
    Html.Add('    .mapping-pack-index {');
    Html.Add('      color: var(--muted);');
    Html.Add('      font-weight: 700;');
    Html.Add('      text-align: right;');
    Html.Add('      white-space: nowrap;');
    Html.Add('      overflow-wrap: normal;');
    Html.Add('      word-break: keep-all;');
    Html.Add('      font-variant-numeric: tabular-nums;');
    Html.Add('    }');
    Html.Add('    .mapping-pack-text {');
    Html.Add('      min-width: 0;');
    Html.Add('      overflow-wrap: anywhere;');
    Html.Add('    }');
    Html.Add('    .empty-state {');
    Html.Add('      color: var(--muted);');
    Html.Add('      padding: 8px 0;');
    Html.Add('    }');
    Html.Add('    .manual-meta {');
    Html.Add('      display: flex;');
    Html.Add('      flex-wrap: wrap;');
    Html.Add('      gap: 10px;');
    Html.Add('      margin-bottom: 12px;');
    Html.Add('      color: var(--muted);');
    Html.Add('      font-size: 13px;');
    Html.Add('    }');
    Html.Add('    .block {');
    Html.Add('      margin-top: 10px;');
    Html.Add('      padding: 10px 12px;');
    Html.Add('      border-radius: 14px;');
    Html.Add('      background: #f7fbff;');
    Html.Add('      border: 1px solid #e4eef8;');
    Html.Add('    }');
    Html.Add('    .block-label {');
    Html.Add('      margin-bottom: 6px;');
    Html.Add('      font-size: 12px;');
    Html.Add('      font-weight: 700;');
    Html.Add('      text-transform: uppercase;');
    Html.Add('      letter-spacing: 0.08em;');
    Html.Add('      color: var(--muted);');
    Html.Add('    }');
    Html.Add('    .pre {');
    Html.Add('      white-space: pre-wrap;');
    Html.Add('      font-family: "Consolas", "Courier New", monospace;');
    Html.Add('      font-size: 13px;');
    Html.Add('      line-height: 1.35;');
    Html.Add('    }');
    Html.Add('    details.block {');
    Html.Add('      padding: 0;');
    Html.Add('      overflow: hidden;');
    Html.Add('    }');
    Html.Add('    details.block > summary.block-label {');
    Html.Add('      margin-bottom: 0;');
    Html.Add('      padding: 10px 12px;');
    Html.Add('      cursor: pointer;');
    Html.Add('    }');
    Html.Add('    details.block[open] > summary.block-label { border-bottom: 1px solid #e4eef8; }');
    Html.Add('    details.block > .pre { padding: 10px 12px; }');
    Html.Add('    .log-block { max-height: 420px; overflow: auto; }');
    Html.Add('    .footer-note {');
    Html.Add('      margin-top: 20px;');
    Html.Add('      color: var(--muted);');
    Html.Add('      font-size: 13px;');
    Html.Add('    }');
    Html.Add('    @media print {');
    Html.Add('      body { background: #ffffff; padding: 0; }');
    Html.Add('      .page { max-width: none; }');
    Html.Add('      .hero, .meta-card, .section, .manual-card { box-shadow: none; }');
    Html.Add('      .section, .manual-card, .meta-card { break-inside: avoid; }');
    Html.Add('    }');
    Html.Add('  </style>');
    Html.Add('</head>');
    Html.Add('<body>');
    Html.Add('  <div class="page">');
    Html.Add('    <div class="hero">');
    Html.Add('      <div class="eyebrow">VCL to FMX Converter</div>');
    Html.Add('      <h1>Conversion Report</h1>');
    Html.Add('      <p>' + HtmlEncode(Format('Generated %s', [
      FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)])) + '</p>');
    Html.Add('      <p>' + HtmlEncode('Source: ' + FContext.Options.SourcePath) + '<br>' +
      HtmlEncode('Output: ' + FContext.Options.OutputPath) + '</p>');
    Html.Add('      <div class="status-chip">' + HtmlEncode(StatusText) + '</div>');
    Html.Add('      <p>' + HtmlEncode('Next step: ' + NextStepText) + '</p>');
    Html.Add('    </div>');
    Html.Add('    <div class="meta">');
    Html.Add('      <div class="meta-card"><div class="label">Files processed</div><div class="value">' +
      IntToStr(FFilesProcessed) + '</div></div>');
    Html.Add('      <div class="meta-card"><div class="label">Files converted</div><div class="value">' +
      IntToStr(FFilesConverted) + '</div></div>');
    Html.Add('      <div class="meta-card"><div class="label">Distinct files needing attention</div><div class="value">' +
      IntToStr(AffectedFiles.Count) + '</div></div>');
    Html.Add('      <div class="meta-card"><div class="label">Manual review items</div><div class="value">' +
      IntToStr(ManualCount) + '</div></div>');
    Html.Add('      <div class="meta-card"><div class="label">Blocking items</div><div class="value">' +
      IntToStr(BlockingCount) + '</div></div>');
    Html.Add('      <div class="meta-card"><div class="label">Files with errors</div><div class="value">' +
      IntToStr(FFilesErrors) + '</div></div>');
    Html.Add('      <div class="meta-card"><div class="label">Warnings</div><div class="value">' +
      IntToStr(WarnCount) + '</div></div>');
    Html.Add('      <div class="meta-card"><div class="label">Errors</div><div class="value">' +
      IntToStr(ErrorCount) + '</div></div>');
    Html.Add('      <div class="meta-card"><div class="label">Total issues</div><div class="value">' +
      IntToStr(VisibleIssueCount) + '</div></div>');
    if InfoCount > 0 then
      Html.Add('      <div class="meta-card"><div class="label">Informational notices</div><div class="value">' +
        IntToStr(InfoCount) + '</div></div>');
    if DryRunPreviewCount > 0 then
      Html.Add('      <div class="meta-card"><div class="label">Dry-run notices</div><div class="value">' +
        IntToStr(DryRunPreviewCount) + '</div></div>');
    Html.Add('      <div class="meta-card"><div class="label">Mapping packs loaded</div><div class="value">' +
      IntToStr(FContext.LoadedMappingPacks.Count) + '</div></div>');
    Html.Add('      <div class="meta-card"><div class="label">Run time</div><div class="value">' +
      HtmlEncode(RunTimeText) + '</div></div>');
    Html.Add('    </div>');

    Html.Add('    <div class="section">');
    Html.Add('      <h2>Conversion health</h2>');
    Html.Add('      <p class="section-note">Risk categories summarize what kind of review the generated project still needs.</p>');
    Html.Add('      <table><tbody>');
    if HasBlockingOutcome then
      Html.Add('        <tr><th>Compile readiness</th><td>Blocked until conversion errors or blocking items are resolved.</td></tr>')
    else if ManualCount > 0 then
      Html.Add('        <tr><th>Compile readiness</th><td>Possible, but manual-review items may still block reliable behavior.</td></tr>')
    else
      Html.Add('        <tr><th>Compile readiness</th><td>No blocking or manual-review categories were detected by the converter.</td></tr>');
    Html.Add('        <tr><th>Runtime behavior review</th><td>' + IfThen(HasRiskCategory('Runtime behavior risk'), 'Yes', 'No') + '</td></tr>');
    Html.Add('        <tr><th>Visual review</th><td>' + IfThen(HasRiskCategory('Visual review risk'), 'Yes', 'No') + '</td></tr>');
    Html.Add('        <tr><th>Data binding review</th><td>' + IfThen(HasRiskCategory('Data binding review risk'), 'Yes', 'No') + '</td></tr>');
    Html.Add('        <tr><th>Manual code review</th><td>' + IfThen(ManualCount > 0, 'Yes', 'No') + '</td></tr>');
    Html.Add('      </tbody></table>');
    Html.Add('    </div>');

    Html.Add('    <div class="section">');
    Html.Add('      <h2>Output files</h2>');
    Html.Add('      <p class="section-note">Files and folders produced or updated by this conversion run.</p>');
    Html.Add('      <table class="issues-table">');
    Html.Add('        <tbody>');
    Html.Add('          <tr><th>Output folder</th><td>' + HtmlEncode(FContext.Options.OutputPath) + '</td></tr>');
    Html.Add('          <tr><th>Text report</th><td>' + HtmlEncode(ReportFile) + '</td></tr>');
    Html.Add('          <tr><th>HTML report</th><td>' + HtmlEncode(HtmlReportFile) + '</td></tr>');
    Html.Add('          <tr><th>Converted source files</th><td>Generated Pascal and FMX files are written beside converted source names in the output folder.</td></tr>');
    Html.Add('        </tbody>');
    Html.Add('      </table>');
    Html.Add('    </div>');

    Html.Add('    <details class="section disclosure">');
    Html.Add('      <summary><h2>Mapping packs loaded (' + IntToStr(FContext.LoadedMappingPacks.Count) + ')</h2><span>Show/hide loaded packs</span></summary>');
    Html.Add('      <p class="section-note">External mapping packs loaded for this conversion run.</p>');
    Html.Add('      <div class="mapping-pack-list">');
    if FContext.LoadedMappingPacks.Count = 0 then
      Html.Add('        <div class="mapping-pack-row"><div class="mapping-pack-text">No mapping packs were loaded for this run.</div></div>')
    else
      for ManualIndex := 0 to FContext.LoadedMappingPacks.Count - 1 do
        Html.Add('        <div class="mapping-pack-row"><div class="mapping-pack-index">' +
          IntToStr(ManualIndex + 1) + '</div><div class="mapping-pack-text">' +
          HtmlEncode(FContext.LoadedMappingPacks[ManualIndex]) + '</div></div>');
    Html.Add('      </div>');
    Html.Add('    </details>');

    AddUsageHtmlSection('Third-party components converted',
      'Mapping-pack components that generated FMX output with a convert action.',
      'No third-party mapping-pack components were fully converted.',
      'convert', True, False);
    AddUsageHtmlSection('Third-party components partially converted',
      'Mapping-pack components that generated FMX output but still require review.',
      'No third-party mapping-pack components were partially converted.',
      'partial', True, False);
    AddUsageHtmlSection('Third-party components detected only',
      'Mapping-pack components intentionally reported without generated FMX output.',
      'No detect-only third-party mapping-pack components were found.',
      'detect_only', False, True);
    AddMappingsUsedHtmlSection;


    if DryRunPreviewCount > 0 then
    begin
      Html.Add('    <details class="section disclosure">');
      Html.Add('      <summary><h2>Dry-run preview (' + IntToStr(DryRunPreviewCount) + ')</h2><span>Show/hide preview notices</span></summary>');
      Html.Add('      <p class="section-note">Preview mode did not write converted source, form, or project files. These notices are not counted as conversion issues.</p>');
      Html.Add('      <div class="compact-list">');
      for Issue in FContext.Issues do
        if IsDryRunPreviewIssue(Issue) then
          Html.Add('        <div>' + HtmlEncode(Issue.Message) + '</div>');
      Html.Add('      </div>');
      Html.Add('    </details>');
    end;
    Html.Add('    <div class="section">');
    Html.Add('      <h2>Detailed issues</h2>');
    Html.Add('      <p class="section-note">Warnings and errors are listed below. Informational run details stay in the text report and conversion log.</p>');
    Html.Add('      <div class="issue-list">');

    HasDetailedIssues := False;
    for Issue in FContext.Issues do
    begin
      if not ShouldIncludeInDetailedIssues(Issue) then
        Continue;
      if Issue.Severity = csInfo then
        Continue;

      HasDetailedIssues := True;
      Html.Add('        <div class="issue-card">');
      Html.Add('          <div class="issue-card-header"><span class="severity ' +
        SeverityCssClass(Issue.Severity) + '">' +
        HtmlEncode(SeverityToString(Issue.Severity)) + '</span><strong>' +
        HtmlEncode(IfThen(Issue.ProblemType <> '', Issue.ProblemType,
          IssueRiskCategory(Issue))) + '</strong><span class="meta">' +
        HtmlEncode(IssueRiskCategory(Issue)) + '</span>' +
        IfThen(Issue.LineNumber > 0,
          '<span class="meta">Line ' + IntToStr(Issue.LineNumber) + '</span>',
          '') + '</div>');
      Html.Add('          <div class="issue-message">' + HtmlEncode(Issue.Message) + '</div>');
      if Trim(Issue.FileName) <> '' then
        Html.Add('          <div class="issue-path">' + HtmlEncode(Issue.FileName) + '</div>');
      if Trim(Issue.SuggestedFix) <> '' then
        Html.Add('          <div class="issue-fix">' + HtmlEncode(Issue.SuggestedFix) + '</div>');
      Html.Add('        </div>');
    end;

    if not HasDetailedIssues then
      Html.Add('        <div class="empty-state">No warning or error items were recorded outside the grouped manual-review section.</div>');

    Html.Add('      </div>');
    Html.Add('    </div>');
    Html.Add('    <div class="section">');
    Html.Add('      <h2>Manual review items</h2>');
    Html.Add('      <p class="section-note">These items usually require an IDE review or a deliberate FMX design decision before the converted output is production-ready.<br><strong style="color:#174f8f;">Click the &gt; arrow on each item to view affected locations and recommended fixes.</strong></p>');
    Html.Add('      <div class="manual-list">');

    if ManualCount = 0 then
      Html.Add('        <div class="manual-card">No grouped manual-review items were recorded.</div>')
    else
      for ManualIndex := 0 to ManualGroups.Count - 1 do
      begin
        Issue := TList<TConversionIssue>(ManualGroups.Objects[ManualIndex])[0];
        Html.Add('        <div class="manual-card">');
        Html.Add('          <h3>' + HtmlEncode(Format('%d. %s', [ManualIndex + 1,
          IfThen(Issue.ProblemType <> '', Issue.ProblemType,
          'Manual review required')])) + '</h3>');
        Html.Add('          <div class="manual-meta">');
        Html.Add('            <span>Occurrences: ' +
          IntToStr(ManualOccurrenceCount(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex]))) + '</span>');
        if ManualAffectedLineCount(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex])) >
           ManualOccurrenceCount(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex])) then
          Html.Add('            <span>Affected lines: ' +
            IntToStr(ManualAffectedLineCount(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex]))) + '</span>');
        if Issue.IsBlocking then
          Html.Add('            <span>Blocking: Yes</span>');
        Html.Add('            <span>Risk: ' + HtmlEncode(IssueRiskCategory(Issue)) + '</span>');
        Html.Add('          </div>');
        Html.Add('          <p><strong>Detail:</strong> ' +
          HtmlEncode(BuildManualDetailText(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex]))) + '</p>');
        Html.Add('          <details class="block">');
        Html.Add('            <summary class="block-label">Affected locations</summary>');
        Html.Add('            <div class="pre">' +
          HtmlEncode(BuildOccurrenceText(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex]))) +
          '</div>');
        Html.Add('          </details>');
        Html.Add('          <div class="block">');
        Html.Add('            <div class="block-label">Recommended solution</div>');
        Html.Add('            <div class="pre">' +
          HtmlEncode(BuildSuggestedFixText(TList<TConversionIssue>(ManualGroups.Objects[ManualIndex]))) +
          '</div>');
        Html.Add('          </div>');
        Html.Add('        </div>');
      end;

    Html.Add('      </div>');
    Html.Add('    </div>');

    if FConversionLog.Count > 0 then
    begin
      Html.Add('    <details class="section disclosure">');
      Html.Add('      <summary><h2>Conversion log</h2><span>Show/hide screen log</span></summary>');
      Html.Add('      <p class="section-note">Screen log captured during this conversion run.</p>');
      Html.Add('      <div class="pre log-block">' + HtmlEncode(FConversionLog.Text) + '</div>');
      Html.Add('    </details>');
    end;

    Html.Add('    <div class="section">');
    Html.Add('      <h2>Issue summary</h2>');
    Html.Add('      <p class="section-note">Use this section for a quick print-friendly tally of the result.</p>');
    Html.Add('      <table>');
    Html.Add('        <tbody>');
    Html.Add('          <tr><th>Informational</th><td>' + IntToStr(InfoCount) + '</td></tr>');
    Html.Add('          <tr><th>Warnings</th><td>' + IntToStr(WarnCount) + '</td></tr>');
    Html.Add('          <tr><th>Manual review required</th><td>' + IntToStr(ManualCount) + '</td></tr>');
    Html.Add('          <tr><th>Errors</th><td>' + IntToStr(ErrorCount) + '</td></tr>');
    Html.Add('          <tr><th>Blocking items</th><td>' + IntToStr(BlockingCount) + '</td></tr>');
    Html.Add('          <tr><th>Distinct files needing attention</th><td>' + IntToStr(AffectedFiles.Count) + '</td></tr>');
    Html.Add('          <tr><th>Files with conversion errors</th><td>' + IntToStr(FFilesErrors) + '</td></tr>');
    Html.Add('        </tbody>');
    Html.Add('      </table>');
    Html.Add('      <div class="footer-note">Next step: ' + HtmlEncode(NextStepText) + '</div>');
    Html.Add('      <div class="footer-note">Generated output should still be reviewed in the IDE. Projects with manual-review or blocking items may not run until those items are fixed or mitigated.</div>');
    Html.Add('    </div>');
    Html.Add('  </div>');
    Html.Add('</body>');
    Html.Add('</html>');

    Html.SaveToFile(HtmlReportFile, TEncoding.UTF8);
    UILog(Format('HTML report saved to: %s', [HtmlReportFile]));

  finally
    AffectedFiles.Free;
    FreeManualGroups;
    ManualGroups.Free;
    SeenBlockingKeys.Free;
    Html.Free;
    Report.Free;
  end;
end;

procedure TConverterEngine.Cancel;
begin
  FCancelled := True;
  UILog('Conversion cancelled by user');
end;

end.
