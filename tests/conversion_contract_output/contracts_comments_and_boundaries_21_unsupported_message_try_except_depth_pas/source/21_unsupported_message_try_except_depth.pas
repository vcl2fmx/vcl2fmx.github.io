unit ContractUnsupportedMessageTryExceptDepth;

interface

uses
  System.SysUtils, System.Classes, Winapi.Messages, Vcl.Forms;

type
  TContractUnsupportedMessageTryExceptDepth = class(TForm)
  protected
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
  end;

implementation

procedure TContractUnsupportedMessageTryExceptDepth.WMSysCommand(var Msg: TWMSysCommand);
begin
  try
    if Msg.CmdType = SC_MINIMIZE then
      Exit;
  except
    on E: Exception do
      raise;
  end;
  inherited;
end;

end.
