unit ContractStringGridDrawCell;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Grid, FMX.Grid.Style, FMX.Types, System.Classes,
  System.SysUtils, System.Variants;
type TContractStringGridDrawCell = class(TForm) StringGrid1: TStringGrid; procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); end;
implementation
procedure TContractStringGridDrawCell.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
begin
  StringGrid1.Canvas.TextOut(Rect.Left, Rect.Top, 'x');
end;
end.
