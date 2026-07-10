unit ContractClassProcedureBoundary;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
  { FMX: Use property setter or direct method call instead of SendMessage }
  { Original: type TContractClassProcedureBoundary = class private FHandle: HWND; public procedure Run; class procedure SendMessage(const AText: string); end; }
implementation
procedure TContractClassProcedureBoundary.Run;
begin
  { FMX: WM_CLOSE - Use Close or OnCloseQuery rather than posting WM_CLOSE. }
  { Original: SendMessage(FHandle, WM_CLOSE, 0, 0) }
end;
class procedure TContractClassProcedureBoundary.SendMessage(const AText: string);
begin
  Writeln(AText);
end;
end.
