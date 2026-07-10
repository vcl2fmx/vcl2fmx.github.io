unit ContractIncludeDirective;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractIncludeDirective = class public procedure Run; end;
implementation
{$I ContractIncludeDirective.inc}
procedure TContractIncludeDirective.Run;
begin
  Writeln('include');
end;
end.
