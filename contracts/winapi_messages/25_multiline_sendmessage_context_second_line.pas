unit ContractMultilineSendMessageContextSecondLine;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractMultilineSendMessageContextSecondLine = class private TargetWindow: HWND; public procedure Run; end;
implementation
procedure TContractMultilineSendMessageContextSecondLine.Run;
begin
  SendMessage(
    TargetWindow,
    WM_SIZE,
    0,
    0);
end;
end.

