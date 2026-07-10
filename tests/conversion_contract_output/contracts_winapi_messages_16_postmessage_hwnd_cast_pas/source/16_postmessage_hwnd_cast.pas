unit ContractPostMessageHwndCast;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractPostMessageHwndCast = class public procedure Run; end;
implementation
procedure TContractPostMessageHwndCast.Run;
begin
  PostMessage(HWND(0), WM_CLOSE, 0, 0);
end;
end.

