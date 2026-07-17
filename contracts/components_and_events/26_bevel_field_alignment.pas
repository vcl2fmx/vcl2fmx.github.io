unit ContractBevelFieldAlignment;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls;

type
  TContractBevelFieldAlignmentForm = class(TForm)
    bevelLine: TBevel;
    procedure FormCreate(Sender: TObject);
  end;

implementation

{$R *.dfm}

procedure TContractBevelFieldAlignmentForm.FormCreate(Sender: TObject);
begin
  Caption := 'Bevel field alignment';
end;

end.
