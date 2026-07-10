unit ContractGDIGetDCRelease;
interface
uses System.SysUtils, System.Classes, Winapi.Windows;
type TContractGDIGetDCRelease = class public procedure Run; end;
implementation
procedure TContractGDIGetDCRelease.Run;
var DC: HDC;
begin
  DC := GetDC(0);
  ReleaseDC(0, DC);
end;
end.

