unit ContractCanvasTextOut;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractCanvasTextOut = class(TForm) procedure Run; end;
implementation
procedure TContractCanvasTextOut.Run;
begin
  Canvas.TextOut(10, 10, 'hello');
end;
end.
