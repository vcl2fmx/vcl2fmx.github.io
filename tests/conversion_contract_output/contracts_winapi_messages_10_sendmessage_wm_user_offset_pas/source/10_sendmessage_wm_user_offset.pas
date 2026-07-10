unit ContractSendMessageWMUserOffset;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractSendMessageWMUserOffset = class public procedure Run; end;
implementation
procedure TContractSendMessageWMUserOffset.Run;
begin
  SendMessage(HWND_BROADCAST, WM_USER + 42, 123, 456);
end;
end.

