unit ContractAlphaColorType;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UITypes, System.Variants;
type TContractAlphaColorType = class public procedure Run; end;
implementation
procedure TContractAlphaColorType.Run;
var C: TAlphaColor;
begin
  C := $FF000000;
  Writeln(IntToHex(C, 8));
end;
end.
