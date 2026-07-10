unit UnitManualReviewSpillGermanSpanish;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Winapi.Messages;

type
  TFrmDisplay = class(TForm)
    // Espanol: detecta cambio de resolucion
    // Deutsch: Fensterposition nach Anzeigewechsel pruefen
    procedure WMDisplayChange(var Message: TMessage); message WM_DISPLAYCHANGE;
    procedure WMWINDOWPOSCHANGED(var Msg: TMessage); message WM_WINDOWPOSCHANGED;
  public
    procedure RebuildLayout;
  end;

var
  FrmDisplay: TFrmDisplay;

implementation

{$R *.dfm}

procedure TFrmDisplay.RebuildLayout;
begin
end;

procedure TFrmDisplay.WMDisplayChange(var Message: TMessage);
begin
  inherited;
  RebuildLayout;
end;

procedure TFrmDisplay.WMWINDOWPOSCHANGED(var Msg: TMessage);
begin
  inherited;
  RebuildLayout;
end;

end.
