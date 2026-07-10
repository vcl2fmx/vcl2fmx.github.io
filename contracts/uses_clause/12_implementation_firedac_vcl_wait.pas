unit ContractImplementationFireDACVCLWait;
interface
uses System.SysUtils, System.Classes;
type TContractImplementationFireDACVCLWait = class public procedure Run; end;
implementation
uses FireDAC.VCLUI.Wait;
procedure TContractImplementationFireDACVCLWait.Run;
begin
  Writeln('wait cursor');
end;
end.

