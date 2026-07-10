unit ContractSendMessageFullyQualified;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractSendMessageFullyQualified = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractSendMessageFullyQualified.Run;
begin
  { FMX: WM_CLOSE - Use Close or OnCloseQuery rather than posting WM_CLOSE. }
  { Original: Winapi.Windows.SendMessage(FHandle, WM_CLOSE, 0, 0); }
end;
end.
