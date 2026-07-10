unit ContractSendMessageInCommentAndCode;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractSendMessageInCommentAndCode = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractSendMessageInCommentAndCode.Run;
begin
  // SendMessage(FHandle, WM_CLOSE, 0, 0);
  { FMX: WM_SIZE - Use OnResize and FMX layout/alignment behavior instead of WM_SIZE. }
  { Original: SendMessage(FHandle, WM_SIZE, 0, 0); }
end;
end.
