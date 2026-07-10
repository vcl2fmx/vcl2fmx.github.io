unit ContractDrawTextRect;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractDrawTextRect = class public procedure Run; end;
implementation
procedure TContractDrawTextRect.Run;
var R: TRect;
begin
  DrawText(0, 'hello', -1, R, DT_LEFT);
end;
end.
