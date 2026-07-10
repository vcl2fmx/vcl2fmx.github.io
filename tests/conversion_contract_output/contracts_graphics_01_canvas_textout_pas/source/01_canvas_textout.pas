unit ContractCanvasTextOut;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.Graphics;
type TContractCanvasTextOut = class(TForm) procedure Run; end;
implementation
procedure TContractCanvasTextOut.Run;
begin
  Canvas.TextOut(10, 10, 'hello');
end;
end.

