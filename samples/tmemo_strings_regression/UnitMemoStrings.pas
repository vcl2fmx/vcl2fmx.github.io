unit UnitMemoStrings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  TfrmMemoStrings = class(TForm)
    MemoPlain: TMemo;
    MemoEncoded: TMemo;
  end;

var
  frmMemoStrings: TfrmMemoStrings;

implementation

{$R *.dfm}

end.
