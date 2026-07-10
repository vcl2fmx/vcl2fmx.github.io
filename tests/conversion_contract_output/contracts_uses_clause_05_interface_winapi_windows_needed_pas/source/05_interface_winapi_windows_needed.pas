unit ContractInterfaceWinapiWindowsNeeded;
interface
uses System.SysUtils, System.Classes, Winapi.Windows;
type TContractInterfaceWinapiWindowsNeeded = class public procedure Run; end;
implementation
procedure TContractInterfaceWinapiWindowsNeeded.Run;
var H: THandle;
begin
  H := CreateFile('x.txt', GENERIC_READ, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if H <> INVALID_HANDLE_VALUE then CloseHandle(H);
end;
end.

