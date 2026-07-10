program WindowsMessagingProject;

uses
  Vcl.Forms,
  WindowsMessagingMain in 'WindowsMessagingMain.pas' {WindowsMessagingForm};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TWindowsMessagingForm, WindowsMessagingForm);
  Application.Run;
end.
