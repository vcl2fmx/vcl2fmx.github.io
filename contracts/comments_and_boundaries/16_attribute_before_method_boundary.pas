unit ContractAttributeBeforeMethodBoundary;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractAttributeBeforeMethodBoundary = class private FHandle: HWND; public procedure Run; procedure SendMessage(const AText: string); end;
implementation
procedure TContractAttributeBeforeMethodBoundary.Run;
begin
  SendMessage(FHandle, WM_CLOSE, 0, 0)
end;
[SomeAttribute]
procedure TContractAttributeBeforeMethodBoundary.SendMessage(const AText: string);
begin
  Writeln(AText);
end;
end.

