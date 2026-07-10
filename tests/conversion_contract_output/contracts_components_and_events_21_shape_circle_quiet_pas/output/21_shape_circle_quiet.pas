unit ContractShapeCircleQuiet;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Objects, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants;
type
  TContractShapeCircleQuietForm = class(TForm)
    shpLED: TEllipse;
    procedure FormCreate(Sender: TObject);
  end;
implementation
{$R *.fmx}

procedure TContractShapeCircleQuietForm.FormCreate(Sender: TObject);
begin
  // FMX: redundant VCL Shape assignment omitted; shpLED is generated as TEllipse.
  shpLED.Fill.Color := claRed;
end;
end.
