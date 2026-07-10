unit ContractMultilineIfSendMessageNoBegin;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractMultilineIfSendMessageNoBegin = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractMultilineIfSendMessageNoBegin.Run;
begin
  if SendMessage(
    FHandle,
    WM_CLOSE,
    0,
    0) <> 0 then
    Writeln('closed');
end;
end.

