unit ContractSendMessageEMSetSel;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.StdCtrls;
type TContractSendMessageEMSetSel = class private Edit1: TEdit; public procedure Run; end;
implementation
procedure TContractSendMessageEMSetSel.Run;
begin
  SendMessage(Edit1.Handle, EM_SETSEL, 0, -1);
end;
end.

