unit ContractSendMessageLBSelectString;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.StdCtrls;
type TContractSendMessageLBSelectString = class private ListBox1: TListBox; public procedure Run; end;
implementation
procedure TContractSendMessageLBSelectString.Run;
begin
  SendMessage(ListBox1.Handle, LB_SELECTSTRING, WPARAM(-1), LPARAM(PChar('abc')));
end;
end.

