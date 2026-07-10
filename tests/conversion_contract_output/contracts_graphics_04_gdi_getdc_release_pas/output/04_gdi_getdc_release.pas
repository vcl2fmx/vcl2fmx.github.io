unit ContractGDIGetDCRelease;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractGDIGetDCRelease = class public procedure Run; end;
implementation
procedure TContractGDIGetDCRelease.Run;
var DC: HDC;
begin
  // FMX manual review: move this drawing code to an FMX OnPaint handler that uses the Canvas parameter
  // Original: DC := GetDC(0);
  // FMX manual review: remove this paired Windows paint/DC cleanup after moving drawing to FMX OnPaint
  // Original: ReleaseDC(0, DC);
end;
end.
