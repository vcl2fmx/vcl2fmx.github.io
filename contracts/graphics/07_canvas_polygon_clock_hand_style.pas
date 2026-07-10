unit ContractCanvasPolygonClockHandStyle;

interface

uses
  System.SysUtils, Vcl.Forms, Vcl.Graphics;

type
  TContractCanvasPolygonClockHandStyle = class(TForm)
  public
    procedure DrawHand(Canvas: TCanvas; CenterX, CenterY: Integer);
  end;

implementation

procedure TContractCanvasPolygonClockHandStyle.DrawHand(Canvas: TCanvas; CenterX, CenterY: Integer);
begin
  Canvas.Pen.Color := clBlack;
  Canvas.Brush.Color := clBlack;
  Canvas.Polygon([
    Point(CenterX, CenterY),
    Point(CenterX - 5, CenterY + 40),
    Point(CenterX, CenterY + 90),
    Point(CenterX + 5, CenterY + 40)
  ]);
  Canvas.Ellipse(CenterX - 8, CenterY - 8, CenterX + 8, CenterY + 8);
end;

end.
