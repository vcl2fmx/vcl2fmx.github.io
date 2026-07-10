unit ContractSendMessageCMFocusChanged;

interface

uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;

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
  SendMessage(FHandle, CM_FOCUSCHANGED, 0, 0);
end;

end.
