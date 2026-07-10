unit ContractMultilinePostMessageUserMessage;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.Forms;

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
  PostMessage(
    FHandle,
    WM_USER + 12,
    1,
    0);
end;

end.

