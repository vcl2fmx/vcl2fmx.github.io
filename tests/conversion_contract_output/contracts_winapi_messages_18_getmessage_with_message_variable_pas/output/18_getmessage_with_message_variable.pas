unit ContractGetMessageWithMessageVariable;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractGetMessageWithMessageVariable = class public procedure Run; end;
implementation
procedure TContractGetMessageWithMessageVariable.Run;
var Message: TMsg;
begin
  { FMX: Message pump calls not needed - FMX has its own event loop }
  { Original: GetMessage(Message, 0, 0, 0); }
end;
end.
