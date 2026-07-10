unit ContractSendMessageLVMGetItemCount;

interface

uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;

type
  TContractSendMessageLVMGetItemCount = class
  private
    FHandle: HWND;
  public
    procedure Run;
  end;

implementation

procedure TContractSendMessageLVMGetItemCount.Run;
var
  Count: NativeInt;
begin
  Count := SendMessage(FHandle, LVM_GETITEMCOUNT, 0, 0);
  Writeln(Count);
end;

end.
