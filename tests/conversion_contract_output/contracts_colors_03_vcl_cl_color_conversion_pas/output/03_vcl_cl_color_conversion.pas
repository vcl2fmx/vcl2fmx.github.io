unit ContractVclClColorConversion;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants;
type
  TContractVclClColorConversion = class
  public
    procedure Run;
  end;
implementation
procedure TContractVclClColorConversion.Run;
var
  C: TAlphaColor;
begin
  C := claRed;
  Writeln(IntToStr(C));
end;
end.
