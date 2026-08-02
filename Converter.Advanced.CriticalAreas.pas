{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v6.0 Navigator
 Written and built in the USA}

 unit Converter.Advanced.CriticalAreas;

interface

uses
  System.Classes, System.SysUtils, System.StrUtils, System.Generics.Collections,
  System.Generics.Defaults,
  System.RegularExpressions, System.RTTI, System.JSON,
  Converter.Core.Types,
  Converter.Parser.Pascal;

type
  // Custom Drawing Converter
  TCustomDrawingConverter = class
  private
    FContext: TConversionContext;

  public
    constructor Create(AContext: TConversionContext);

    function ConvertCustomDrawing(var PascalCode: TStringList): Boolean;
  end;

  // Windows Message Handler Converter
  TMessageHandlerConverter = class
  private
    FContext: TConversionContext;
    FMessageMap: TDictionary<string, string>;

    procedure InitializeMessageMap;
  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    function ConvertMessageHandlers(var PascalCode: TStringList): Boolean;
  end;

  // Owner-Draw Converter
  TOwnerDrawConverter = class
  private
    FContext: TConversionContext;

    function DetectOwnerDrawControls(const Lines: TStringList): TList<string>;
    function ConvertListBoxDraw(const HandlerBody: TStringList): TStringList;
  public
    constructor Create(AContext: TConversionContext);

    function ConvertOwnerDraw(var PascalCode: TStringList): Boolean;
  end;

  // ActionList Converter
  TActionListConverter = class
  private
    FContext: TConversionContext;
  public
    constructor Create(AContext: TConversionContext);

    function ConvertActionLists(var PascalCode: TStringList): Boolean;
  end;

  // Thread Synchronization Converter
  TThreadSyncConverter = class
  private
    FContext: TConversionContext;

    function DetectSynchronizeCalls(const Line: string): Boolean;
    function DetectQueueCalls(const Line: string): Boolean;
    function DetectCriticalSection(const Line: string): Boolean;
    function ConvertSynchronize(const MethodCall: string): string;
    function ConvertQueue(const MethodCall: string): string;
  public
    constructor Create(AContext: TConversionContext);

    function ConvertThreadSync(var PascalCode: TStringList): Boolean;
  end;

  // DPI Scaling Converter
  TDPIScalingConverter = class
  private
    FContext: TConversionContext;

    function DetectScalingCode(const Line: string): Boolean;
    function DetectFixedPixels(const Value: string): Boolean;
  public
    constructor Create(AContext: TConversionContext);

    function ConvertDPIAssumptions(var PascalCode: TStringList): Boolean;
  end;

  // Master Critical Areas Converter
  TCriticalAreasConverter = class
  private
    FContext: TConversionContext;
    FCustomDrawing: TCustomDrawingConverter;
    FMessageHandler: TMessageHandlerConverter;
    FOwnerDraw: TOwnerDrawConverter;
    FActionList: TActionListConverter;
    FThreadSync: TThreadSyncConverter;
    FDPIScaling: TDPIScalingConverter;

    FIssuesFound: TStringList;
  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    function ConvertAllCriticalAreas(var PascalCode: TStringList): Boolean;
    property IssuesFound: TStringList read FIssuesFound;
  end;

implementation

function CriticalAreaBlockOpenCount(const Line: string): Integer;
begin
  Result := TRegEx.Matches(Line, '\b(begin|case|try|repeat)\b',
    [roIgnoreCase]).Count;
end;

function CriticalAreaBlockCloseCount(const Line: string): Integer;
begin
  Result := TRegEx.Matches(Line, '\b(end|until)\b', [roIgnoreCase]).Count;
end;

procedure ReplaceCodeBlock(Lines: TStringList; StartLine, OldCount: Integer;
  const NewLines: TStringList);
var
  I: Integer;
begin
  for I := 1 to OldCount do
    Lines.Delete(StartLine);

  for I := 0 to NewLines.Count - 1 do
    Lines.Insert(StartLine + I, NewLines[I]);
end;

{ TCustomDrawingConverter }

constructor TCustomDrawingConverter.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;
end;

function TCustomDrawingConverter.ConvertCustomDrawing(
  var PascalCode: TStringList): Boolean;
begin
  // The older line-by-line GDI rewrites were too aggressive and could emit
  // invalid FMX canvas code. Let later generic compatibility passes handle
  // paint-heavy methods more safely.
  Result := False;
end;

{ TMessageHandlerConverter }

constructor TMessageHandlerConverter.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;
  FMessageMap := TDictionary<string, string>.Create(TIStringComparer.Ordinal);

  InitializeMessageMap;
end;

destructor TMessageHandlerConverter.Destroy;
begin
  FMessageMap.Free;
  inherited;
end;

procedure TMessageHandlerConverter.InitializeMessageMap;
begin
  FMessageMap.Add('WM_PAINT', 'OnPaint');
  FMessageMap.Add('WM_SIZE', 'OnResize');
  FMessageMap.Add('WM_MOVE', 'OnPositionChanged');
  FMessageMap.Add('WM_SHOWWINDOW', 'OnVisibleChanged');
  FMessageMap.Add('WM_ENABLE', 'OnEnabledChanged');
  FMessageMap.Add('WM_SETFOCUS', 'OnEnter');
  FMessageMap.Add('WM_KILLFOCUS', 'OnExit');
  FMessageMap.Add('WM_KEYDOWN', 'OnKeyDown');
  FMessageMap.Add('WM_KEYUP', 'OnKeyUp');
  FMessageMap.Add('WM_CHAR', 'OnKeyDown');
  FMessageMap.Add('WM_MOUSEMOVE', 'OnMouseMove');
  FMessageMap.Add('WM_LBUTTONDOWN', 'OnMouseDown');
  FMessageMap.Add('WM_LBUTTONUP', 'OnMouseUp');
  FMessageMap.Add('WM_RBUTTONDOWN', 'OnMouseDown');
  FMessageMap.Add('WM_RBUTTONUP', 'OnMouseUp');
  FMessageMap.Add('WM_MBUTTONDOWN', 'OnMouseDown');
  FMessageMap.Add('WM_MBUTTONUP', 'OnMouseUp');
  FMessageMap.Add('WM_MOUSEWHEEL', 'OnMouseWheel');
  FMessageMap.Add('WM_TIMER', 'OnTimer');
  FMessageMap.Add('WM_COMMAND', 'OnClick');
  FMessageMap.Add('WM_DESTROY', 'OnClose');
  FMessageMap.Add('WM_CLOSE', 'OnCloseQuery');
  FMessageMap.Add('CM_DIALOGCHAR', 'OnKeyDown');
end;

function TMessageHandlerConverter.ConvertMessageHandlers(
  var PascalCode: TStringList): Boolean;
var
  I: Integer;
  J: Integer;
  K: Integer;
  Line: string;
  AnalysisLine: string;
  MethodName: string;
  MessageName: string;
  FMXEvent: string;
  Parts: TArray<string>;
  Part: string;
  HandlerDepth: Integer;
  SawHandlerBegin: Boolean;
  CleanLine: string;
  WMUserConst: string;
  WMUserValue: string;
  CustomMsgClass: string;
  SubscriptionLines: TStringList;
  UnsubscribeLines: TStringList;
  AnalysisLines: TStringList;
  FormClassName: string;
  InFormClass: Boolean;
  FormClassDepth: Integer;
  NeedsMessageSubscription: Boolean;
  SubscriptionInjected: Boolean;
begin
  Result := False;
  SubscriptionLines := TStringList.Create;
  UnsubscribeLines := TStringList.Create;
  AnalysisLines := TStringList.Create;
  try
    AnalysisLines.Text := VCL2FMXStripCommentsForAnalysis(PascalCode.Text);
    // Detect the form/object class name for subscription wiring
    FormClassName := '';
    InFormClass := False;
    FormClassDepth := 0;
    NeedsMessageSubscription := False;
    for I := 0 to PascalCode.Count - 1 do
    begin
      if I < AnalysisLines.Count then
        CleanLine := Trim(AnalysisLines[I])
      else
        CleanLine := Trim(PascalCode[I]);
      if TRegEx.IsMatch(CleanLine,
           '^T\w+\s*=\s*class\s*\(T(Form|Frame|DataModule)',
           [roIgnoreCase]) then
      begin
        FormClassName := TRegEx.Match(CleanLine, '^(T\w+)', [roIgnoreCase]).Value;
        Break;
      end;
    end;

    for I := 0 to PascalCode.Count - 1 do
    begin
      Line := PascalCode[I];
      if I < AnalysisLines.Count then
        AnalysisLine := AnalysisLines[I]
      else
        AnalysisLine := Line;

      // --- Pattern 1a: WndProc override declaration inside the class ---
      if TRegEx.IsMatch(AnalysisLine, '^\s*procedure\s+\w*(WndProc|WindowProc)\s*\([^\)]*\bvar\s+[A-Za-z_][A-Za-z0-9_]*\s*:', [roIgnoreCase]) then
      begin
        PascalCode[I] := '  { FMX manual review: ' + Trim(Line) + ' }';
        Result := True;
        Continue;
      end;

      // --- Pattern 1b: WndProc override implementation body ---
      if TRegEx.IsMatch(AnalysisLine, '^\s*procedure\s+[A-Za-z_][A-Za-z0-9_]*\.(WndProc|WindowProc)\s*\([^\)]*\bvar\s+[A-Za-z_][A-Za-z0-9_]*\s*:', [roIgnoreCase]) then
      begin
        FContext.AddIssue(csManualReview,
          'Windows WndProc override converted to TMessageManager subscription pattern.',
          'Windows messaging',
          Trim(Line),
          'Review the generated TMessageManager subscriptions in FormCreate/Destroy.',
          I + 1, False);

        PascalCode[I] := '  { FMX: WndProc replaced by TMessageManager - see FormCreate for subscriptions }';
        HandlerDepth := 0;
        SawHandlerBegin := False;

        for J := I + 1 to PascalCode.Count - 1 do
        begin
          if J < AnalysisLines.Count then
            CleanLine := Trim(AnalysisLines[J])
          else
            CleanLine := Trim(PascalCode[J]);
          if CriticalAreaBlockOpenCount(CleanLine) > 0 then
          begin
            Inc(HandlerDepth, CriticalAreaBlockOpenCount(CleanLine));
            SawHandlerBegin := True;
          end;
          Dec(HandlerDepth, CriticalAreaBlockCloseCount(CleanLine));

          if SawHandlerBegin and (HandlerDepth <= 0) and SameText(CleanLine, 'end;') then
          begin
            PascalCode[J] := '  { ' + Trim(PascalCode[J]) + ' }';
            Break;
          end;

          if (J < AnalysisLines.Count) and (Pos('WM_', AnalysisLines[J]) > 0) then
          begin
            Parts := Trim(AnalysisLines[J]).Split([':']);
            if Length(Parts) > 0 then
            begin
              MessageName := Trim(Parts[0]);
              if FMessageMap.TryGetValue(UpperCase(MessageName), FMXEvent) then
                PascalCode[J] := Format('  { FMX: %s -> use %s event handler }',
                  [Trim(PascalCode[J]), FMXEvent])
              else
                PascalCode[J] := '  { FMX: ' + Trim(PascalCode[J]) + ' -> use TMessageManager }';
            end;
          end
          else if Trim(PascalCode[J]) <> '' then
            PascalCode[J] := '  { ' + Trim(PascalCode[J]) + ' }';
        end;

        Result := True;
      end;

      // --- Pattern 2: message WM_XXX handler declarations (interface section) ---
      if ContainsText(AnalysisLine, 'message') and
         (ContainsText(AnalysisLine, 'WM_') or ContainsText(AnalysisLine, 'CM_')) then
      begin
        Parts := AnalysisLine.Split([' ', ';']);
        MethodName := '';
        MessageName := '';

        for Part in Parts do
        begin
          if (Pos('WM_', Part) > 0) or (Pos('CM_', Part) > 0) then
            MessageName := Trim(Part)
          else if SameText(Trim(Part), 'procedure') then
            if Length(Parts) > 1 then
              MethodName := Trim(Parts[1]);
        end;

        if FMessageMap.TryGetValue(UpperCase(MessageName), FMXEvent) then
        begin
          // Tier 1: direct FMX event mapping - convert declaration
          PascalCode[I] := TRegEx.Replace(Line,
            ';\s*message\s+\w+\s*$', '; { FMX: use ' + FMXEvent + ' event }',
            [roIgnoreCase]);
          if FormClassName <> '' then
          begin
            SubscriptionLines.Add(Format(
              '  { Wire %s to %s event in Object Inspector }',
              [MethodName, FMXEvent]));
          end;
        end
        else if Pos('WM_USER', MessageName) > 0 then
        begin
          // Tier 2: WM_USER custom message - generate TMessageManager pattern
          NeedsMessageSubscription := True;
          WMUserConst := MessageName;
          CustomMsgClass := 'T' + TRegEx.Replace(
            MethodName, '[^A-Za-z0-9]', '', []) + 'Msg';

          // Signal that the bridge unit is needed in the output project
          FContext.NeedsFMXMessageBridge := True;

          // Rewrite declaration
          PascalCode[I] := TRegEx.Replace(Line,
            ';\s*message\s+\w+[\w+\s]*$',
            '; { FMX: TMessageManager subscription - see FormCreate }',
            [roIgnoreCase]);

          // Queue subscription and unsubscribe code
          if FormClassName <> '' then
          begin
            SubscriptionLines.Add('');
            SubscriptionLines.Add(Format(
              '  { FMX replacement for %s (%s) }', [MethodName, WMUserConst]));
            SubscriptionLines.Add(Format(
              '  TMessageManager.DefaultManager.SubscribeToMessage(%s,',
              [CustomMsgClass]));
            SubscriptionLines.Add(
              '    procedure(const Sender: TObject; const M: TMessage)');
            SubscriptionLines.Add('    begin');
            SubscriptionLines.Add(Format(
              '      %s(M as %s);', [MethodName, CustomMsgClass]));
            SubscriptionLines.Add('    end);');

            UnsubscribeLines.Add(Format(
              '  TMessageManager.DefaultManager.Unsubscribe(%s);',
              [CustomMsgClass]));
          end;
        end
        else
        begin
          // Unknown WM_ - comment with guidance
          PascalCode[I] := TRegEx.Replace(Line,
            ';\s*message\s+\w+[\w+\s]*$',
            '; { FMX manual review: ' + MessageName + ' has no direct FMX event. For CM_DIALOGCHAR use FMX keyboard/action handling; for WM_SYSCOMMAND map the specific SC_* command to form state/close/platform logic; otherwise use TMessageManager or platform-specific code. }',
            [roIgnoreCase]);
        end;

        Result := True;
      end;
    end;

    // Inject subscription stubs into FormCreate if we have any
    if (SubscriptionLines.Count > 0) and (FormClassName <> '') then
    begin
      SubscriptionInjected := False;
      for I := 0 to PascalCode.Count - 1 do
      begin
        CleanLine := Trim(PascalCode[I]);
        if TRegEx.IsMatch(CleanLine,
             '^procedure\s+' + FormClassName + '\.FormCreate\b',
             [roIgnoreCase]) then
        begin
          // Find the begin of FormCreate
          for J := I + 1 to PascalCode.Count - 1 do
          begin
            if SameText(Trim(PascalCode[J]), 'begin') then
            begin
              PascalCode.Insert(J + 1,
                '  { FMX: Subscribe to messages - generated by VCL2FMX converter }');
              for K := SubscriptionLines.Count - 1 downto 0 do
                PascalCode.Insert(J + 2, SubscriptionLines[K]);
              SubscriptionInjected := True;
              Break;
            end;
          end;
          Break;
        end;
      end;

      if not SubscriptionInjected and Assigned(FContext) then
        FContext.AddIssue(csWarning,
          'WM_USER message subscription code was generated but could not be inserted automatically.',
          'Windows messaging',
          FormClassName + '.FormCreate not found or has no begin block',
          'Create or review FormCreate and add the generated TMessageManager subscription code manually.',
          -1, False);

      // Inject unsubscribe into FormDestroy / Destroy
      if UnsubscribeLines.Count > 0 then
      begin
        for I := 0 to PascalCode.Count - 1 do
        begin
          CleanLine := Trim(PascalCode[I]);
          if TRegEx.IsMatch(CleanLine,
               '^procedure\s+' + FormClassName + '\.(FormDestroy|Destroy)\b',
               [roIgnoreCase]) then
          begin
            for J := I + 1 to PascalCode.Count - 1 do
            begin
              if SameText(Trim(PascalCode[J]), 'begin') then
              begin
                PascalCode.Insert(J + 1,
                  '  { FMX: Unsubscribe messages - generated by VCL2FMX converter }');
                for K := UnsubscribeLines.Count - 1 downto 0 do
                  PascalCode.Insert(J + 2, UnsubscribeLines[K]);
                Break;
              end;
            end;
            Break;
          end;
        end;
      end;
    end
    else if NeedsMessageSubscription and Assigned(FContext) then
      FContext.AddIssue(csWarning,
        'WM_USER message handler detected, but no form class/FormCreate target was available for automatic subscription injection.',
        'Windows messaging',
        'WM_USER handler declaration',
        'Create or review FormCreate and add the generated TMessageManager subscription code manually.',
        -1, False);

  finally
    AnalysisLines.Free;
    UnsubscribeLines.Free;
    SubscriptionLines.Free;
  end;
end;

{ TOwnerDrawConverter }

constructor TOwnerDrawConverter.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;
end;

function TOwnerDrawConverter.DetectOwnerDrawControls(
  const Lines: TStringList): TList<string>;
var
  I: Integer;
  Line: string;
  Parts: TArray<string>;
  ControlName: string;
begin
  Result := TList<string>.Create;

  for I := 0 to Lines.Count - 1 do
  begin
    Line := Lines[I];

    if (Pos('Style = lbOwnerDraw', Line) > 0) or
       (Pos('Style = csOwnerDraw', Line) > 0) or
       (Pos('OwnerDraw = True', Line) > 0) or
       (Pos('OnDrawItem', Line) > 0) or
       (Pos('OnMeasureItem', Line) > 0) or
       (Pos('OnDrawCell', Line) > 0) then
    begin
      Parts := Line.Split(['=']);
      if Length(Parts) > 0 then
      begin
        ControlName := Trim(Parts[0]);
        if Pos(' ', ControlName) = 0 then
          Result.Add(ControlName);
      end;
    end;
  end;
end;

function TOwnerDrawConverter.ConvertOwnerDraw(
  var PascalCode: TStringList): Boolean;
var
  Controls: TList<string>;
  I: Integer;
  InHandler: Boolean;
  HandlerLines: TStringList;
  ConvertedHandler: TStringList;
  OriginalCount: Integer;
  StartLine: Integer;
  Line: string;
  ControlName: string;
  HandlerDepth: Integer;
  SawHandlerBegin: Boolean;
begin
  Result := False;
  StartLine := -1;
  HandlerLines := nil;
  Controls := DetectOwnerDrawControls(PascalCode);

  try
    for ControlName in Controls do
    begin
      InHandler := False;
      HandlerDepth := 0;
      SawHandlerBegin := False;
      FreeAndNil(HandlerLines);

      for I := 0 to PascalCode.Count - 1 do
      begin
        Line := PascalCode[I];

        if (Pos('procedure', Line) > 0) and
           ((Pos(ControlName + 'Draw', Line) > 0) or
            (Pos(ControlName + 'Measure', Line) > 0) or
            ((Pos('DrawItem', Line) > 0) and (Pos('Sender: TObject', Line) > 0))) then
        begin
          FreeAndNil(HandlerLines);
          InHandler := True;
          StartLine := I;
          HandlerDepth := 0;
          SawHandlerBegin := False;
          HandlerLines := TStringList.Create;
          HandlerLines.Add(Line);

          FContext.AddIssue(csInfo,
            Format('Owner-draw handler for %s at line %d',
              [ControlName, I + 1]));
        end
        else if InHandler then
        begin
          HandlerLines.Add(Line);

          if CriticalAreaBlockOpenCount(Trim(Line)) > 0 then
          begin
            Inc(HandlerDepth, CriticalAreaBlockOpenCount(Trim(Line)));
            SawHandlerBegin := True;
          end;
          Dec(HandlerDepth, CriticalAreaBlockCloseCount(Trim(Line)));

          if SawHandlerBegin and (HandlerDepth <= 0) and SameText(Trim(Line), 'end;') then
          begin
            OriginalCount := HandlerLines.Count;

            if Pos('ListBox', ControlName) > 0 then
            begin
              ConvertedHandler := ConvertListBoxDraw(HandlerLines);
              FreeAndNil(HandlerLines);
              HandlerLines := ConvertedHandler;
            end;

            ReplaceCodeBlock(PascalCode, StartLine, OriginalCount, HandlerLines);

            FreeAndNil(HandlerLines);
            Result := True;
            Break;
          end;
        end;
      end;
    end;
  finally
    HandlerLines.Free;
    Controls.Free;
  end;
end;

function TOwnerDrawConverter.ConvertListBoxDraw(
  const HandlerBody: TStringList): TStringList;
var
  I: Integer;
  Line: string;
begin
  Result := TStringList.Create;

  for I := 0 to HandlerBody.Count - 1 do
  begin
    Line := HandlerBody[I];

    if Pos('Canvas.', Line) > 0 then
    begin
      Line := StringReplace(Line, 'TRect', 'TRectF', [rfReplaceAll]);
      Line := StringReplace(Line, 'Rect(', 'RectF(', [rfReplaceAll]);
      Line := '  // FMX manual review: DrawFocusRect has no direct FMX equivalent; draw the focus rectangle manually with Canvas.DrawRect and Stroke.Dash.';
    end;

    if Pos('odSelected', Line) > 0 then
    begin
      Line := '  if ItemSelected then';
    end;

    if Pos('odFocused', Line) > 0 then
    begin
      Line := '  if IsFocused then';
    end;

    Result.Add(Line);
  end;

  Result.Insert(1, '  var ItemRect: TRectF;');
  Result.Insert(2, '  var ItemSelected: Boolean;');
  Result.Insert(3, '  var ItemIndex: Integer;');
  Result.Insert(4, '  // FMX: Get item state from parameters');
end;

{ TActionListConverter }

constructor TActionListConverter.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;
end;

function TActionListConverter.ConvertActionLists(
  var PascalCode: TStringList): Boolean;
var
  I: Integer;
  InActionList: Boolean;
  Line: string;
begin
  Result := False;
  InActionList := False;

  for I := 0 to PascalCode.Count - 1 do
  begin
    Line := PascalCode[I];

    if (Pos('object', Line) > 0) and (Pos('TActionList', Line) > 0) then
    begin
      InActionList := True;
      FContext.AddIssue(csInfo, Format('TActionList detected', []));
    end
    else if InActionList then
    begin
      if Trim(Line) = 'end' then
      begin
        InActionList := False;
        Result := True;
      end;
    end;

    if TRegEx.IsMatch(Trim(Line), '^\s*procedure\s+\w+(Execute|Update)\s*\(',
      [roIgnoreCase]) then
    begin
      if TRegEx.IsMatch(Line, 'Execute\s*\(', [roIgnoreCase]) then
        PascalCode[I] := '  // FMX: Handle OnExecute in action handler';
      if TRegEx.IsMatch(Line, 'Update\s*\(', [roIgnoreCase]) then
        PascalCode[I] := '  // FMX: Handle OnUpdate in action handler';

      Result := True;
    end;
  end;
end;

{ TThreadSyncConverter }

constructor TThreadSyncConverter.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;
end;

function TThreadSyncConverter.ConvertThreadSync(
  var PascalCode: TStringList): Boolean;
var
  I: Integer;
  Line: string;
begin
  Result := False;

  for I := 0 to PascalCode.Count - 1 do
  begin
    Line := PascalCode[I];

    if DetectSynchronizeCalls(Line) then
    begin
      PascalCode[I] := ConvertSynchronize(Line);
      Result := True;
    end;

    if DetectQueueCalls(Line) then
    begin
      PascalCode[I] := ConvertQueue(Line);
      Result := True;
    end;

    if DetectCriticalSection(Line) then
    begin
      PascalCode[I] := '  // ' + Line + ' - use TMonitor or TEvent in FMX';
      FContext.AddIssue(csInfo, 'Critical section converted - verify threading model');
      Result := True;
    end;
  end;
end;

function TThreadSyncConverter.DetectSynchronizeCalls(const Line: string): Boolean;
begin
  Result := (Pos('Synchronize(', Line) > 0) and
            (Pos('//', Trim(Line)) <> 1);
end;

function TThreadSyncConverter.DetectQueueCalls(const Line: string): Boolean;
begin
  Result := (Pos('Queue(', Line) > 0) and
            (Pos('//', Trim(Line)) <> 1);
end;

function TThreadSyncConverter.DetectCriticalSection(const Line: string): Boolean;
begin
  // Preserve RTL TCriticalSection declarations and instance usage.
  // Only raw WinAPI critical-section calls still need manual review.
  Result := ((Pos('EnterCriticalSection', Line) > 0) or
             (Pos('LeaveCriticalSection', Line) > 0)) and
            (Pos('//', Trim(Line)) <> 1);
end;

function TThreadSyncConverter.ConvertSynchronize(const MethodCall: string): string;
var
  StartPos: Integer;
  EndPos: Integer;
  Params: string;
begin
  Result := MethodCall;

  if Pos('Synchronize', MethodCall) > 0 then
  begin
    StartPos := Pos('(', MethodCall);
    EndPos := LastDelimiter(')', MethodCall);
    if (StartPos > 0) and (EndPos > StartPos) then
    begin
      Params := Copy(MethodCall, StartPos + 1, EndPos - StartPos - 1);
      Result := Format('  // Review thread handoff manually: TThread.Queue(nil, %s);',
        [Trim(Params)]);

      FContext.AddIssue(csInfo,
        'Synchronize converted to TThread.Queue - verify thread safety');
    end;
  end;
end;

function TThreadSyncConverter.ConvertQueue(const MethodCall: string): string;
begin
  Result := MethodCall;

  if Pos('Queue', MethodCall) > 0 then
  begin
    FContext.AddIssue(csInfo,
      'Queue call - ensure System.Classes is in uses clause');
  end;
end;

{ TDPIScalingConverter }

constructor TDPIScalingConverter.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;
end;

function TDPIScalingConverter.ConvertDPIAssumptions(
  var PascalCode: TStringList): Boolean;
var
  I: Integer;
  Line: string;
  NewLine: string;
  Matches: TMatchCollection;
  Match: TMatch;
begin
  Result := False;

  for I := 0 to PascalCode.Count - 1 do
  begin
    Line := PascalCode[I];
    NewLine := Line;

    if DetectScalingCode(Line) then
    begin
      Matches := TRegEx.Matches(Line, '\b\d+\b');
      for Match in Matches do
      begin
        if DetectFixedPixels(Match.Value) then
        begin
          NewLine := StringReplace(NewLine, Match.Value,
            Format('Round(%s * GetScreenScale)', [Match.Value]), [rfReplaceAll]);
          Result := True;
        end;
      end;
    end;

    if (Pos('Font.Size', Line) > 0) and (Pos('=', Line) > 0) then
    begin
      FContext.AddIssue(csInfo, 'Font size detected - verify DPI scaling');
      Result := True;
    end;

    if Pos('PixelsPerInch', Line) > 0 then
    begin
      if Pos('.Font.Height', Line) > 0 then
      begin
        // Preserve font-height DPI conversions so later generic passes can
        // translate them into FMX font sizing helpers.
        Result := True;
      end
      else
      begin
        NewLine := '  // ' + Line + ' - FMX uses automatic DPI scaling';
        Result := True;
      end;
    end;

    PascalCode[I] := NewLine;
  end;
end;

function TDPIScalingConverter.DetectScalingCode(const Line: string): Boolean;
begin
  Result := ((Pos('Width =', Line) > 0) or
             (Pos('Height =', Line) > 0) or
             (Pos('Left =', Line) > 0) or
             (Pos('Top =', Line) > 0) or
             (Pos('SetBounds', Line) > 0)) and
            (Pos('//', Trim(Line)) <> 1);
end;

function TDPIScalingConverter.DetectFixedPixels(const Value: string): Boolean;
var
  IntValue: Integer;
begin
  Result := TryStrToInt(Value, IntValue) and
            (IntValue > 0) and
            (IntValue < 2000);
end;

{ TCriticalAreasConverter }

constructor TCriticalAreasConverter.Create(AContext: TConversionContext);
begin
  inherited Create;
  FContext := AContext;

  FCustomDrawing := TCustomDrawingConverter.Create(AContext);
  FMessageHandler := TMessageHandlerConverter.Create(AContext);
  FOwnerDraw := TOwnerDrawConverter.Create(AContext);
  FActionList := TActionListConverter.Create(AContext);
  FThreadSync := TThreadSyncConverter.Create(AContext);
  FDPIScaling := TDPIScalingConverter.Create(AContext);

  FIssuesFound := TStringList.Create;
end;

destructor TCriticalAreasConverter.Destroy;
begin
  FCustomDrawing.Free;
  FMessageHandler.Free;
  FOwnerDraw.Free;
  FActionList.Free;
  FThreadSync.Free;
  FDPIScaling.Free;

  FIssuesFound.Free;
  inherited;
end;

function TCriticalAreasConverter.ConvertAllCriticalAreas(
  var PascalCode: TStringList): Boolean;
begin
  Result := False;
  FIssuesFound.Clear;

  if FCustomDrawing.ConvertCustomDrawing(PascalCode) then
  begin
    FIssuesFound.Add('Custom drawing converted - review paint handlers');
    Result := True;
  end;

  if FMessageHandler.ConvertMessageHandlers(PascalCode) then
  begin
    FIssuesFound.Add('Windows message handlers converted - verify event handlers');
    Result := True;
  end;

  if FOwnerDraw.ConvertOwnerDraw(PascalCode) then
  begin
    FIssuesFound.Add('Owner-draw controls converted - test custom drawing');
    Result := True;
  end;

  if FActionList.ConvertActionLists(PascalCode) then
  begin
    FIssuesFound.Add('ActionLists converted - verify action connections');
    Result := True;
  end;

  if FThreadSync.ConvertThreadSync(PascalCode) then
  begin
    FIssuesFound.Add('Thread synchronization converted - test thread safety');
    Result := True;
  end;

  if FDPIScaling.ConvertDPIAssumptions(PascalCode) then
  begin
    FIssuesFound.Add('DPI assumptions marked - test on different resolutions');
    Result := True;
  end;
end;

end.
