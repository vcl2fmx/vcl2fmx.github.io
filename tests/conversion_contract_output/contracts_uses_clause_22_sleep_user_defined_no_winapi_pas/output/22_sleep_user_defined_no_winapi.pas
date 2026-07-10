unit ContractSleepUserDefinedNoWinapi;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractSleepUserDefinedNoWinapi = class
  public
    procedure MySleep(ms: Integer);
    procedure Run;
  end;
implementation
procedure TContractSleepUserDefinedNoWinapi.MySleep(ms: Integer);
begin
  Writeln(ms);
end;
procedure TContractSleepUserDefinedNoWinapi.Run;
begin
  MySleep(100);
end;
end.
