unit ContractStringGridDrawCell;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.Grids, Vcl.Graphics;
type TContractStringGridDrawCell = class(TForm) StringGrid1: TStringGrid; procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); end;
implementation
procedure TContractStringGridDrawCell.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
begin
  StringGrid1.Canvas.TextOut(Rect.Left, Rect.Top, 'x');
end;
end.

