unit ContractRealClaColorShouldAddUIConsts;

interface

uses
  System.SysUtils, System.Classes;

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
