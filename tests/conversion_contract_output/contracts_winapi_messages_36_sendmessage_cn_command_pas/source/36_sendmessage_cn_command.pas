unit ContractSendMessageCNCommand;

interface

uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;

type
  TContractSendMessageCNCommand = class
  private
    FHandle: HWND;
  public
    procedure Run;
  end;

implementation

procedure TContractSendMessageCNCommand.Run;
begin
  SendMessage(FHandle, CN_COMMAND, 0, 0);
end;

end.
