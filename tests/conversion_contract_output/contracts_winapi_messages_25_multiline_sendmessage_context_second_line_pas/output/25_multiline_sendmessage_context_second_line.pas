unit ContractMultilineSendMessageContextSecondLine;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractMultilineSendMessageContextSecondLine = class private TargetWindow: HWND; public procedure Run; end;
implementation
procedure TContractMultilineSendMessageContextSecondLine.Run;
begin
  // FMX manual review: SendMessage(
  // FMX manual review: TargetWindow,
  // FMX manual review: WM_SIZE,
  // FMX manual review: 0,
  // FMX manual review: 0);
end;
end.
