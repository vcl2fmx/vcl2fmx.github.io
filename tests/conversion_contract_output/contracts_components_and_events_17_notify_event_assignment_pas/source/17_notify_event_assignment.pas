unit ContractNotifyEventAssignment;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls;
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

