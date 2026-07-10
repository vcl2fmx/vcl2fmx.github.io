unit ContractBlockingApplicationCall;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractBlockingApplicationCall = class public procedure Run; end;
implementation
procedure TContractBlockingApplicationCall.Run;
begin
  BringToFront;
end;
end.
