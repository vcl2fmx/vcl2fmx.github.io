unit ContractSendMessageInCommentAndCode;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractSendMessageInCommentAndCode = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractSendMessageInCommentAndCode.Run;
begin
  // SendMessage(FHandle, WM_CLOSE, 0, 0);
  SendMessage(FHandle, WM_SIZE, 0, 0);
end;
end.

