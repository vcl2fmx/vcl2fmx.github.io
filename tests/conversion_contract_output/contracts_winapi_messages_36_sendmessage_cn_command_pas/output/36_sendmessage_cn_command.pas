unit ContractSendMessageCNCommand;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type
  TContractSendMessageCNCommand = class
  private
    FHandle: HWND;
  public
    procedure Run;
  end;
implementation
procedure TContractSendMessageCNCommand.Run;
begin
  { FMX: CN_COMMAND - Use FMX control events, notifications, and direct property changes instead of VCL control notifications. }
  { Original: SendMessage(FHandle, CN_COMMAND, 0, 0); }
end;
end.
