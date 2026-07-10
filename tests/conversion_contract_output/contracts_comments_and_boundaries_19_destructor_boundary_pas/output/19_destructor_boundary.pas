unit ContractDestructorBoundary;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractDestructorBoundary = class private FHandle: HWND; public destructor Destroy; override; procedure Run; end;
implementation
procedure TContractDestructorBoundary.Run;
begin
  { FMX: WM_CLOSE - Use Close or OnCloseQuery rather than posting WM_CLOSE. }
  { Original: SendMessage(FHandle, WM_CLOSE, 0, 0) }
end;
destructor TContractDestructorBoundary.Destroy;
begin
  inherited;
end;
end.
