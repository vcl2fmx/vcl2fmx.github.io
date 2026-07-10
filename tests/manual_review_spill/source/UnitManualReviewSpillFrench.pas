unit UnitManualReviewSpillFrench;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Winapi.Messages;

type
  TFrmDesToInf = class(TForm)
    procedure ClearAndInit;

    // permet de minimiser toute l'application
    procedure WMSyscommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
    // creee le dimanche 10 janvier 2004
    // permet de deplacer les fenetres masquees
    procedure WMMoving(var Msg: TWMMove); message WM_MOVE;
  public
    { Public declarations }
    FrmCaller: TForm;
    procedure ClearAllData;
  end;

var
  FrmDesToInf: TFrmDesToInf;

implementation

uses
  Vcl.Dialogs;

{$R *.dfm}

procedure TFrmDesToInf.ClearAndInit;
begin
end;

procedure TFrmDesToInf.ClearAllData;
begin
end;

procedure TFrmDesToInf.WMSyscommand(var Msg: TWMSysCommand);
begin
  case (Msg.CmdType and $FFF0) of
    SC_MINIMIZE:
    begin
      Msg.Result := 0;
      Application.Minimize;
    end;
  else
    inherited;
  end;
end;

procedure TFrmDesToInf.WMMoving(var Msg: TWMMove);
begin
  inherited;
  if Assigned(FrmDesToInf) then
    Left := Left + 1;
end;

end.
