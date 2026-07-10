unit ContractSendMessageCBSelectString;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.StdCtrls;
type TContractSendMessageCBSelectString = class private ComboBox1: TComboBox; public procedure Run; end;
implementation
procedure TContractSendMessageCBSelectString.Run;
begin
  SendMessage(ComboBox1.Handle, CB_SELECTSTRING, WPARAM(-1), LPARAM(PChar('abc')));
end;
end.

