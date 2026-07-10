unit ContractPenBrushFont;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.Graphics;
type TContractPenBrushFont = class(TForm) procedure Run; end;
implementation
procedure TContractPenBrushFont.Run;
begin
  Canvas.Pen.Color := clRed;
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Color := clBlue;
end;
end.

