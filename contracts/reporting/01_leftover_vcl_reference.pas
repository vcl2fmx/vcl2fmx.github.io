unit ContractLeftoverVclReference;
interface
uses System.SysUtils, System.Classes, Vcl.Forms;
type TContractLeftoverVclReference = class public procedure Run; end;
implementation
procedure TContractLeftoverVclReference.Run;
begin
  Writeln(Vcl.Forms.Application.Title);
end;
end.

