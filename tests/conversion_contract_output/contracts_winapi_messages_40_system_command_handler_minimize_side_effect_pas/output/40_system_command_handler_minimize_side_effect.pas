unit ContractSystemCommandHandlerMinimizeSideEffect;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractSystemCommandHandlerMinimizeSideEffect = class(TForm)
    Timer1: TTimer;
  private
  // FMX manual review: procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
  end;
implementation
  // FMX manual review: procedure TContractSystemCommandHandlerMinimizeSideEffect.WMSysCommand(var Msg: TWMSysCommand);
  // FMX manual review: begin
  // FMX manual review: if (Msg.CmdType and $FFF0) = SC_MINIMIZE then
  // FMX manual review: Timer1.Enabled := True
  // FMX manual review: else
  // FMX manual review: inherited;
  // FMX manual review: end;
  // FMX manual review: 
end.
