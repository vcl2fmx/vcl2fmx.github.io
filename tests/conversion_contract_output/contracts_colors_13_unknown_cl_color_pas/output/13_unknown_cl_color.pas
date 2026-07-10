unit ContractUnknownClColor;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UITypes, System.Variants;
type TContractUnknownClColor = class public procedure Run; end;
implementation
procedure TContractUnknownClColor.Run;
var C: TAlphaColor;
begin
  C := clCompanyBrandColor;
  Writeln(IntToStr(C));
end;
end.
