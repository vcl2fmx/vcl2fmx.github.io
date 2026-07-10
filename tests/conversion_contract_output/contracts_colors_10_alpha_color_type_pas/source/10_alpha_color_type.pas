unit ContractAlphaColorType;
interface
uses System.SysUtils, System.Classes;
type TContractAlphaColorType = class public procedure Run; end;
implementation
procedure TContractAlphaColorType.Run;
var C: TAlphaColor;
begin
  C := $FF000000;
  Writeln(IntToHex(C, 8));
end;
end.

