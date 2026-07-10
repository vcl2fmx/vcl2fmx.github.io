unit ContractInterfaceShellAPINeeded;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.ShellAPI;
type TContractInterfaceShellAPINeeded = class public procedure Run; end;
implementation
procedure TContractInterfaceShellAPINeeded.Run;
begin
  ShellExecute(0, 'open', 'notepad.exe', nil, nil, 1);
end;
end.
