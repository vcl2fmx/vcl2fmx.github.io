unit ContractMultilinePostMessageContextSecondLine;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractMultilinePostMessageContextSecondLine = class private TargetWindow: HWND; public procedure Run; end;
implementation
procedure TContractMultilinePostMessageContextSecondLine.Run;
begin
  PostMessage(
    TargetWindow,
    WM_CLOSE,
    0,
    0);
end;
end.

