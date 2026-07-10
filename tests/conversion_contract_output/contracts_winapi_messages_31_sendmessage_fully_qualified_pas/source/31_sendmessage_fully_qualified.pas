unit ContractSendMessageFullyQualified;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractSendMessageFullyQualified = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractSendMessageFullyQualified.Run;
begin
  Winapi.Windows.SendMessage(FHandle, WM_CLOSE, 0, 0);
end;
end.

