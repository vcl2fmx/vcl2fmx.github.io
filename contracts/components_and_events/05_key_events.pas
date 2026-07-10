unit ContractKeyEvents;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls;
type TContractKeyEvents = class(TForm) procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); end;
implementation
procedure TContractKeyEvents.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 13 then Caption := 'enter';
end;
end.

