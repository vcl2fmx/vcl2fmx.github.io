unit ContractMessagePumpCalls;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;

type
  TContractMessagePumpCalls = class
  public
    procedure Run;
  end;

implementation

procedure TContractMessagePumpCalls.Run;
var
  Msg: TMsg;
begin
  while GetMessage(Msg, 0, 0, 0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;

end.

