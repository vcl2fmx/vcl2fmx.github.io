unit RealWorldMain;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Grid, FMX.Grid.Style, FMX.Memo, FMX.Types,
  System.Classes, System.SysUtils, System.UIConsts, System.UITypes, System.Variants, Winapi.Windows;
type
  TMemo = class(FMX.Memo.TMemo)
  public
    procedure Clear; reintroduce;
  end;
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
{$R *.fmx}
{$I RealWorldHelpers.inc}
procedure TMemo.Clear;
begin
  Lines.Clear;
end;
procedure TRealWorldForm.Run;
begin
  Memo1.Lines.Add(RealWorldHelperText);
  { FMX: WM_CLOSE - Use Close or OnCloseQuery rather than posting WM_CLOSE. }
  { Original: SendMessage(FHandle, WM_CLOSE, 0, 0); }
end;
end.
