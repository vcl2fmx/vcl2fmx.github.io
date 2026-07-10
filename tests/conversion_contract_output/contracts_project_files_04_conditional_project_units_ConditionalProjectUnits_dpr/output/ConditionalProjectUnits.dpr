program ConditionalProjectUnits;
uses
  FMX.Forms,
  {$IFDEF USE_EXTRA}
  ExtraUnit in 'ExtraUnit.pas',
  {$ENDIF}
  MainUnit in 'MainUnit.pas';
begin
  Application.Initialize;
  Application.Run;
end.

