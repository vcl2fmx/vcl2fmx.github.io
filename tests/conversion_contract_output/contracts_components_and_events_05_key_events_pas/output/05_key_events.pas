unit ContractKeyEvents;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractKeyEvents = class(TForm) procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); end;
implementation
procedure TContractKeyEvents.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 13 then Caption := 'enter';
end;
end.
