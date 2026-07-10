unit UnitUtf8Accents;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  TfrmUtf8Accents = class(TForm)
    LabelAccent: TLabel;
    MemoAccent: TMemo;
  end;

var
  frmUtf8Accents: TfrmUtf8Accents;

implementation

{$R *.dfm}

end.
