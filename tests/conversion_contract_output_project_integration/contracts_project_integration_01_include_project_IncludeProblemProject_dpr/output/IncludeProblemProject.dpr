program IncludeProblemProject;

uses
  FMX.Forms,
  IncludeProblemMain in 'IncludeProblemMain.pas' {IncludeProblemForm};

begin
  Application.Initialize;

  Application.CreateForm(TIncludeProblemForm, IncludeProblemForm);
  Application.Run;
end.
