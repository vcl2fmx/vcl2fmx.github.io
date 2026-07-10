unit UnitDevExpressMock;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms;

type
  TFormDevExpressMock = class(TForm)
    cxButton1: TcxButton;
    cxTextEdit1: TcxTextEdit;
    cxMemo1: TcxMemo;
    cxMaskEdit1: TcxMaskEdit;
    cxGrid1: TcxGrid;
    dxRibbon1: TdxRibbon;
    procedure cxButton1Click(Sender: TObject);
    procedure cxTextEdit1Change(Sender: TObject);
  end;

implementation

{$R *.dfm}

procedure TFormDevExpressMock.cxButton1Click(Sender: TObject);
begin
end;

procedure TFormDevExpressMock.cxTextEdit1Change(Sender: TObject);
begin
end;

end.
