unit ContractCanvasRectangleEllipse;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.Graphics;
type TContractCanvasRectangleEllipse = class(TForm) procedure Run; end;
implementation
procedure TContractCanvasRectangleEllipse.Run;
begin
  Canvas.Rectangle(0, 0, 20, 20);
  Canvas.Ellipse(0, 0, 20, 20);
end;
end.

