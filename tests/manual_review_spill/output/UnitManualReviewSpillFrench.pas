unit UnitManualReviewSpillFrench;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants, Winapi.Messages;
type
  TFrmDesToInf = class(TForm)
    procedure ClearAndInit;
    // permet de minimiser toute l'application
  // FMX manual review: procedure WMSyscommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
    // creee le dimanche 10 janvier 2004
    // permet de deplacer les fenetres masquees
  // FMX manual review: procedure WMMoving(var Msg: TWMMove); message WM_MOVE;
  public
    { Public declarations }
    FrmCaller: TForm;
    procedure ClearAllData;
  end;
var
  FrmDesToInf: TFrmDesToInf;
implementation
{$R *.fmx}

procedure TFrmDesToInf.ClearAndInit;
begin
end;
procedure TFrmDesToInf.ClearAllData;
begin
end;
  // FMX manual review: procedure TFrmDesToInf.WMSyscommand(var Msg: TWMSysCommand);
  // FMX manual review: begin
  // FMX manual review: case (Msg.CmdType and $FFF0) of
  // FMX manual review: SC_MINIMIZE:
  // FMX manual review: begin
  // FMX manual review: Msg.Result := 0;
  // FMX manual review: Application.Minimize;
  // FMX manual review: end;
  // FMX manual review: else
  // FMX manual review: inherited;
  // FMX manual review: end;
  // FMX manual review: end;
  // FMX manual review: 
  // FMX manual review: procedure TFrmDesToInf.WMMoving(var Msg: TWMMove);
  // FMX manual review: begin
  // FMX manual review: inherited;
  // FMX manual review: if Assigned(FrmDesToInf) then
  // FMX manual review: Left := Left + 1;
  // FMX manual review: end;
  // FMX manual review: 
end.
