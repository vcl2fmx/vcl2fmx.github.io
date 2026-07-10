unit ContractRGBHelpersNeedWinapiWindows;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractRGBHelpersNeedWinapiWindows = class public procedure Run; end;
implementation
procedure TContractRGBHelpersNeedWinapiWindows.Run;
var C: Integer;
begin
  C := RGB(GeneratedGetRValue(0), GeneratedGetGValue(0), GeneratedGetBValue(0));
  Writeln(IntToStr(C));
end;
end.
