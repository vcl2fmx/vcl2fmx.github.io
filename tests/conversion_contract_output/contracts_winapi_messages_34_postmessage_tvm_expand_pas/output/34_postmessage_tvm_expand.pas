unit ContractPostMessageTVMExpand;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type
  TContractPostMessageTVMExpand = class
  private
    FHandle: HWND;
  public
    procedure Run;
  end;
implementation
procedure TContractPostMessageTVMExpand.Run;
begin
  { FMX: TVM_EXPAND - Use FMX list view, tree view, tab control, or adapter APIs instead of common-control messages. }
  { FMX: Preserve async behavior with TThread.Queue only if the original timing matters. }
  { Original: PostMessage(FHandle, TVM_EXPAND, 0, 0); }
  { TThread.Queue(nil, procedure begin TMessageManager.DefaultManager.SendMessage(Self, TMyMsg.Create(lParam)); end); }
end;
end.
