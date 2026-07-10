unit ContractUserSendMessageWithHandleWordString;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
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
