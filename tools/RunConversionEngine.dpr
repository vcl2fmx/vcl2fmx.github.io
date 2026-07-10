program RunConversionEngine;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Converter.Core.Types,
  Converter.Core.Engine;

var
  Context: TConversionContext;
  Engine: TConverterEngine;
begin
  if ParamCount < 2 then
  begin
    Writeln('Usage: RunConversionEngine <source-folder> <output-folder> [--dry-run]');
    Halt(1);
  end;

  Context := TConversionContext.Create;
  try
    Context.Options.SourcePath := ParamStr(1);
    Context.Options.OutputPath := ParamStr(2);
    Context.Options.ProcessSubdirectories := False;
    Context.Options.CreateReport := True;
    Context.Options.EnableCriticalAreas := True;
    Context.Options.EnableDataAware := True;
    Context.Options.EnableThirdParty := True;
    Context.Options.EnableWinAPI := True;
    Context.Options.FileTypes := ftBoth;
    Context.Options.DryRunPreview := (ParamCount >= 3) and SameText(ParamStr(3), '--dry-run');

    Engine := TConverterEngine.Create(Context);
    try
      if Engine.Convert(Context) then
        Halt(0)
      else
        Halt(2);
    finally
      Engine.Free;
    end;
  finally
    Context.Free;
  end;
end.
