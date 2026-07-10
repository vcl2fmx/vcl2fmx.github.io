unit ContractTScalableShouldNotAddUIConsts;
interface
uses System.SysUtils, System.Classes;
type TScalableThing = class end; TContractTScalableShouldNotAddUIConsts = class public procedure Run; end;
implementation
procedure TContractTScalableShouldNotAddUIConsts.Run;
begin
  Writeln(TScalableThing.ClassName);
end;
end.

