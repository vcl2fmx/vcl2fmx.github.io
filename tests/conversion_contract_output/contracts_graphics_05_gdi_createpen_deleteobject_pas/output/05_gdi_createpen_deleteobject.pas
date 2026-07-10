unit ContractGDICreatePenDeleteObject;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractGDICreatePenDeleteObject = class public procedure Run; end;
implementation
procedure TContractGDICreatePenDeleteObject.Run;
var P: HPEN;
begin
  // FMX manual review: replace GDI pen/brush/object code with Canvas.Stroke and Canvas.Fill settings
  // Original: P := CreatePen(PS_SOLID, 1, RGB(255, 0, 0));
  // FMX manual review: replace GDI pen/brush/object code with Canvas.Stroke and Canvas.Fill settings
  // Original: DeleteObject(P);
end;
end.
