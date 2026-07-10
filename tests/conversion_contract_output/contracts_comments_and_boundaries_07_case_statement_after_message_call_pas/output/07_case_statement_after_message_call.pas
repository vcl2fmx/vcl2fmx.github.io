unit ContractCaseStatementAfterMessageCall;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractCaseStatementAfterMessageCall = class private FHandle: HWND; public procedure Run(AValue: Integer); end;
implementation
procedure TContractCaseStatementAfterMessageCall.Run(AValue: Integer);
begin
  { FMX: WM_CLOSE - Use Close or OnCloseQuery rather than posting WM_CLOSE. }
  { Original: SendMessage(FHandle, WM_CLOSE, 0, 0); }
  case AValue of
    1: Writeln('one');
  end;
end;
end.
