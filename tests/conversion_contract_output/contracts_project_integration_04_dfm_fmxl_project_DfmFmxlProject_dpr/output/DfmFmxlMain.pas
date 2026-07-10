unit DfmFmxlMain;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Grid, FMX.Grid.Style, FMX.Memo, FMX.Types,
  System.Classes, System.SysUtils, System.Variants;
type
  TMemo = class(FMX.Memo.TMemo)
  public
    procedure Clear; reintroduce;
  end;
  TDfmFmxlForm = class(TForm)
    Memo1: TMemo;
    StringGrid1: TStringGrid;
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
  end;
var
  DfmFmxlForm: TDfmFmxlForm;
implementation
{$R *.fmx}

procedure TMemo.Clear;
begin
  Lines.Clear;
end;
procedure TDfmFmxlForm.StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
end;
end.
