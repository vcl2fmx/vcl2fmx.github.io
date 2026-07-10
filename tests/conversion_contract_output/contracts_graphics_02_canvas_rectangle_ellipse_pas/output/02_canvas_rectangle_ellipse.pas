unit ContractCanvasRectangleEllipse;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils, System.Types,
  System.Variants;
type TContractCanvasRectangleEllipse = class(TForm) procedure Run; end;
implementation
procedure FillAndStrokeEllipse(ACanvas: TCanvas; const R: TRectF);
begin
  ACanvas.FillEllipse(R, 1);
  ACanvas.DrawEllipse(R, 1);
end;
procedure TContractCanvasRectangleEllipse.Run;
begin
  Canvas.Rectangle(0, 0, 20, 20);
  FillAndStrokeEllipse(Canvas, System.Types.RectF(0, 0, 20, 20));
end;
end.
