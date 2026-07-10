unit ContractEndDotBoundary;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
implementation
procedure Run;
begin
  SendMessage(0, WM_CLOSE, 0, 0)
end.

