unit ContractSendMessageAssignmentResult;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.StdCtrls;
type TContractSendMessageAssignmentResult = class private Memo1: TMemo; public procedure Run; end;
implementation
procedure TContractSendMessageAssignmentResult.Run;
var L: NativeInt;
begin
  L := SendMessage(Memo1.Handle, EM_LINEFROMCHAR, Memo1.SelStart, 0);
end;
end.

