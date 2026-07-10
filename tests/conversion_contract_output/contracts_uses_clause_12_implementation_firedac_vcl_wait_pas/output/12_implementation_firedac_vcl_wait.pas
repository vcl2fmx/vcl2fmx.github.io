unit ContractImplementationFireDACVCLWait;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractImplementationFireDACVCLWait = class public procedure Run; end;
implementation
uses FireDAC.FMXUI.Wait;
procedure TContractImplementationFireDACVCLWait.Run;
begin
  Writeln('wait cursor');
end;
end.
