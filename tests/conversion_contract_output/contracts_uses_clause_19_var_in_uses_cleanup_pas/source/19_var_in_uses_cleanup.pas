unit ContractVarInUsesCleanup;
interface
uses
  System.SysUtils,
  System.Classes var Dummy: Integer;
type TContractVarInUsesCleanup = class public procedure Run; end;
implementation
procedure TContractVarInUsesCleanup.Run;
begin
  Writeln('odd parser case');
end;
end.

