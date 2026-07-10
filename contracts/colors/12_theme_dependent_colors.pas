unit ContractThemeDependentColors;
interface
uses System.SysUtils, System.Classes, Vcl.Graphics;
type TContractThemeDependentColors = class public procedure Run; end;
implementation
procedure TContractThemeDependentColors.Run;
var C: TColor;
begin
  C := clActiveCaption;
  C := clInactiveCaption;
  Writeln(IntToStr(C));
end;
end.

