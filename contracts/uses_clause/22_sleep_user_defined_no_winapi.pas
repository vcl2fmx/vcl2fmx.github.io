unit ContractSleepUserDefinedNoWinapi;

interface

uses
  System.SysUtils, System.Classes;

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
