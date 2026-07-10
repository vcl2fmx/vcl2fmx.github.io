unit ContractSendMessageIfCondition;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractSendMessageIfCondition = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractSendMessageIfCondition.Run;
begin
  { FMX: Replace with TMessageManager - SendMessage removed }
  { Original: if SendMessage(FHandle, WM_USER + 1, 0, 0) <> 0 then }
  { TMessageManager.DefaultManager.SendMessage(Self, TMyMsg.Create(lParam)); }
    Writeln('sent');
end;
end.
