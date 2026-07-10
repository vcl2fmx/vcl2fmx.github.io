unit ContractTimerEvent;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls;
type TContractTimerEvent = class(TForm) Timer1: TTimer; procedure Timer1Timer(Sender: TObject); end;
implementation
procedure TContractTimerEvent.Timer1Timer(Sender: TObject);
begin
  Caption := TimeToStr(Now);
end;
end.

