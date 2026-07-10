unit ContractPostMessageSystemCommandMinimize;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.Forms;
type TContractPostMessageSystemCommandMinimize = class(TForm) public procedure Run; end;
implementation
procedure TContractPostMessageSystemCommandMinimize.Run;
begin
  PostMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
end;
end.

