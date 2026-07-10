unit ContractClarityShouldNotAddUIConsts;
interface
uses System.SysUtils, System.Classes;
type TContractClarityShouldNotAddUIConsts = class public procedure Run; end;
implementation
procedure TContractClarityShouldNotAddUIConsts.Run;
var clarity: string;
begin
  clarity := 'not a color';
  Writeln(clarity);
end;
end.

