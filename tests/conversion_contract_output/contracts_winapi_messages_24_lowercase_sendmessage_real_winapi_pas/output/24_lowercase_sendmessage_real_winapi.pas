unit ContractLowercaseSendMessageRealWinapi;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractLowercaseSendMessageRealWinapi = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractLowercaseSendMessageRealWinapi.Run;
begin
  { FMX: wm_close - Use Close or OnCloseQuery rather than posting WM_CLOSE. }
  { Original: sendmessage(FHandle, wm_close, 0, 0); }
end;
end.
