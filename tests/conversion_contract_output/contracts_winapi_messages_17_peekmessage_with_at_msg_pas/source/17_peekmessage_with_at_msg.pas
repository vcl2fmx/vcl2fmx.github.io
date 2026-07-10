unit ContractPeekMessageWithAtMsg;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractPeekMessageWithAtMsg = class public procedure Run; end;
implementation
procedure TContractPeekMessageWithAtMsg.Run;
var Msg: TMsg;
begin
  PeekMessage(@Msg, 0, 0, 0, PM_REMOVE);
end;
end.

