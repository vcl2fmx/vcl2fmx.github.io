unit ContractRGBHelpersNeedWinapiWindows;
interface
uses System.SysUtils, System.Classes, Winapi.Windows;
type TContractRGBHelpersNeedWinapiWindows = class public procedure Run; end;
implementation
procedure TContractRGBHelpersNeedWinapiWindows.Run;
var C: Integer;
begin
  C := RGB(GetRValue(0), GetGValue(0), GetBValue(0));
  Writeln(IntToStr(C));
end;
end.

