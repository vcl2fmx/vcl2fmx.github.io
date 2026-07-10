unit ContractSendMessageLBSelectString;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.ListBox, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractSendMessageLBSelectString = class private ListBox1: TListBox; public procedure Run; end;
implementation
procedure TContractSendMessageLBSelectString.Run;
begin
  { FMX: LB_SELECTSTRING - Use FMX list box or combo box item, selection, and data APIs instead of list/combo control messages. }
  { Original: SendMessage(ListBox1.Handle, LB_SELECTSTRING, WPARAM(-1), LPARAM(PChar('abc'))); }
end;
end.
