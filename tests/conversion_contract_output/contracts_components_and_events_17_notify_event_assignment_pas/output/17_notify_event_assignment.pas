unit ContractNotifyEventAssignment;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractNotifyEventAssignment = class(TForm) Timer1: TTimer; procedure Run; procedure OnTick(Sender: TObject); end;
implementation
procedure TContractNotifyEventAssignment.Run;
begin
  Timer1.OnTimer := OnTick;
end;
procedure TContractNotifyEventAssignment.OnTick(Sender: TObject);
begin
end;
end.
