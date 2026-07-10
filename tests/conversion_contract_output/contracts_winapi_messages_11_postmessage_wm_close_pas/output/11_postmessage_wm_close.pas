unit ContractPostMessageWMClose;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractPostMessageWMClose = class(TForm) public procedure Run; end;
implementation
procedure TContractPostMessageWMClose.Run;
begin
  { FMX: WM_CLOSE - Use Close or OnCloseQuery rather than posting WM_CLOSE. }
  { FMX: Preserve async behavior with TThread.Queue only if the original timing matters. }
  { Original: PostMessage(Handle, WM_CLOSE, 0, 0); }
  { TThread.Queue(nil, procedure begin TMessageManager.DefaultManager.SendMessage(Self, TMyMsg.Create(lParam)); end); }
end;
end.
