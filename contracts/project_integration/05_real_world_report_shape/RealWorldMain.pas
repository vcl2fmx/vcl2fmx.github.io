unit RealWorldMain;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages, Vcl.Forms, Vcl.StdCtrls, Vcl.Grids;

type
  TRealWorldForm = class(TForm)
    Memo1: TMemo;
    StringGrid1: TStringGrid;
  private
    FHandle: HWND;
  public
    procedure Run;
  end;

var
  RealWorldForm: TRealWorldForm;

implementation

{$R *.dfm}

{$I RealWorldHelpers.inc}

procedure TRealWorldForm.Run;
begin
  Memo1.Lines.Add(RealWorldHelperText);
  SendMessage(FHandle, WM_CLOSE, 0, 0);
end;

end.
