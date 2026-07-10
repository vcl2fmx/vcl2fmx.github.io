unit ContractPaintBoxOnPaint;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls, Vcl.Graphics;
type TContractPaintBoxOnPaint = class(TForm) PaintBox1: TPaintBox; procedure PaintBox1Paint(Sender: TObject); end;
implementation
procedure TContractPaintBoxOnPaint.PaintBox1Paint(Sender: TObject);
begin
  PaintBox1.Canvas.Rectangle(0, 0, 10, 10);
end;
end.

