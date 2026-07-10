unit ContractSendMessageLVMGetItemCount;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
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
  { FMX: LVM_GETITEMCOUNT - Use FMX list view, tree view, tab control, or adapter APIs instead of common-control messages. }
  { Original: Count := SendMessage(FHandle, LVM_GETITEMCOUNT, 0, 0); }
  Writeln(Count);
end;
end.
