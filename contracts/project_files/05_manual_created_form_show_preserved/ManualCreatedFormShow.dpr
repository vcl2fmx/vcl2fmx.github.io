program ManualCreatedFormShow;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  SecondaryUnit in 'SecondaryUnit.pas' {SecondaryForm};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSecondaryForm, SecondaryForm);
  SecondaryForm.Show;
  Application.Run;
end.
