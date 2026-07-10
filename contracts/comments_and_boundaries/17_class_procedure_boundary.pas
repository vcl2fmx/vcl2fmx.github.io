unit ContractClassProcedureBoundary;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractClassProcedureBoundary = class private FHandle: HWND; public procedure Run; class procedure SendMessage(const AText: string); end;
implementation
procedure TContractClassProcedureBoundary.Run;
begin
  SendMessage(FHandle, WM_CLOSE, 0, 0)
end;
class procedure TContractClassProcedureBoundary.SendMessage(const AText: string);
begin
  Writeln(AText);
end;
end.

