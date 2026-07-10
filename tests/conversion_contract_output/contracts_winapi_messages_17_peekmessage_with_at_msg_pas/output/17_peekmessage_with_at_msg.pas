unit ContractPeekMessageWithAtMsg;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractPeekMessageWithAtMsg = class public procedure Run; end;
implementation
procedure TContractPeekMessageWithAtMsg.Run;
var Msg: TMsg;
begin
  { FMX: Message pump calls not needed - FMX has its own event loop }
  { Original: PeekMessage(@Msg, 0, 0, 0, PM_REMOVE); }
end;
end.
