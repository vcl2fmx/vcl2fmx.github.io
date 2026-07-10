unit ContractSystemCommandHandlerCloseOnly;

interface

uses
  System.SysUtils, Winapi.Messages, Vcl.Forms;

type
  TContractSystemCommandHandlerCloseOnly = class(TForm)
  private
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
  end;

implementation

procedure TContractSystemCommandHandlerCloseOnly.WMSysCommand(var Msg: TWMSysCommand);
begin
  if (Msg.CmdType and $FFF0) = SC_CLOSE then
    Close
  else
    inherited;
end;

end.
