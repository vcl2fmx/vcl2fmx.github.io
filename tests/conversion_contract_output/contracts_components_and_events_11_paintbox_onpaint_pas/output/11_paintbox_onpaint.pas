unit ContractPaintBoxOnPaint;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Objects, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractPaintBoxOnPaint = class(TForm) PaintBox1: TPaintBox; procedure PaintBox1Paint(Sender: TObject); end;
implementation
procedure TContractPaintBoxOnPaint.PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
begin
  PaintBox1.Canvas.Rectangle(0, 0, 10, 10);
end;
end.
