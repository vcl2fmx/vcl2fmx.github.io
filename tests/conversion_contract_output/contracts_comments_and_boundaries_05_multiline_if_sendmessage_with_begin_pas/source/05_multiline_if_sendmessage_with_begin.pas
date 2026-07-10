unit ContractMultilineIfSendMessageWithBegin;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractMultilineIfSendMessageWithBegin = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractMultilineIfSendMessageWithBegin.Run;
begin
  if SendMessage(
    FHandle,
    WM_CLOSE,
    0,
    0) <> 0 then
  begin
    Writeln('closed');
  end;
end;
end.

