unit ContractMultilineIfSendMessageWithBegin;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractMultilineIfSendMessageWithBegin = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractMultilineIfSendMessageWithBegin.Run;
begin
  // FMX manual review: if SendMessage(
  // FMX manual review: FHandle,
  // FMX manual review: WM_CLOSE,
  // FMX manual review: 0,
  // FMX manual review: 0) <> 0 then
  begin
    Writeln('closed');
  end;
end;
end.
