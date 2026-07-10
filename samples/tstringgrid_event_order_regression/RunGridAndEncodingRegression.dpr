program RunGridAndEncodingRegression;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  Converter.Core.Types,
  Converter.Core.Engine;

procedure RunConversion(const SourceFolder, OutputFolder: string);
var
  Context: TConversionContext;
  Engine: TConverterEngine;
begin
  Context := TConversionContext.Create;
  try
    Context.Options.SourcePath := SourceFolder;
    Context.Options.OutputPath := OutputFolder;
    Context.Options.ProcessSubdirectories := False;
    Context.Options.CreateReport := True;
    Context.Options.MappingPackFolder := ExpandFileName('mapping_packs');

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
end;

begin
  RunConversion(
    ExpandFileName('samples\tstringgrid_event_order_regression'),
    ExpandFileName('samples\tstringgrid_event_order_regression\output'));

  RunConversion(
    ExpandFileName('samples\fmx_utf8_accent_regression'),
    ExpandFileName('samples\fmx_utf8_accent_regression\output'));
end.
