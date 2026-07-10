unit DfmFmxlMain;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.StdCtrls, Vcl.Grids;

type
  TDfmFmxlForm = class(TForm)
    Memo1: TMemo;
    StringGrid1: TStringGrid;
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
  end;

var
  DfmFmxlForm: TDfmFmxlForm;

implementation

{$R *.dfm}

procedure TDfmFmxlForm.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
end;

end.
