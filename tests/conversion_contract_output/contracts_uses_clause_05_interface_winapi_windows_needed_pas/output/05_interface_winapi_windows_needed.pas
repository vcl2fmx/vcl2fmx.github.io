unit ContractInterfaceWinapiWindowsNeeded;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractInterfaceWinapiWindowsNeeded = class public procedure Run; end;
implementation
procedure TContractInterfaceWinapiWindowsNeeded.Run;
var H: THandle;
begin
  // FMX: Use TFile, TStream, or TPath from System.IOUtils after manual review
  // Original: H := CreateFile('x.txt', GENERIC_READ, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if H <> INVALID_HANDLE_VALUE then CloseHandle(H);
end;
end.
