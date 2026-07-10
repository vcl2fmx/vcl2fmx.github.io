unit ContractSendMessageHandleVariable;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractSendMessageHandleVariable = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractSendMessageHandleVariable.Run;
begin
  SendMessage(FHandle, WM_SIZE, 0, 0);
end;
end.

