unit ContractBlockingApplicationCall;
interface
uses System.SysUtils, System.Classes, Vcl.Forms;
type TContractBlockingApplicationCall = class public procedure Run; end;
implementation
procedure TContractBlockingApplicationCall.Run;
begin
  Application.ShowMainForm := False;
  Application.BringToFront;
end;
end.

