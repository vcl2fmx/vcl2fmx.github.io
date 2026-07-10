unit ContractPostMessageSystemCommandMinimize;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractPostMessageSystemCommandMinimize = class(TForm) public procedure Run; end;
implementation
procedure TContractPostMessageSystemCommandMinimize.Run;
begin
  { FMX: WM_SYSCOMMAND / SC_MINIMIZE - For minimize behavior, use the FMX form WindowState where supported, or platform-specific code when the target requires it. }
  { FMX: Preserve async behavior with TThread.Queue only if the original timing matters. }
  { Original: PostMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0); }
  { TThread.Queue(nil, procedure begin TMessageManager.DefaultManager.SendMessage(Self, TMyMsg.Create(lParam)); end); }
end;
end.
