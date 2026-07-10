unit UsesCleanupMain;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.StdCtrls, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants
  {$IFDEF USE_VCL_STYLES}
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  {$ENDIF}
;
type
  TUsesCleanupForm = class(TForm)
    Button1: TButton;
  public
    procedure Run;
  end;
var
  UsesCleanupForm: TUsesCleanupForm;
implementation
{$R *.fmx}

procedure TUsesCleanupForm.Run;
begin
  Button1.Text := 'uses cleanup';
end;
end.
