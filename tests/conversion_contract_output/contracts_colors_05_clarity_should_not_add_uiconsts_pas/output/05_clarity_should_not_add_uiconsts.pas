unit ContractClarityShouldNotAddUIConsts;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractClarityShouldNotAddUIConsts = class public procedure Run; end;
implementation
procedure TContractClarityShouldNotAddUIConsts.Run;
var clarity: string;
begin
  clarity := 'not a color';
  Writeln(clarity);
end;
end.
