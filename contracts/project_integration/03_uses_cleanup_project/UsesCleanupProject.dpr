program UsesCleanupProject;

uses
  Vcl.Forms,
  UsesCleanupMain in 'UsesCleanupMain.pas' {UsesCleanupForm};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TUsesCleanupForm, UsesCleanupForm);
  Application.Run;
end.
