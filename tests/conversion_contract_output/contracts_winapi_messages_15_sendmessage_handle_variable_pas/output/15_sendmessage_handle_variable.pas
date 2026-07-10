unit ContractSendMessageHandleVariable;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractSendMessageHandleVariable = class private FHandle: HWND; public procedure Run; end;
implementation
procedure TContractSendMessageHandleVariable.Run;
begin
  { FMX: WM_SIZE - Use OnResize and FMX layout/alignment behavior instead of WM_SIZE. }
  { Original: SendMessage(FHandle, WM_SIZE, 0, 0); }
end;
end.
