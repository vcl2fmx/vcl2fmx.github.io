program IncludeProblemProject;

uses
  Vcl.Forms,
  IncludeProblemMain in 'IncludeProblemMain.pas' {IncludeProblemForm};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TIncludeProblemForm, IncludeProblemForm);
  Application.Run;
end.
