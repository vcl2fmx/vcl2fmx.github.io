unit ContractTScalableShouldNotAddUIConsts;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TScalableThing = class end; TContractTScalableShouldNotAddUIConsts = class public procedure Run; end;
implementation
procedure TContractTScalableShouldNotAddUIConsts.Run;
begin
  Writeln(TScalableThing.ClassName);
end;
end.
