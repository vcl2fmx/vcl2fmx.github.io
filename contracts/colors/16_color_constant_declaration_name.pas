unit ContractColorConstantDeclarationName;

interface

uses
  Vcl.Graphics;

const
  cBackColorXP = $00E1E1E1;
  clMyBlue = $00EAC9B7;
  clSalmon = $00C5E6FA;

type
  TContractColorConstantDeclarationName = class
  public
    procedure Run;
  end;

implementation

var
  ColorIntForm: TColor;
  ColorINeForm: TColor;

procedure TContractColorConstantDeclarationName.Run;
begin
  ColorIntForm := cBackColorXP;
  ColorINeForm := clSalmon;
end;

end.
