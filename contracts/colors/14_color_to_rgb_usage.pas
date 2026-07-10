unit ContractColorToRGBUsage;
interface
uses System.SysUtils, System.Classes, Vcl.Graphics;
type TContractColorToRGBUsage = class public procedure Run; end;
implementation
procedure TContractColorToRGBUsage.Run;
begin
  Writeln(IntToStr(ColorToRGB(clRed)));
end;
end.

