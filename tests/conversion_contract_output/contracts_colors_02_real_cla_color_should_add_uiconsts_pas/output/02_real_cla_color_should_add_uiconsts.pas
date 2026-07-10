unit ContractRealClaColorShouldAddUIConsts;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants;
type
  TContractRealClaColorShouldAddUIConsts = class
  public
    procedure Run;
  end;
implementation
procedure TContractRealClaColorShouldAddUIConsts.Run;
var
  ColorValue: TAlphaColor;
begin
  ColorValue := claBlack;
  Writeln(Integer(ColorValue));
end;
end.
