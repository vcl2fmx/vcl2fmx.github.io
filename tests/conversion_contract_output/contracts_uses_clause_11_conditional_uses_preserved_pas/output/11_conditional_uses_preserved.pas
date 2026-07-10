unit ContractConditionalUsesPreserved;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
;
type TContractConditionalUsesPreserved = class public procedure Run; end;
implementation
procedure TContractConditionalUsesPreserved.Run;
begin
  Writeln('conditional uses');
end;
end.
