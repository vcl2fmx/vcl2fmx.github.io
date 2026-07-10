program UsesCleanupProject;

uses
  FMX.Forms,
  UsesCleanupMain in 'UsesCleanupMain.pas' {UsesCleanupForm};

begin
  Application.Initialize;

  Application.CreateForm(TUsesCleanupForm, UsesCleanupForm);
  Application.Run;
end.
