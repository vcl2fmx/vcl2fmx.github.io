{VCL2FMX © 2026 echurchsites.wixsite.com
 Delphi VCL to FMX Converter and assistant
 Version v5.0 Vanguard
 Written and built in the USA}

 unit Converter.Advanced.CriticalAreas;

interface

uses
  System.Classes, System.SysUtils, System.StrUtils, System.Generics.Collections,
  System.RegularExpressions, System.RTTI, System.JSON,
  Converter.Core.Types,
  Converter.Parser.Pascal;

type
  // Custom Drawing Converter
  TCustomDrawingConverter = class
  private
    FContext: TConversionContext;

    function ConvertGDIMethod(const MethodCall: string): string;
    function ConvertPaintHandler(const MethodBody: TStringList): TStringList;
    function IsGDIFunction(const Line: string): Boolean;
  public
    constructor Create(AContext: TConversionContext);

    function ConvertOnPaint(var PascalCode: TStringList): Boolean;
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
    function ConvertMessageMaps(var PascalCode: TStringList): Boolean;
    function GenerateFMXMessageHandlers: TStringList;
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
    function GenerateDrawHandlers: TStringList;
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

  // Form Inheritance Converter
  TFormInheritanceConverter = class
  private
    FContext: TConversionContext;
    FInheritedForms: TDictionary<string, string>;

    procedure AnalyzeInheritance(const FormName, ClassName: string);
  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    function ConvertInheritedForms(const FormFiles: TArray<string>): Boolean;
    function GenerateInheritanceHierarchy: TStringList;
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
    FFormInheritance: TFormInheritanceConverter;

    FIssuesFound: TStringList;
  public
    constructor Create(AContext: TConversionContext);
    destructor Destroy; override;

    function ConvertAllCriticalAreas(var PascalCode: TStringList): Boolean;
    function GenerateCriticalAreasReport: TStringList;
    property IssuesFound: TStringList read FIssuesFound;
  end;

implementation

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
  FContext := AContext;
end;

function TCustomDrawingConverter.ConvertOnPaint(var PascalCode: TStringList): Boolean;
var
  I: Integer;
  J: Integer;
  InPaintHandler: Boolean;
  PaintLines: TStringList;
  StartLine: Integer;
  ConvertedLines: TStringList;
  Line: string;
  HandlerDepth: Integer;
  SawHandlerBegin: Boolean;
begin
  Result := False;
  InPaintHandler := False;
  PaintLines := nil;
  StartLine := -1;
  HandlerDepth := 0;
  SawHandlerBegin := False;

  for I := 0 to PascalCode.Count - 1 do
  begin
    Line := Trim(PascalCode[I]);

    if (Pos('procedure', Line) > 0) and
       ((Pos('Paint', Line) > 0) or (Pos('Draw', Line) > 0)) and
       (Pos('Sender: TObject', Line) > 0) then
    begin
      InPaintHandler := True;
      StartLine := I;
      HandlerDepth := 0;
      SawHandlerBegin := False;
      PaintLines := TStringList.Create;
      PaintLines.Add(PascalCode[I]);

      FContext.AddIssue(csInfo,
        Format('Custom paint handler detected at line %d', [I + 1]));
    end
    else if InPaintHandler then
    begin
      PaintLines.Add(PascalCode[I]);

      if TRegEx.IsMatch(Line, '^(begin|case\b|try\b|repeat\b)', [roIgnoreCase]) then
      begin
        Inc(HandlerDepth);
        SawHandlerBegin := True;
      end;
      if TRegEx.IsMatch(Line, '^(end\b|until\b|finally\b|except\b)', [roIgnoreCase]) then
        Dec(HandlerDepth);

      if SawHandlerBegin and (HandlerDepth <= 0) and SameText(Trim(Line), 'end;') then
      begin
        InPaintHandler := False;

        ConvertedLines := ConvertPaintHandler(PaintLines);
        J := PaintLines.Count;
        ReplaceCodeBlock(PascalCode, StartLine, J, ConvertedLines);

        FreeAndNil(PaintLines);
        FreeAndNil(ConvertedLines);
        Result := True;
      end;
    end;
  end;
end;

function TCustomDrawingConverter.ConvertPaintHandler(
  const MethodBody: TStringList): TStringList;
var
  I: Integer;
  Line: string;
  InCanvasOp: Boolean;
begin
  Result := TStringList.Create;
  InCanvasOp := False;

  for I := 0 to MethodBody.Count - 1 do
  begin
    Line := MethodBody[I];

    if IsGDIFunction(Line) then
    begin
      if not InCanvasOp then
      begin
        Result.Add('  // Converted GDI operations to FMX Canvas');
        Result.Add('  with Canvas do');
        Result.Add('  begin');
        InCanvasOp := True;
      end;

      Result.Add('    ' + ConvertGDIMethod(Trim(Line)));
    end
    else
    begin
      if InCanvasOp then
      begin
        Result.Add('  end;');
        InCanvasOp := False;
      end;

      Result.Add(Line);
    end;
  end;

  if InCanvasOp then
    Result.Add('  end;');
end;

function TCustomDrawingConverter.ConvertGDIMethod(const MethodCall: string): string;
var
  Params: string;
  StartPos: Integer;
  EndPos: Integer;
  X, Y, Text: string;
  Parts: TArray<string>;
begin
  Result := MethodCall;

  if Pos('Rectangle', MethodCall) > 0 then
  begin
    StartPos := Pos('(', MethodCall);
    EndPos := LastDelimiter(')', MethodCall);
    if (StartPos > 0) and (EndPos > StartPos) then
    begin
      Params := Copy(MethodCall, StartPos + 1, EndPos - StartPos - 1);
      Result := Format('DrawRect(RectF(%s), 0, 0, AllCorners, 1, TCornerStyle.Round);', [Params]);
    end;
  end

  else if Pos('Ellipse', MethodCall) > 0 then
  begin
    StartPos := Pos('(', MethodCall);
    EndPos := LastDelimiter(')', MethodCall);
    if (StartPos > 0) and (EndPos > StartPos) then
    begin
      Params := Copy(MethodCall, StartPos + 1, EndPos - StartPos - 1);
      Result := Format('DrawEllipse(RectF(%s), 1);', [Params]);
    end;
  end

  else if Pos('TextOut', MethodCall) > 0 then
  begin
    StartPos := Pos('(', MethodCall);
    EndPos := LastDelimiter(')', MethodCall);
    if (StartPos > 0) and (EndPos > StartPos) then
    begin
      Params := Copy(MethodCall, StartPos + 1, EndPos - StartPos - 1);
      Parts := Params.Split([',']);
      if Length(Parts) >= 3 then
      begin
        X := Trim(Parts[0]);
        Y := Trim(Parts[1]);
        Text := Trim(Parts[2]);
        Result := Format('DrawText(RectF(%s, %s, %s+500, %s+50), %s, False, 1, [], TTextAlign.Leading, TTextAlign.Center);',
          [X, Y, X, Y, Text]);
      end;
    end;
  end

  else if Pos('LineTo', MethodCall) > 0 then
  begin
    StartPos := Pos('(', MethodCall);
    EndPos := LastDelimiter(')', MethodCall);
    if (StartPos > 0) and (EndPos > StartPos) then
    begin
      Params := Copy(MethodCall, StartPos + 1, EndPos - StartPos - 1);
      Result := Format('DrawLine(PointF(0, 0), PointF(%s), 1);', [Params]);
    end;
  end

  else if Pos('FillRect', MethodCall) > 0 then
  begin
    StartPos := Pos('(', MethodCall);
    EndPos := LastDelimiter(')', MethodCall);
    if (StartPos > 0) and (EndPos > StartPos) then
    begin
      Params := Copy(MethodCall, StartPos + 1, EndPos - StartPos - 1);
      Result := Format('FillRect(RectF(%s), 0, 0, AllCorners, 1, TCornerStyle.Round);', [Params]);
    end;
  end

  else if Pos('FrameRect', MethodCall) > 0 then
  begin
    StartPos := Pos('(', MethodCall);
    EndPos := LastDelimiter(')', MethodCall);
    if (StartPos > 0) and (EndPos > StartPos) then
    begin
      Params := Copy(MethodCall, StartPos + 1, EndPos - StartPos - 1);
      Result := Format('DrawRect(RectF(%s), 0, 0, AllCorners, 1, TCornerStyle.Round);', [Params]);
    end;
  end;

  if Pos('Pen.Color', Result) > 0 then
    Result := StringReplace(Result, 'Pen.Color', 'Stroke.Color', [rfReplaceAll]);
  if Pos('Pen.Width', Result) > 0 then
    Result := StringReplace(Result, 'Pen.Width', 'Stroke.Thickness', [rfReplaceAll]);
  if Pos('Brush.Color', Result) > 0 then
    Result := StringReplace(Result, 'Brush.Color', 'Fill.Color', [rfReplaceAll]);
  if Pos('Brush.Style', Result) > 0 then
    Result := StringReplace(Result, 'Brush.Style', 'Fill.Kind', [rfReplaceAll]);
end;

function TCustomDrawingConverter.IsGDIFunction(const Line: string): Boolean;
var
  L: string;
begin
  L := LowerCase(Line);
  Result := (Pos('canvas.', L) > 0) and (
    (Pos('rectangle', L) > 0) or
    (Pos('ellipse', L) > 0) or
    (Pos('textout', L) > 0) or
    (Pos('lineto', L) > 0) or
    (Pos('moveto', L) > 0) or
    (Pos('fillrect', L) > 0) or
    (Pos('framerect', L) > 0) or
    (Pos('polygon', L) > 0) or
    (Pos('polyline', L) > 0) or
    (Pos('pie', L) > 0) or
    (Pos('arc', L) > 0) or
    (Pos('chord', L) > 0)
  );
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
  FContext := AContext;
  FMessageMap := TDictionary<string, string>.Create;

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
          if TRegEx.IsMatch(CleanLine, '^(begin|case\b|try\b|repeat\b)', [roIgnoreCase]) then
          begin
            Inc(HandlerDepth);
            SawHandlerBegin := True;
          end;
          if TRegEx.IsMatch(CleanLine, '^(end\b|until\b)', [roIgnoreCase]) then
            Dec(HandlerDepth);

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
              if FMessageMap.TryGetValue(MessageName, FMXEvent) then
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

        if FMessageMap.TryGetValue(MessageName, FMXEvent) then
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

function TMessageHandlerConverter.ConvertMessageMaps(
  var PascalCode: TStringList): Boolean;
begin
  Result := ConvertMessageHandlers(PascalCode);
end;

function TMessageHandlerConverter.GenerateFMXMessageHandlers: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('{ ===== FMX Message Bridge =====');
  Result.Add('  Generated by VCL2FMX Converter.');
  Result.Add('  Replace Windows WM_USER messages with TMessageManager.');
  Result.Add('  Usage:');
  Result.Add('    1. Define a message class for each custom WM_USER + N:');
  Result.Add('       type TMyMsg = class(TMessage<Integer>) end;');
  Result.Add('    2. In FormCreate: subscribe:');
  Result.Add('       TMessageManager.DefaultManager.SubscribeToMessage(TMyMsg,');
  Result.Add('         procedure(const Sender: TObject; const M: TMessage)');
  Result.Add('         begin');
  Result.Add('           HandleMyMsg(M as TMyMsg);');
  Result.Add('         end);');
  Result.Add('    3. To send (replaces PostMessage):');
  Result.Add('       TMessageManager.DefaultManager.SendMessage(Self, TMyMsg.Create(Value));');
  Result.Add('    4. In FormDestroy: unsubscribe:');
  Result.Add('       TMessageManager.DefaultManager.Unsubscribe(TMyMsg);');
  Result.Add('  Requires: System.Messaging in uses clause.');
  Result.Add('  ============================= }');
end;

{ TOwnerDrawConverter }

constructor TOwnerDrawConverter.Create(AContext: TConversionContext);
begin
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
  Controls := DetectOwnerDrawControls(PascalCode);

  try
    for ControlName in Controls do
    begin
      InHandler := False;
      HandlerDepth := 0;
      SawHandlerBegin := False;

      for I := 0 to PascalCode.Count - 1 do
      begin
        Line := PascalCode[I];

        if (Pos('procedure', Line) > 0) and
           ((Pos(ControlName + 'Draw', Line) > 0) or
            (Pos(ControlName + 'Measure', Line) > 0) or
            ((Pos('DrawItem', Line) > 0) and (Pos('Sender: TObject', Line) > 0))) then
        begin
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

          if TRegEx.IsMatch(Trim(Line), '^(begin|case\b|try\b|repeat\b)', [roIgnoreCase]) then
          begin
            Inc(HandlerDepth);
            SawHandlerBegin := True;
          end;
          if TRegEx.IsMatch(Trim(Line), '^(end\b|until\b|finally\b|except\b)', [roIgnoreCase]) then
            Dec(HandlerDepth);

          if SawHandlerBegin and (HandlerDepth <= 0) and SameText(Trim(Line), 'end;') then
          begin
            InHandler := False;
            OriginalCount := HandlerLines.Count;

            if Pos('ListBox', ControlName) > 0 then
            begin
              ConvertedHandler := ConvertListBoxDraw(HandlerLines);
              HandlerLines.Free;
              HandlerLines := ConvertedHandler;
            end;

            ReplaceCodeBlock(PascalCode, StartLine, OriginalCount, HandlerLines);

            FreeAndNil(HandlerLines);
            Result := True;
          end;
        end;
      end;
    end;
  finally
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
      Line := StringReplace(Line, 'DrawFocusRect', 'DrawRect with Stroke.Dash := TDash.Dash', [rfReplaceAll]);
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

function TOwnerDrawConverter.GenerateDrawHandlers: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('  // FMX owner-draw template');
  Result.Add('  procedure ListBox1DrawItem(Sender: TObject; const Canvas: TCanvas;');
  Result.Add('    const Item: TListBoxItem; const Rect: TRectF; const State: TDrawState);');
  Result.Add('  begin');
  Result.Add('    // Custom drawing code here');
  Result.Add('    Canvas.Fill.Color := TAlphaColorRec.White;');
  Result.Add('    Canvas.FillRect(Rect, 0, 0, AllCorners, 1);');
  Result.Add('    ');
  Result.Add('    if dsSelected in State then');
  Result.Add('      Canvas.Fill.Color := TAlphaColorRec.Lightblue;');
  Result.Add('      ');
  Result.Add('    Canvas.FillText(Rect, Item.Text, False, 1, [], TTextAlign.Leading);');
  Result.Add('  end;');
end;

{ TActionListConverter }

constructor TActionListConverter.Create(AContext: TConversionContext);
begin
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

{ TFormInheritanceConverter }

constructor TFormInheritanceConverter.Create(AContext: TConversionContext);
begin
  FContext := AContext;
  FInheritedForms := TDictionary<string, string>.Create;
end;

destructor TFormInheritanceConverter.Destroy;
begin
  FInheritedForms.Free;
  inherited;
end;

procedure TFormInheritanceConverter.AnalyzeInheritance(const FormName,
  ClassName: string);
begin
  if Pos('(', ClassName) > 0 then
  begin
    var InheritedFrom := Copy(ClassName,
      Pos('(', ClassName) + 1,
      Pos(')', ClassName) - Pos('(', ClassName) - 1);

    FInheritedForms.Add(FormName, InheritedFrom);

    FContext.AddIssue(csInfo,
      Format('Form inheritance detected: %s inherits from %s',
        [FormName, InheritedFrom]));
  end;
end;

function TFormInheritanceConverter.ConvertInheritedForms(
  const FormFiles: TArray<string>): Boolean;
var
  I: Integer;
  Content: TStringList;
  FormName: string;
  ClassName: string;
  Line: string;
  Parts: TArray<string>;
begin
  Result := False;

  for I := 0 to Length(FormFiles) - 1 do
  begin
    Content := TStringList.Create;
    try
      if FileExists(FormFiles[I]) then
        Content.LoadFromFile(FormFiles[I]);

      for var J := 0 to Content.Count - 1 do
      begin
        Line := Trim(Content[J]);
        if Pos('object', Line) = 1 then
        begin
          Parts := Line.Split([':']);
          if Length(Parts) >= 2 then
          begin
            FormName := Trim(StringReplace(Parts[0], 'object', '', [rfReplaceAll]));
            ClassName := Trim(Parts[1]);
            AnalyzeInheritance(FormName, ClassName);
          end;
          Break;
        end;
      end;
    finally
      Content.Free;
    end;
  end;
end;

function TFormInheritanceConverter.GenerateInheritanceHierarchy: TStringList;
var
  Pair: TPair<string, string>;
begin
  Result := TStringList.Create;
  Result.Add('Form Inheritance Hierarchy:');
  Result.Add('==========================');

  for Pair in FInheritedForms do
  begin
    Result.Add(Format('  %s -> %s', [Pair.Key, Pair.Value]));
  end;

  if FInheritedForms.Count = 0 then
    Result.Add('  No form inheritance detected');
end;

{ TCriticalAreasConverter }

constructor TCriticalAreasConverter.Create(AContext: TConversionContext);
begin
  FContext := AContext;

  FCustomDrawing := TCustomDrawingConverter.Create(AContext);
  FMessageHandler := TMessageHandlerConverter.Create(AContext);
  FOwnerDraw := TOwnerDrawConverter.Create(AContext);
  FActionList := TActionListConverter.Create(AContext);
  FThreadSync := TThreadSyncConverter.Create(AContext);
  FDPIScaling := TDPIScalingConverter.Create(AContext);
  FFormInheritance := TFormInheritanceConverter.Create(AContext);

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
  FFormInheritance.Free;

  FIssuesFound.Free;
  inherited;
end;

function TCriticalAreasConverter.ConvertAllCriticalAreas(
  var PascalCode: TStringList): Boolean;
begin
  Result := False;

  if FCustomDrawing.ConvertCustomDrawing(PascalCode) then
  begin
    FIssuesFound.Add('Custom drawing converted - review paint handlers');
    Result := True;
  end;

  if FMessageHandler.ConvertMessageMaps(PascalCode) then
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

function TCriticalAreasConverter.GenerateCriticalAreasReport: TStringList;
var
  I: Integer;
begin
  Result := TStringList.Create;
  Result.Add('Critical Areas Conversion Report');
  Result.Add('================================');
  Result.Add('');

  if FIssuesFound.Count > 0 then
  begin
    for I := 0 to FIssuesFound.Count - 1 do
      Result.Add(Format('%d. %s', [I + 1, FIssuesFound[I]]));
  end
  else
    Result.Add('No critical issues detected.');

  Result.Add('');
  Result.Add('Please thoroughly test these areas after conversion.');
end;

end.
