unit ContractMessagesBareUnitRemoved;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractMessagesBareUnitRemoved = class public procedure Run; end;
implementation
procedure TContractMessagesBareUnitRemoved.Run;
begin
  Writeln('bare messages unit without usage');
end;
end.
