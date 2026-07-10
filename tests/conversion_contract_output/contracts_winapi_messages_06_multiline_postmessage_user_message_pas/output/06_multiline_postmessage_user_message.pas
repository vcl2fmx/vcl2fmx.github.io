unit ContractMultilinePostMessageUserMessage;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type
  TContractMultilinePostMessageUserMessage = class
  private
    FHandle: HWND;
  public
    procedure Run;
  end;
implementation
procedure TContractMultilinePostMessageUserMessage.Run;
begin
  // FMX manual review: PostMessage(
  // FMX manual review: FHandle,
  // FMX manual review: WM_USER + 12,
  // FMX manual review: 1,
  // FMX manual review: 0);
end;
end.
