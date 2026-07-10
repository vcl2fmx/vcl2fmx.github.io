unit ContractInterfaceShellAPINeeded;
interface
uses System.SysUtils, System.Classes, Winapi.ShellAPI;
type TContractInterfaceShellAPINeeded = class public procedure Run; end;
implementation
procedure TContractInterfaceShellAPINeeded.Run;
begin
  ShellExecute(0, 'open', 'notepad.exe', nil, nil, 1);
end;
end.

