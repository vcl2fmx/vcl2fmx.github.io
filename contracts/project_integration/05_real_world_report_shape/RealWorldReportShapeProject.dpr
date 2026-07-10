program RealWorldReportShapeProject;

uses
  Vcl.Forms,
  RealWorldMain in 'RealWorldMain.pas' {RealWorldForm};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TRealWorldForm, RealWorldForm);
  Application.Run;
end.
