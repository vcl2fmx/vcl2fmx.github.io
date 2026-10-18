program V7TranslationContracts;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.IOUtils, System.StrUtils, System.JSON,
  System.NetEncoding, DAT.Runtime.Manager;
const
  Phrases: array[0..24] of string = ('Component reference','Component Mapping Reference','Property reference','Property Mapping Reference','Event reference','Event Mapping Reference','Reference notes','Discoverable components','Direct conversions','Substitute mappings','Manual review','Property rules','Direct rules','Renamed rules','Transformed rules','Event rules','Direct events','Renamed events','Signature review','Uses an explicit event rule from the built-in mapper.','Derived from RTTI inventory because the same published event exists on the FMX target.','Choose a VCL source folder and an FMX output folder, then start the conversion.','Use TRectangle with appropriate Fill and Stroke','Manual replacement required','Mapping pack');
var
  Runtime: TTranslationRuntime;
  FileName, Code, Phrase, Original, Translated: string;
  Checks, MappingChecks, ExpectedMappingChecks, LanguageMappingChecks: Integer;
  Pack: TJSONObject;
  Entry: TJSONPair;
begin
  Checks := 0;
  MappingChecks := 0;
  ExpectedMappingChecks := 0;
  try
    Pack := TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(ParamStr(1), 'en-US.json'))) as TJSONObject;
    try
      for Entry in Pack.GetValue<TJSONObject>('sources') do
        if StartsStr('Converter.Mapping.Strings.', Entry.JsonString.Value) then Inc(ExpectedMappingChecks);
    finally
      Pack.Free;
    end;
    Runtime := TTranslationRuntime.Create('VCL2FMXConverter', ParamStr(1),
      TPath.Combine(ParamStr(2), 'contract-language.ini'), 'en-US', 'FireMonkey');
    try
      for FileName in TDirectory.GetFiles(ParamStr(1), '*.json') do
      begin
        Code := TPath.GetFileNameWithoutExtension(FileName);
        if not Runtime.LoadLanguage(Code) then
          raise Exception.Create('Pack failed to load: ' + Code);
        Pack := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName)) as TJSONObject;
        LanguageMappingChecks := 0;
        try
          for Entry in Pack.GetValue<TJSONObject>('sources') do
            if StartsStr('Converter.Mapping.Strings.', Entry.JsonString.Value) then
            begin
              Phrase := TNetEncoding.HTML.Encode(Entry.JsonValue.Value);
              Original := '<td>Uses an explicit event rule from the built-in mapper. ' +
                Phrase + '</td><code>TButton.OnClick</code>';
              Translated := Runtime.TranslateHtmlText(Original);
              if (Code <> 'en-US') and (ContainsStr(Translated, Phrase) or
                ContainsStr(Translated, 'Uses an explicit event rule from the built-in mapper.')) then
                raise Exception.Create(Code + ': bundled mapping prose remains English: ' + Entry.JsonValue.Value);
              if not ContainsStr(Translated, '<code>TButton.OnClick</code>') then
                raise Exception.Create(Code + ': mapping code identifier changed');
              Inc(MappingChecks);
              Inc(LanguageMappingChecks);
            end;
        finally
          Pack.Free;
        end;
        if LanguageMappingChecks <> ExpectedMappingChecks then
          raise Exception.CreateFmt('%s: only %d of %d bundled mapping descriptions are registered',
            [Code, LanguageMappingChecks, ExpectedMappingChecks]);
        for Phrase in Phrases do
        begin
          Original := '<h2>' + Phrase + '</h2><code>TButton</code>';
          Translated := Runtime.TranslateHtmlText(Original);
          if (Code <> 'en-US') and ContainsText(Translated, '<h2>' + Phrase + '</h2>') then
            raise Exception.Create(Code + ': untranslated HTML heading: ' + Phrase);
          if not ContainsStr(Translated, '<code>TButton</code>') then
            raise Exception.Create(Code + ': protected code was changed');
          Inc(Checks);
        end;
        if Runtime.TranslateDynamicText('VCL to FMX Converter') <> 'VCL to FMX Converter' then
          raise Exception.Create(Code + ': product identity changed');
        Original := '<td>Derived from RTTI inventory because the same published event exists on the FMX target. Use TRectangle with appropriate Fill and Stroke</td>';
        Translated := Runtime.TranslateHtmlText(Original);
        if (Code <> 'en-US') and (ContainsStr(Translated, 'Derived from RTTI inventory because') or ContainsStr(Translated, 'with appropriate Fill and Stroke')) then
          raise Exception.Create(Code + ': combined mapping notes remain English');
        if Code = 'ja-JP' then
        begin
          Translated := Runtime.TranslateDynamicText('Processing Pascal: Unit1.pas');
          if ContainsStr(Translated, 'Processing Pascal:') or not ContainsStr(Translated, 'Unit1.pas') then
            raise Exception.Create('Japanese processing message or filename is incorrect');
        end;
        if Code = 'fil-PH' then
          if (Runtime.TranslateHtmlText('<span>Direct</span>') = '<span>Direct</span>') or
             (Runtime.TranslateHtmlText('<span>Compatible</span>') = '<span>Compatible</span>') then
            raise Exception.Create('Filipino mapping badges remain English');
        if not Runtime.LoadLanguage('en-US') then
          raise Exception.Create('Return to English failed');
        if Runtime.TranslateHtmlText('<h2>Component reference</h2>') <>
          '<h2>Component reference</h2>' then
          raise Exception.Create('Cached foreign heading survived return to English');
      end;
    finally
      Runtime.Free;
    end;
    Writeln('PASS: ', Checks, ' HTML headings; code protection and return to English.');
    if MappingChecks = 0 then raise Exception.Create('No bundled mapping descriptions were tested');
    Writeln('PASS: ', MappingChecks, ' combined bundled mapping description checks.');
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
