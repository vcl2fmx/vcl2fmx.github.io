unit ContractDirectiveBetweenCallLines;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractDirectiveBetweenCallLines = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractDirectiveBetweenCallLines.Run;
begin
  SendMessage(
    FHandle,
    {$IFDEF MSWINDOWS}
    WM_CLOSE,
    {$ELSE}
    WM_USER,
    {$ENDIF}
    0,
    0);
end;
end.

