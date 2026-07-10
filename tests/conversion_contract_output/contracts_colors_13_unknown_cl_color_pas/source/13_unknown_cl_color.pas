unit ContractUnknownClColor;
interface
uses System.SysUtils, System.Classes, Vcl.Graphics;
type TContractUnknownClColor = class public procedure Run; end;
implementation
procedure TContractUnknownClColor.Run;
var C: TColor;
begin
  C := clCompanyBrandColor;
  Writeln(IntToStr(C));
end;
end.

