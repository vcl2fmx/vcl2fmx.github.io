unit RegressionForm;

interface

// Comment must remain unchanged: Vcl.Controls, Vcl.ImgList, Vcl.ToolWin.
(*
type
  TFakeForm = class(TForm)
  end;
*)

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls
  {$IFDEF REGULAR_EXP}
  , RegularExpressions
  {$ENDIF}
  ;

type
  TRegressionForm = class(TForm)
    Memo1: TMemo;
    RadioButton1: TRadioButton;
    procedure RadioButton1Click(Sender: TObject);
  private
    FColors: array[0..3] of TColor;
  end;

implementation

Uses
  System.StrUtils, Vcl.Graphics;

{$R *.dfm}

procedure TRegressionForm.RadioButton1Click(Sender: TObject);
begin
  FColors[0] := clBlack;
  FColors[1] := clGreen;
  FColors[2] := clRed;
  FColors[3] := clWhite;
  Self.Color := clActiveCaption;
  Memo1.Clear;
  // SendMessage(Handle, WM_USER, 0, 0);
  /// Panels[0].Width :=
end;

initialization
  // Generated methods must never be inserted in this block.

end.
