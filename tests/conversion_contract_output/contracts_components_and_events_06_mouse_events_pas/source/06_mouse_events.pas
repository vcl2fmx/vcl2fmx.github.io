unit ContractMouseEvents;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls;
type TContractMouseEvents = class(TForm) procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer); end;
implementation
procedure TContractMouseEvents.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Caption := IntToStr(X + Y);
end;
end.

