unit ContractTimerEvent;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractTimerEvent = class(TForm) Timer1: TTimer; procedure Timer1Timer(Sender: TObject); end;
implementation
procedure TContractTimerEvent.Timer1Timer(Sender: TObject);
begin
  Caption := TimeToStr(Now);
end;
end.
