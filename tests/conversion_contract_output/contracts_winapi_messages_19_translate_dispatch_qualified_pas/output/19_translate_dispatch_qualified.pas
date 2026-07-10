unit ContractTranslateDispatchQualified;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractTranslateDispatchQualified = class public procedure Run; end;
implementation
procedure TContractTranslateDispatchQualified.Run;
var Msg: TMsg;
begin
  { FMX: Message pump calls not needed - FMX has its own event loop }
  { Original: Winapi.Windows.TranslateMessage(Msg); }
  { FMX: Message pump calls not needed - FMX has its own event loop }
  { Original: Winapi.Windows.DispatchMessage(Msg); }
end;
end.
