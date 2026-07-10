unit ContractSendMessageCMFocusChanged;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type
  TContractSendMessageCMFocusChanged = class
  private
    FHandle: HWND;
  public
    procedure Run;
  end;
implementation
procedure TContractSendMessageCMFocusChanged.Run;
begin
  { FMX: CM_FOCUSCHANGED - Use FMX control events, notifications, and direct property changes instead of VCL control notifications. }
  { Original: SendMessage(FHandle, CM_FOCUSCHANGED, 0, 0); }
end;
end.
