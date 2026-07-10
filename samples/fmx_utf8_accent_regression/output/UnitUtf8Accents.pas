unit UnitUtf8Accents;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Memo, FMX.StdCtrls, FMX.Types, System.Classes,
  System.SysUtils, System.UIConsts, System.UITypes, System.Variants, Winapi.Windows;
type
  TMemo = class(FMX.Memo.TMemo)
  public
    procedure Clear; reintroduce;
  end;
  TfrmUtf8Accents = class(TForm)
    LabelAccent: TLabel;
    MemoAccent: TMemo;
  end;
var
  frmUtf8Accents: TfrmUtf8Accents;
implementation
{$R *.fmx}

procedure TMemo.Clear;
begin
  Lines.Clear;
end;
end.
