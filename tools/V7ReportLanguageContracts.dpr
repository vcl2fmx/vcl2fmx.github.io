program V7ReportLanguageContracts;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.IOUtils, System.Classes, System.StrUtils,
  DAT.Runtime.Manager, Converter.Core.Types, Converter.Core.Engine;
var
  Root, InputPath, OutputPath, PackFile, Code, Html, ReportText, JsonText, Evidence: string;
  Runtime: TTranslationRuntime;
  Context: TConversionContext;
  Engine: TConverterEngine;
  Checks: Integer;
begin
  Checks := 0;
  try
    Root := TPath.Combine(ParamStr(2), TGUID.NewGuid.ToString);
    InputPath := TPath.Combine(Root, 'Component reference');
    TDirectory.CreateDirectory(InputPath);
    TFile.WriteAllText(TPath.Combine(InputPath, 'Example.pas'),
      'unit Example;' + sLineBreak + 'interface' + sLineBreak + 'implementation' + sLineBreak + 'end.', TEncoding.UTF8);
    Evidence := 'TButton.Caption := ''Component reference'';';
    Runtime := TTranslationRuntime.Create('VCL2FMXConverter', ParamStr(1), TPath.Combine(Root, 'report-test.ini'), 'en-US', 'FireMonkey');
    try
      for PackFile in TDirectory.GetFiles(ParamStr(1), '*.json') do
      begin
        Code := TPath.GetFileNameWithoutExtension(PackFile);
        Writeln(Code); Flush(Output);
        if not Runtime.LoadLanguage(Code) then raise Exception.Create('Cannot load ' + Code);
        OutputPath := TPath.Combine(Root, Code);
        Context := TConversionContext.Create;
        Context.Options.SourcePath := InputPath;
        Context.Options.OutputPath := OutputPath;
        Context.Options.EnableMappingPacks := False;
        Engine := TConverterEngine.Create(Context);
        try
          Engine.ReportLanguageCode := Code;
          Engine.ReportTextDirection := Runtime.ActivePack.TextDirection;
          Engine.ReportTextTranslator := function(Value: string): string
            begin Result := Runtime.TranslateDynamicText(Value); end;
          Engine.ReportHtmlTranslator := function(Value: string): string
            begin Result := Runtime.TranslateHtmlText(Value); end;
          Engine.LogCallback := procedure(MessageText: string)
            begin
              if Pos('Reading Example.pas', MessageText) > 0 then
                Context.AddManualReview('Manual review required', 'Manual replacement required', Evidence,
                  'Review the generated report and any mapping suggestions, then run conversion again with dry-run disabled to write converted source and project artifacts.');
            end;
          Engine.Convert(Context);
          if (Engine.TextReportPath = '') or (Engine.HtmlReportPath = '') then raise Exception.Create(Code + ': report missing');
          ReportText := TFile.ReadAllText(Engine.TextReportPath, TEncoding.UTF8);
          Html := TFile.ReadAllText(Engine.HtmlReportPath, TEncoding.UTF8);
          JsonText := TFile.ReadAllText(TPath.Combine(OutputPath, 'VCL_to_FMX_Conversion_Report.json'), TEncoding.UTF8);
          if (Code <> 'en-US') and (ContainsStr(ReportText, 'CONVERSION SUMMARY') or ContainsStr(Html, '<h1>Conversion Report</h1>')) then
            raise Exception.Create(Code + ': report heading remains English');
          if not ContainsStr(ReportText, InputPath) or not ContainsStr(Html, InputPath) then raise Exception.Create(Code + ': source path changed');
          if not ContainsStr(ReportText, Evidence) then raise Exception.Create(Code + ': Pascal evidence changed');
          if not ContainsStr(JsonText, 'Manual replacement required') then raise Exception.Create(Code + ': canonical JSON narrative changed');
          if not ContainsStr(Html, '<html lang="' + Code + '" dir="' + Runtime.ActivePack.TextDirection + '">') then raise Exception.Create(Code + ': report locale metadata missing');
          if ContainsStr(ReportText, #$E000) or ContainsStr(Html, #$E000) then raise Exception.Create(Code + ': protection token leaked');
          Inc(Checks);
        finally Engine.Free; Context.Free; end;
      end;
    finally Runtime.Free; end;
    Writeln('PASS: ', Checks, ' saved-report language, data-protection and JSON contracts.');
  except on E: Exception do begin Writeln('FAIL: ', E.Message); ExitCode := 1; end; end;
end.
