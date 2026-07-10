unit ContractSendMessageIfCondition;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractSendMessageIfCondition = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractSendMessageIfCondition.Run;
begin
  if SendMessage(FHandle, WM_USER + 1, 0, 0) <> 0 then
    Writeln('sent');
end;
end.

