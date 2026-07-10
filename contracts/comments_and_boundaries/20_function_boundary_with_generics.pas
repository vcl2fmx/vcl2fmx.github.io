unit ContractFunctionBoundaryWithGenerics;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, System.Generics.Collections;
type TContractFunctionBoundaryWithGenerics = class private FHandle: HWND; public procedure Run; function Values: TArray<Integer>; end;
implementation
procedure TContractFunctionBoundaryWithGenerics.Run;
begin
  SendMessage(FHandle, WM_CLOSE, 0, 0)
end;
function TContractFunctionBoundaryWithGenerics.Values: TArray<Integer>;
begin
  Result := [1, 2, 3];
end;
end.

