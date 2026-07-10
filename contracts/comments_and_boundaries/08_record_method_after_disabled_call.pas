unit ContractRecordMethodAfterDisabledCall;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type
  TContractRecordMethodAfterDisabledCall = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractRecordMethodAfterDisabledCall.Run;
begin
  SendMessage(
    FHandle,
    WM_CLOSE,
    0,
    0)
end;
procedure HelperAfterBoundary;
begin
  Writeln('boundary');
end;
end.

