unit ContractSystemCommandHandlerMinimizeSideEffect;

interface

uses
  System.SysUtils, Winapi.Messages, Vcl.Forms, Vcl.ExtCtrls;

type
  TContractSystemCommandHandlerMinimizeSideEffect = class(TForm)
    Timer1: TTimer;
  private
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
  end;

implementation

procedure TContractSystemCommandHandlerMinimizeSideEffect.WMSysCommand(var Msg: TWMSysCommand);
begin
  if (Msg.CmdType and $FFF0) = SC_MINIMIZE then
    Timer1.Enabled := True
  else
    inherited;
end;

end.
