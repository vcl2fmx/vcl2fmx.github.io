unit ContractMessagesBareUnitRemoved;
interface
uses System.SysUtils, System.Classes, Messages;
type TContractMessagesBareUnitRemoved = class public procedure Run; end;
implementation
procedure TContractMessagesBareUnitRemoved.Run;
begin
  Writeln('bare messages unit without usage');
end;
end.

