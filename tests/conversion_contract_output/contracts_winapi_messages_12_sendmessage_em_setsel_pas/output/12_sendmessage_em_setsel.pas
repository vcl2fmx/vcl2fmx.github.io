unit ContractSendMessageEMSetSel;
interface
uses FMX.Controls, FMX.Edit, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractSendMessageEMSetSel = class private Edit1: TEdit; public procedure Run; end;
implementation
procedure TContractSendMessageEMSetSel.Run;
begin
  { FMX: EM_SETSEL - Use FMX edit/memo text, selection, caret, and clipboard APIs instead of edit control messages. }
  { Original: SendMessage(Edit1.Handle, EM_SETSEL, 0, -1); }
end;
end.
