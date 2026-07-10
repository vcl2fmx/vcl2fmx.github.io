unit ContractNestedBeginEndAfterDisabledCall;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractNestedBeginEndAfterDisabledCall = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractNestedBeginEndAfterDisabledCall.Run;
begin
  if True then
  begin
    SendMessage(
      FHandle,
      WM_USER + 1,
      0,
      0);
    Writeln('after');
  end;
end;
end.

