unit ContractGetMessageWithMessageVariable;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractGetMessageWithMessageVariable = class public procedure Run; end;
implementation
procedure TContractGetMessageWithMessageVariable.Run;
var Message: TMsg;
begin
  GetMessage(Message, 0, 0, 0);
end;
end.

