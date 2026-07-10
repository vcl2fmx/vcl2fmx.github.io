program RunMemoStringsRegression;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Converter.Core.Types,
  Converter.Core.Engine;

var
  Context: TConversionContext;
  Engine: TConverterEngine;
  Root: string;
begin
  Root := IncludeTrailingPathDelimiter(GetCurrentDir);

  Context := TConversionContext.Create;
  try
    Context.Options.SourcePath := ExpandFileName(Root + 'samples\tmemo_strings_regression');
    Context.Options.OutputPath := ExpandFileName(Root + 'samples\tmemo_strings_regression\output');
    Context.Options.ProcessSubdirectories := False;
    Context.Options.CreateReport := True;
    Context.Options.MappingPackFolder := ExpandFileName(Root + 'mapping_packs');

    Engine := TConverterEngine.Create(Context);
    try
      if not Engine.Convert(Context) then
        Halt(1);
    finally
      Engine.Free;
    end;
  finally
    Context.Free;
  end;
end.
