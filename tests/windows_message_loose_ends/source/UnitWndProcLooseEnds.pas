unit UnitWndProcLooseEnds;

interface

uses
  System.Classes,
  Winapi.Messages,
  Vcl.Forms;

type
  TWndProcLooseEndsForm = class(TForm)
  protected
    procedure WndProc(var Msg: TMessage); override;
  end;

implementation

procedure TWndProcLooseEndsForm.WndProc(var Msg: TMessage);
begin
  case Msg.Msg of
    WM_SIZE:
      inherited;
  else
    inherited;
  end;
end;

end.
