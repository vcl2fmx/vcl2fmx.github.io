unit ContractConstructorBoundary;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractConstructorBoundary = class private FHandle: HWND; public constructor Create; procedure Run; end;
implementation
procedure TContractConstructorBoundary.Run;
begin
  { FMX: WM_CLOSE - Use Close or OnCloseQuery rather than posting WM_CLOSE. }
  { Original: SendMessage(FHandle, WM_CLOSE, 0, 0) }
end;
constructor TContractConstructorBoundary.Create;
begin
  inherited Create;
end;
end.
