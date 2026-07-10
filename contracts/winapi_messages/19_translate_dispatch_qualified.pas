unit ContractTranslateDispatchQualified;
interface
uses System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;
type TContractTranslateDispatchQualified = class public procedure Run; end;
implementation
procedure TContractTranslateDispatchQualified.Run;
var Msg: TMsg;
begin
  Winapi.Windows.TranslateMessage(Msg);
  Winapi.Windows.DispatchMessage(Msg);
end;
end.

