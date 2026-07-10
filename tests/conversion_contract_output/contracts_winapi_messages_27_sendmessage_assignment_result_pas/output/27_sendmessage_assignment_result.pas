unit ContractSendMessageAssignmentResult;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Memo, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractSendMessageAssignmentResult = class private Memo1: TMemo; public procedure Run; end;
implementation
procedure TMemo.Clear;
begin
  Lines.Clear;
end;
procedure TContractSendMessageAssignmentResult.Run;
var L: NativeInt;
begin
  { FMX: EM_LINEFROMCHAR - Use FMX edit/memo text, selection, caret, and clipboard APIs instead of edit control messages. }
  { Original: L := SendMessage(Memo1.Handle, EM_LINEFROMCHAR, Memo1.SelStart, 0); }
end;
end.
