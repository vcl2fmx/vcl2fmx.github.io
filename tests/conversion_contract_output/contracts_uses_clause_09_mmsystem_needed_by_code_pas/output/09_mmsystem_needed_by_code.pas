unit ContractMMSystemNeededByCode;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.MMSystem;
type TContractMMSystemNeededByCode = class public procedure Run; end;
implementation
procedure TContractMMSystemNeededByCode.Run;
begin
  waveOutGetNumDevs;
end;
end.
