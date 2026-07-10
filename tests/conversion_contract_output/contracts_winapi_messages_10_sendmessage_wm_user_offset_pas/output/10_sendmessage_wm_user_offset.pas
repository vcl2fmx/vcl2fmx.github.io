unit ContractSendMessageWMUserOffset;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractSendMessageWMUserOffset = class public procedure Run; end;
implementation
procedure TContractSendMessageWMUserOffset.Run;
begin
  { FMX: Replace with TMessageManager - SendMessage removed }
  { Original: SendMessage(HWND_BROADCAST, WM_USER + 42, 123, 456); }
  { TMessageManager.DefaultManager.SendMessage(Self, TMyMsg.Create(lParam)); }
end;
end.
