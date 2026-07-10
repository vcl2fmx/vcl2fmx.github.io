unit ContractMessagePumpCalls;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type
  TContractMessagePumpCalls = class
  public
    procedure Run;
  end;
implementation
procedure TContractMessagePumpCalls.Run;
var
  Msg: TMsg;
begin
  { FMX: Message pump calls not needed - FMX has its own event loop }
  { Original: while GetMessage(Msg, 0, 0, 0) do }
  begin
  { FMX: Message pump calls not needed - FMX has its own event loop }
  { Original: TranslateMessage(Msg); }
  { FMX: Message pump calls not needed - FMX has its own event loop }
  { Original: DispatchMessage(Msg); }
  end;
end;
end.
