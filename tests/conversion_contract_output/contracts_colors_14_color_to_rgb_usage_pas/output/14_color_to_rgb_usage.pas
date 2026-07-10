unit ContractColorToRGBUsage;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants, Winapi.Windows;
type TContractColorToRGBUsage = class public procedure Run; end;
implementation
procedure TContractColorToRGBUsage.Run;
begin
  Writeln(IntToStr(GeneratedColorToRGB(claRed)));
end;
end.
