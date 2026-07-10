program ContractHarness;

uses
  System.StartUpCopy,
  FMX.Forms,
  ContractSendMessageWMUserOffset in '10_sendmessage_wm_user_offset.pas',
  FMXMessageBridge in 'FMXMessageBridge.pas';

begin
  Application.Initialize;
  Application.Run;
end.
