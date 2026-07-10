unit ContractPostMessageHwndCast;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractPostMessageHwndCast = class public procedure Run; end;
implementation
procedure TContractPostMessageHwndCast.Run;
begin
  { FMX: WM_CLOSE - Use Close or OnCloseQuery rather than posting WM_CLOSE. }
  { FMX: Preserve async behavior with TThread.Queue only if the original timing matters. }
  { Original: PostMessage(HWND(0), WM_CLOSE, 0, 0); }
  { TThread.Queue(nil, procedure begin TMessageManager.DefaultManager.SendMessage(Self, TMyMsg.Create(lParam)); end); }
end;
end.
