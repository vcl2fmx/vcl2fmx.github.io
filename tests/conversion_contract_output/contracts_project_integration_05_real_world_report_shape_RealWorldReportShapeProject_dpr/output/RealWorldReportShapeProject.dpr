program RealWorldReportShapeProject;

uses
  FMX.Forms,
  RealWorldMain in 'RealWorldMain.pas' {RealWorldForm};

begin
  Application.Initialize;

  Application.CreateForm(TRealWorldForm, RealWorldForm);
  Application.Run;
end.
