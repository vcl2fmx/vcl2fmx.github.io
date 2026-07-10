unit ContractFunctionBoundaryWithGenerics;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.Generics.Collections,
  System.SysUtils, System.Variants, Winapi.Windows;
type TContractFunctionBoundaryWithGenerics = class private FHandle: HWND; public procedure Run; function Values: TArray<Integer>; end;
implementation
procedure TContractFunctionBoundaryWithGenerics.Run;
begin
  { FMX: WM_CLOSE - Use Close or OnCloseQuery rather than posting WM_CLOSE. }
  { Original: SendMessage(FHandle, WM_CLOSE, 0, 0) }
end;
function TContractFunctionBoundaryWithGenerics.Values: TArray<Integer>;
begin
  Result := [1, 2, 3];
end;
end.
