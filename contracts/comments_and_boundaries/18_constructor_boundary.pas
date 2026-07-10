unit ContractConstructorBoundary;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractConstructorBoundary = class private FHandle: HWND; public constructor Create; procedure Run; end;
implementation
procedure TContractConstructorBoundary.Run;
begin
  SendMessage(FHandle, WM_CLOSE, 0, 0)
end;
constructor TContractConstructorBoundary.Create;
begin
  inherited Create;
end;
end.

