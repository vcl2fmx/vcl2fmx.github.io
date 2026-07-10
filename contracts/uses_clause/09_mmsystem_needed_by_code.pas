unit ContractMMSystemNeededByCode;
interface
uses System.SysUtils, System.Classes, MMSystem;
type TContractMMSystemNeededByCode = class public procedure Run; end;
implementation
procedure TContractMMSystemNeededByCode.Run;
begin
  waveOutGetNumDevs;
end;
end.

