unit UnitDevExpressMock;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants;
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
{$R *.fmx}
procedure TFormDevExpressMock.cxButton1Click(Sender: TObject);
begin
end;
procedure TFormDevExpressMock.cxTextEdit1Change(Sender: TObject);
begin
end;
end.
