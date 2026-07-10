unit UnitManualReviewSpillGermanSpanish;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants, Winapi.Messages;
type
  TFrmDisplay = class(TForm)
    // Espanol: detecta cambio de resolucion
    // Deutsch: Fensterposition nach Anzeigewechsel pruefen
  // FMX manual review: procedure WMDisplayChange(var Message: TMessage); message WM_DISPLAYCHANGE;
  // FMX manual review: procedure WMWINDOWPOSCHANGED(var Msg: TMessage); message WM_WINDOWPOSCHANGED;
  public
    procedure RebuildLayout;
  end;
var
  FrmDisplay: TFrmDisplay;
implementation
{$R *.fmx}

procedure TFrmDisplay.RebuildLayout;
begin
end;
  // FMX manual review: procedure TFrmDisplay.WMDisplayChange(var Message: TMessage);
  // FMX manual review: begin
  // FMX manual review: inherited;
  // FMX manual review: RebuildLayout;
  // FMX manual review: end;
  // FMX manual review: 
procedure TFrmDisplay.WMWINDOWPOSCHANGED(var Msg: TMessage);
begin
  inherited;
  RebuildLayout;
end;
end.
