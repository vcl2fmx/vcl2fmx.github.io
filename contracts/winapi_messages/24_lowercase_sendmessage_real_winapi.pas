unit ContractLowercaseSendMessageRealWinapi;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractLowercaseSendMessageRealWinapi = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractLowercaseSendMessageRealWinapi.Run;
begin
  sendmessage(FHandle, wm_close, 0, 0);
end;
end.

