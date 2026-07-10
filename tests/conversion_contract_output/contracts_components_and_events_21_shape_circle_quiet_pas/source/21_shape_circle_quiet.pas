unit ContractShapeCircleQuiet;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls;

type
  TContractShapeCircleQuietForm = class(TForm)
    shpLED: TShape;
    procedure FormCreate(Sender: TObject);
  end;

implementation

{$R *.dfm}

procedure TContractShapeCircleQuietForm.FormCreate(Sender: TObject);
begin
  shpLED.Shape := stCircle;
  shpLED.Brush.Color := clRed;
end;

end.
