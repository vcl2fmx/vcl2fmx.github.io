unit ContractCaseStatementAfterMessageCall;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractCaseStatementAfterMessageCall = class private FHandle: HWND; public procedure Run(AValue: Integer); end;
implementation
procedure TContractCaseStatementAfterMessageCall.Run(AValue: Integer);
begin
  SendMessage(FHandle, WM_CLOSE, 0, 0);
  case AValue of
    1: Writeln('one');
  end;
end;
end.

