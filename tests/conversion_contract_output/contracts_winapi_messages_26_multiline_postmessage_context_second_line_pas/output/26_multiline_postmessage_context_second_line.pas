unit ContractMultilinePostMessageContextSecondLine;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractMultilinePostMessageContextSecondLine = class private TargetWindow: HWND; public procedure Run; end;
implementation
procedure TContractMultilinePostMessageContextSecondLine.Run;
begin
  // FMX manual review: PostMessage(
  // FMX manual review: TargetWindow,
  // FMX manual review: WM_CLOSE,
  // FMX manual review: 0,
  // FMX manual review: 0);
end;
end.
