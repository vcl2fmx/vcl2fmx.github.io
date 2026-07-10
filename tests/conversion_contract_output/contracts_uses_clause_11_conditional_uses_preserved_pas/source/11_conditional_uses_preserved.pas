unit ContractConditionalUsesPreserved;
interface
uses
  System.SysUtils,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.Classes;
type TContractConditionalUsesPreserved = class public procedure Run; end;
implementation
procedure TContractConditionalUsesPreserved.Run;
begin
  Writeln('conditional uses');
end;
end.

