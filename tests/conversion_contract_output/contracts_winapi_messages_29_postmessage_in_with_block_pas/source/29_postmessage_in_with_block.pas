unit ContractPostMessageInWithBlock;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.Forms;
type TContractPostMessageInWithBlock = class(TForm) public procedure Run; end;
implementation
procedure TContractPostMessageInWithBlock.Run;
begin
  with Self do
    PostMessage(Handle, WM_CLOSE, 0, 0);
end;
end.

