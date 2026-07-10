unit ContractDrawTextRect;
interface
uses System.SysUtils, System.Classes, Winapi.Windows;
type TContractDrawTextRect = class public procedure Run; end;
implementation
procedure TContractDrawTextRect.Run;
var R: TRect;
begin
  DrawText(0, 'hello', -1, R, DT_LEFT);
end;
end.

