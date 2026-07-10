unit ContractSendMessageSystemCommandClose;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.Forms;
type TContractSendMessageSystemCommandClose = class(TForm) public procedure Run; end;
implementation
procedure TContractSendMessageSystemCommandClose.Run;
begin
  SendMessage(Handle, WM_SYSCOMMAND, SC_CLOSE, 0);
end;
end.

