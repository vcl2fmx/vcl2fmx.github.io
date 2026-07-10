unit ContractCanvasPolygonClockHandStyle;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils, System.Types,
  System.UIConsts, System.UITypes, System.Variants;
type
  TContractCanvasPolygonClockHandStyle = class(TForm)
  public
    procedure DrawHand(Canvas: TCanvas; CenterX, CenterY: Integer);
  end;
implementation
procedure FillAndStrokeEllipse(ACanvas: TCanvas; const R: TRectF);
begin
  ACanvas.FillEllipse(R, 1);
  ACanvas.DrawEllipse(R, 1);
end;
procedure TContractCanvasPolygonClockHandStyle.DrawHand(Canvas: TCanvas; CenterX, CenterY: Integer);
begin
  Canvas.Stroke.Color := claBlack;
  Canvas.Fill.Color := claBlack;
  Canvas.FillPolygon([
    System.Types.PointF(CenterX, CenterY),
    System.Types.PointF(CenterX - 5, CenterY + 40),
    System.Types.PointF(CenterX, CenterY + 90),
    System.Types.PointF(CenterX + 5, CenterY + 40)
  ], 1);
  FillAndStrokeEllipse(Canvas, System.Types.RectF(CenterX - 8, CenterY - 8, CenterX + 8, CenterY + 8));
end;
end.
