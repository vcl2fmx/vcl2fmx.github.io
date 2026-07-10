unit ContractMultilineRealSendMessage;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.StdCtrls;

type
  TContractMultilineRealSendMessage = class
  private
    Memo1: TMemo;
  public
    procedure Run;
  end;

implementation

procedure TContractMultilineRealSendMessage.Run;
begin
  SendMessage(
    Memo1.Handle,
    WM_VSCROLL,
    SB_TOP,
    0);
end;

end.

