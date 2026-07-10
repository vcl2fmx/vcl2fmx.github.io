unit ContractGDICreatePenDeleteObject;
interface
uses System.SysUtils, System.Classes, Winapi.Windows;
type TContractGDICreatePenDeleteObject = class public procedure Run; end;
implementation
procedure TContractGDICreatePenDeleteObject.Run;
var P: HPEN;
begin
  P := CreatePen(PS_SOLID, 1, RGB(255, 0, 0));
  DeleteObject(P);
end;
end.

