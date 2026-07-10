unit ContractUserSendMessageWithHandleWordString;
interface
uses System.SysUtils, System.Classes;
type TContractUserSendMessageWithHandleWordString = class public procedure SendMessage(const AText: string); procedure Run; end;
implementation
procedure TContractUserSendMessageWithHandleWordString.SendMessage(const AText: string);
begin
  Writeln(AText);
end;
procedure TContractUserSendMessageWithHandleWordString.Run;
begin
  SendMessage('Handle this as domain text, not HWND');
end;
end.

