unit ContractMultilineRealSendMessage;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Memo, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type
  TMemo = class(FMX.Memo.TMemo)
  public
    procedure Clear; reintroduce;
  end;
  TContractMultilineRealSendMessage = class
  private
    Memo1: TMemo;
  public
    procedure Run;
  end;
implementation
procedure TMemo.Clear;
begin
  Lines.Clear;
end;
procedure TContractMultilineRealSendMessage.Run;
begin
  // FMX manual review: SendMessage(
  // FMX manual review: Memo1.Handle,
  // FMX manual review: WM_VSCROLL,
  // FMX manual review: SB_TOP,
  // FMX manual review: 0);
end;
end.
