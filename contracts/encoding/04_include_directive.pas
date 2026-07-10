unit ContractIncludeDirective;
interface
uses System.SysUtils, System.Classes;
type TContractIncludeDirective = class public procedure Run; end;
implementation
{$I ContractIncludeDirective.inc}
procedure TContractIncludeDirective.Run;
begin
  Writeln('include');
end;
end.

