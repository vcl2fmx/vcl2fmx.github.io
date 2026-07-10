unit ContractSendMessageCBSelectString;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.ListBox, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractSendMessageCBSelectString = class private ComboBox1: TComboBox; public procedure Run; end;
implementation
procedure TContractSendMessageCBSelectString.Run;
begin
  { FMX: CB_SELECTSTRING - Use FMX list box or combo box item, selection, and data APIs instead of list/combo control messages. }
  { Original: SendMessage(ComboBox1.Handle, CB_SELECTSTRING, WPARAM(-1), LPARAM(PChar('abc'))); }
end;
end.
