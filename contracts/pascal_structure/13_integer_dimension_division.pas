unit ContractIntegerDimensionDivision;

interface

uses
  Vcl.Forms,
  Vcl.Controls,
  Vcl.ExtCtrls;

type
  TContractIntegerDimensionDivision = class(TForm)
  private
    Image1: TImage;
    CenterX, CenterY: Integer;
    OffsetX, OffsetY: Integer;
    procedure UpdateCenter;
  end;

implementation

procedure TContractIntegerDimensionDivision.UpdateCenter;
begin
  CenterX := Image1.Width div 2 + OffsetX;
  CenterY := Image1.Height div 2 + OffsetY;
end;

end.
