unit ContractThemeDependentColors;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UITypes, System.Variants;
type TContractThemeDependentColors = class public procedure Run; end;
implementation
procedure TContractThemeDependentColors.Run;
var C: TAlphaColor;
begin
  C := $FF0078D7;
  C := $FFF0F0F0;
  Writeln(IntToStr(C));
end;
end.
