unit ContractPostMessageTVMExpand;

interface

uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;

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
  PostMessage(FHandle, TVM_EXPAND, 0, 0);
end;

end.
