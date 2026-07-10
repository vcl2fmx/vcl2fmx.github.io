unit ContractDirectiveBetweenCallLines;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractDirectiveBetweenCallLines = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractDirectiveBetweenCallLines.Run;
begin
  // FMX manual review: SendMessage(
  // FMX manual review: FHandle,
  // FMX manual review: {$IFDEF MSWINDOWS}
  // FMX manual review: WM_CLOSE,
  // FMX manual review: {$ELSE}
  // FMX manual review: WM_USER,
  // FMX manual review: {$ENDIF}
  // FMX manual review: 0,
  // FMX manual review: 0);
end;
end.
