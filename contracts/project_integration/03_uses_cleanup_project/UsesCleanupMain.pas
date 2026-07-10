unit UsesCleanupMain;

interface

uses
  System.SysUtils,
  {$IFDEF USE_VCL_STYLES}
  Vcl.Themes,
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  Winapi.Messages,
  {$ENDIF}
  Vcl.Forms,
  Vcl.StdCtrls,
  System.Classes;

type
  TUsesCleanupForm = class(TForm)
    Button1: TButton;
  public
    procedure Run;
  end;

var
  UsesCleanupForm: TUsesCleanupForm;

implementation

uses
  {$IFDEF USE_VCL_WAIT}
  FireDAC.VCLUI.Wait,
  {$ENDIF}
  System.Types;

{$R *.dfm}

procedure TUsesCleanupForm.Run;
begin
  Button1.Caption := 'uses cleanup';
end;

end.
