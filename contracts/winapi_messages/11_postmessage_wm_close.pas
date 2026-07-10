unit ContractPostMessageWMClose;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.Forms;
type TContractPostMessageWMClose = class(TForm) public procedure Run; end;
implementation
procedure TContractPostMessageWMClose.Run;
begin
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;
end.

