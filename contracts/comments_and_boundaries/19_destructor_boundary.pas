unit ContractDestructorBoundary;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractDestructorBoundary = class private FHandle: HWND; public destructor Destroy; override; procedure Run; end;
implementation
procedure TContractDestructorBoundary.Run;
begin
  SendMessage(FHandle, WM_CLOSE, 0, 0)
end;
destructor TContractDestructorBoundary.Destroy;
begin
  inherited;
end;
end.

