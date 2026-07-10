program WindowsMessagingProject;

uses
  FMX.Forms,
  WindowsMessagingMain in 'WindowsMessagingMain.pas' {WindowsMessagingForm},
  FMXMessageBridge in 'FMXMessageBridge.pas';

begin
  Application.Initialize;

  Application.CreateForm(TWindowsMessagingForm, WindowsMessagingForm);
  Application.Run;
end.
