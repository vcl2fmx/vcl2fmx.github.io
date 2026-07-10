unit ContractLeftoverVclReference;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractLeftoverVclReference = class public procedure Run; end;
implementation
procedure TContractLeftoverVclReference.Run;
begin
  Writeln(Vcl.Forms.Application.Title);
end;
end.
