unit ContractNoInterfaceUsesInsert;
interface
type TContractNoInterfaceUsesInsert = class public procedure Run; end;
implementation
procedure TContractNoInterfaceUsesInsert.Run;
begin
  Writeln('insert uses when needed');
end;
end.

