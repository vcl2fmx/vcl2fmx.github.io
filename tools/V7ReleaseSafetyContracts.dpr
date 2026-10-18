program V7ReleaseSafetyContracts;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.IOUtils, System.Classes, System.NetEncoding,
  Converter.Core.Types, Converter.Core.Engine, Converter.Core.FileManager;
var
  Root, InputPath, OutputPath, PackPath, Sentinel, Name, OriginalText,
    ReadText, EncodingName, PreviousDirectory: string;
  LegacyEncoding: TEncoding;
  Context: TConversionContext;
  Engine: TConverterEngine;
  FileManager: TFileManager;
  LockedFile: TFileStream;
  Issue: TConversionIssue;
  Failed, Passed: Integer;
  Found, Outcome: Boolean;

procedure Check(Value: Boolean; const Description: string);
var Diagnostic: TConversionIssue;
begin
  if Value then begin Inc(Passed); Writeln('PASS: ', Description); end
  else begin
    Inc(Failed); Writeln('FAIL: ', Description);
    if Assigned(Context) then
      for Diagnostic in Context.Issues do Writeln('  ', Diagnostic.Message);
  end;
end;

procedure Setup(const CaseName: string);
begin
  InputPath := TPath.Combine(Root, CaseName + '\input');
  OutputPath := TPath.Combine(Root, CaseName + '\output');
  TDirectory.CreateDirectory(InputPath);
  TDirectory.CreateDirectory(OutputPath);
  TFile.WriteAllText(TPath.Combine(InputPath, 'Example.pas'),
    'unit Example;' + sLineBreak + 'interface' + sLineBreak +
    'implementation' + sLineBreak + 'end.', TEncoding.UTF8);
  Context := TConversionContext.Create;
  Context.Options.SourcePath := InputPath;
  Context.Options.OutputPath := OutputPath;
  Context.Options.EnableMappingPacks := False;
  Context.Options.ProcessSubdirectories := False;
end;

begin
  Failed := 0; Passed := 0;
  Root := TPath.GetFullPath(TPath.Combine(ParamStr(1), TGUID.NewGuid.ToString));
  try
    Setup('relative');
    OriginalText := TNetEncoding.Base64.EncodeBytesToString(TFile.ReadAllBytes(TPath.Combine(InputPath, 'Example.pas')));
    PreviousDirectory := GetCurrentDir;
    SetCurrentDir(ExtractFilePath(InputPath));
    Context.Options.SourcePath := 'input';
    Context.Options.OutputPath := 'output';
    Engine := TConverterEngine.Create(Context);
    try
      Check(Engine.Convert(Context), 'relative paths convert successfully');
      Check(TFile.Exists(TPath.Combine(OutputPath, 'Example.pas')), 'relative path writes into output');
      Check(TNetEncoding.Base64.EncodeBytesToString(TFile.ReadAllBytes(TPath.Combine(InputPath, 'Example.pas'))) = OriginalText, 'relative path preserves original source bytes');
    finally SetCurrentDir(PreviousDirectory); Engine.Free; Context.Free; end;

    Setup('empty');
    TFile.Delete(TPath.Combine(InputPath, 'Example.pas'));
    TDirectory.CreateDirectory(TPath.Combine(OutputPath, 'Win32'));
    Sentinel := TPath.Combine(OutputPath, 'Win32\keep.txt');
    TFile.WriteAllText(Sentinel, 'keep');
    Engine := TConverterEngine.Create(Context);
    try
      OriginalText := '';
      Engine.LogCallback := procedure(MessageText: string)
        begin OriginalText := OriginalText + MessageText; end;
      Check(not Engine.Convert(Context) and Context.HasBlockingIssues, 'empty input blocks conversion');
      Check((Engine.EndTime >= Engine.StartTime) and (Pos('No eligible source files', OriginalText) > 0),
        'preflight failures expose a reason and completion time');
      Check(TFile.ReadAllText(Sentinel) = 'keep', 'empty input preserves stale output before cleanup');
    finally Engine.Free; Context.Free; end;

    for Name in ['multiple', 'mismatch', 'matching', 'project-only'] do
    begin
      Setup(Name);
      if Name = 'project-only' then TFile.Delete(TPath.Combine(InputPath, 'Example.pas'));
      TFile.WriteAllText(TPath.Combine(InputPath, 'First.dpr'),
        'program First;' + sLineBreak + 'begin' + sLineBreak + 'end.');
      if Name = 'multiple' then
        TFile.WriteAllText(TPath.Combine(InputPath, 'Second.dpr'), 'program Second; begin end.')
      else if Name = 'mismatch' then
        TFile.WriteAllText(TPath.Combine(InputPath, 'First.dproj'), '<Project><MainSource>Other.dpr</MainSource></Project>')
      else
        TFile.WriteAllText(TPath.Combine(InputPath, 'First.dproj'), '<Project><MainSource>First.dpr</MainSource></Project>');
      Engine := TConverterEngine.Create(Context);
      try
        Outcome := Engine.Convert(Context);
        if (Name = 'matching') or (Name = 'project-only') then Check(Outcome, Name + ' project pair succeeds')
        else begin
          Check(not Outcome and Context.HasBlockingIssues, Name + ' project selection blocks');
          Check(not TFile.Exists(TPath.Combine(OutputPath, 'Example.pas')), Name + ' fails before output writes');
        end;
      finally Engine.Free; Context.Free; end;
    end;

    Setup('lateunicode');
    OriginalText := 'unit Example;' + sLineBreak + '{' + StringOfChar('x', 2000) + '}' + sLineBreak +
      'interface' + sLineBreak + 'const Caption = ''' + #$041F#$0440#$0438#$0432#$0435#$0442 + ''';' + sLineBreak +
      'implementation' + sLineBreak + 'end.';
    TFile.WriteAllBytes(TPath.Combine(InputPath, 'Example.pas'), TEncoding.UTF8.GetBytes(OriginalText));
    Check(VCL2FMXTryReadTextFile(TPath.Combine(InputPath, 'Example.pas'), ReadText, EncodingName) and
      (ReadText = OriginalText), 'UTF-8 without BOM preserves Unicode beyond byte 1001');
    Engine := TConverterEngine.Create(Context);
    try
      Check(Engine.Convert(Context), 'late Unicode converts');
      Check(Pos(#$041F#$0440#$0438#$0432#$0435#$0442, TFile.ReadAllText(TPath.Combine(OutputPath, 'Example.pas'))) > 0,
        'late Unicode survives output');
    finally Engine.Free; Context.Free; end;

    Setup('codepage');
    Check(VCL2FMXUTF8SourceText('unit Example; {$CODEPAGE 1251}') = 'unit Example; {$CODEPAGE UTF8}',
      'inline encoding directives match UTF-8 output');
    OriginalText := '// {$CODEPAGE 1251}' + sLineBreak + 'const Example = ''{$CODEPAGE 1251}'';';
    Check(VCL2FMXUTF8SourceText(OriginalText) = OriginalText, 'codepage examples in comments and strings remain unchanged');
    TFile.WriteAllBytes(TPath.Combine(InputPath, 'Example.pas'),
      TEncoding.UTF8.GetBytes(OriginalText + sLineBreak + #$041F#$0440#$0438#$0432#$0435#$0442));
    Check(VCL2FMXTryReadTextFile(TPath.Combine(InputPath, 'Example.pas'), ReadText, EncodingName) and
      (Pos(#$041F#$0440#$0438#$0432#$0435#$0442, ReadText) > 0), 'codepage examples cannot change UTF-8 detection');
    OriginalText := '{$CODEPAGE 1251}' + sLineBreak + 'unit Example;' + sLineBreak +
      'interface' + sLineBreak + 'const Caption = ''' + #$041F#$0440#$0438#$0432#$0435#$0442 + ''';' + sLineBreak +
      'implementation' + sLineBreak + 'end.';
    LegacyEncoding := TEncoding.GetEncoding(1251);
    try TFile.WriteAllBytes(TPath.Combine(InputPath, 'Example.pas'), LegacyEncoding.GetBytes(OriginalText));
    finally LegacyEncoding.Free; end;
    Check(VCL2FMXTryReadTextFile(TPath.Combine(InputPath, 'Example.pas'), ReadText, EncodingName) and
      (ReadText = OriginalText), 'explicit Cyrillic code page decodes correctly');
    Engine := TConverterEngine.Create(Context);
    try
      Check(Engine.Convert(Context), 'explicit legacy encoding converts');
      ReadText := TFile.ReadAllText(TPath.Combine(OutputPath, 'Example.pas'));
      Check((Pos(#$041F#$0440#$0438#$0432#$0435#$0442, ReadText) > 0) and
        (Pos('{$CODEPAGE UTF8}', ReadText) > 0), 'output preserves Cyrillic and updates encoding directive');
    finally Engine.Free; Context.Free; end;

    if ParamStr(2) = '' then raise Exception.Create('Junction fixture directory is required');
    for Name in ['same-root', 'source-cycle', 'output-link', 'output-hardlink'] do
    begin
      Setup(Name);
      Context.Options.SourcePath := TPath.Combine(ParamStr(2), Name + '\input');
      Context.Options.OutputPath := TPath.Combine(ParamStr(2), Name + '\output');
      Context.Options.ProcessSubdirectories := True;
      Sentinel := TPath.Combine(ParamStr(2), Name + '\input\Example.pas');
      OriginalText := TNetEncoding.Base64.EncodeBytesToString(TFile.ReadAllBytes(Sentinel));
      Engine := TConverterEngine.Create(Context);
      try
        Check(not Engine.Convert(Context) and Context.HasBlockingIssues, Name + ' is blocked');
        Check(TNetEncoding.Base64.EncodeBytesToString(TFile.ReadAllBytes(Sentinel)) = OriginalText, Name + ' preserves source bytes');
      finally Engine.Free; Context.Free; end;
    end;

    Setup('outside-file');
    Sentinel := TPath.Combine(Root, 'Outside.pas');
    TFile.WriteAllText(Sentinel, 'original');
    FileManager := TFileManager.Create(Context);
    try
      Check(not FileManager.SaveConvertedFile(Sentinel, 'changed'), 'per-file containment rejects outside source');
      Check(TFile.ReadAllText(Sentinel) = 'original', 'outside source remains unchanged');
    finally FileManager.Free; Context.Free; end;

    Setup('preview');
    for Name in VCL2FMX_STALE_OUTPUT_FOLDERS do
    begin
      TDirectory.CreateDirectory(TPath.Combine(OutputPath, Name));
      TFile.WriteAllText(TPath.Combine(OutputPath, Name + '\keep.txt'), 'preserve');
    end;
    Context.Options.DryRunPreview := True;
    Engine := TConverterEngine.Create(Context);
    try
      Engine.Convert(Context);
      for Name in VCL2FMX_STALE_OUTPUT_FOLDERS do
      begin
        Sentinel := TPath.Combine(OutputPath, Name + '\keep.txt');
        Check(TFile.Exists(Sentinel), 'preview retains ' + Name);
        if TFile.Exists(Sentinel) then Check(TFile.ReadAllText(Sentinel) = 'preserve', 'preview retains bytes');
      end;
      Check(not TFile.Exists(TPath.Combine(OutputPath, 'Example.pas')), 'preview creates no converted source');
    finally Engine.Free; Context.Free; end;

    Setup('readfailure');
    Engine := TConverterEngine.Create(Context);
    LockedFile := nil;
    try
      Engine.LogCallback := procedure(MessageText: string)
        begin
          if (Pos('Reading Example.pas', MessageText) > 0) and (LockedFile = nil) then
            LockedFile := TFileStream.Create(TPath.Combine(InputPath, 'Example.pas'), fmOpenRead or fmShareExclusive);
        end;
      Outcome := Engine.Convert(Context);
      Check(LockedFile <> nil, 'input locked after enumeration');
      Check(not Outcome and Context.HasBlockingIssues and (Engine.FilesWithErrors > 0), 'unreadable Pascal blocks success');
    finally LockedFile.Free; Engine.Free; Context.Free; end;

    Setup('badpack');
    PackPath := TPath.Combine(Root, 'packs'); TDirectory.CreateDirectory(PackPath);
    TFile.WriteAllText(TPath.Combine(PackPath, 'broken.json'), '{broken');
    Context.Options.EnableMappingPacks := True;
    Context.Options.MappingPackFolder := PackPath;
    Engine := TConverterEngine.Create(Context);
    try
      Engine.Convert(Context);
      Found := False;
      for Issue in Context.Issues do
        if Pos('Mapping pack skipped:', Issue.Message) > 0 then Found := True;
      Check(Found, 'invalid mapping-pack diagnostic survives conversion');
      {$IFDEF REPORT_PATHS}
      Check(Engine.HtmlReportPath <> '', 'successful report exposes current-run path');
      TDirectory.CreateDirectory(TPath.Combine(OutputPath, 'nested-source'));
      Context.Options.SourcePath := TPath.Combine(OutputPath, 'nested-source');
      Check(not Engine.Convert(Context), 'unsafe second run fails');
      Check((Engine.HtmlReportPath = '') and (Engine.TextReportPath = ''), 'failed second run cannot expose old report');
      Check(TFile.Exists(TPath.Combine(OutputPath, 'VCL_to_FMX_Conversion_Report.html')), 'old report retained without being attributed to new run');
      {$ENDIF}
    finally Engine.Free; Context.Free; end;
  except on E: Exception do begin Inc(Failed); Writeln('FAIL: ', E.ClassName, ': ', E.Message); end; end;
  Writeln('Safety contracts: ', Passed, ' passed, ', Failed, ' failed');
  if Failed <> 0 then ExitCode := 1;
end.
