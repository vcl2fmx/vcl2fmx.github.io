unit ContractShellAPIBareUnitNeeded;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.ShellAPI;
type TContractShellAPIBareUnitNeeded = class public procedure Run; end;
implementation
procedure TContractShellAPIBareUnitNeeded.Run;
begin
  ShellExecute(0, 'open', 'calc.exe', nil, nil, 1);
end;
end.
