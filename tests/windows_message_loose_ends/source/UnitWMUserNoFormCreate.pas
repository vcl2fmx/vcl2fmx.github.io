unit UnitWMUserNoFormCreate;

interface

uses
  System.Classes,
  Winapi.Messages,
  Vcl.Forms;

type
  TWMUserNoFormCreateForm = class(TForm)
  private
    procedure WMCustom(var Msg: TMessage); message WM_USER;
  end;

implementation

procedure TWMUserNoFormCreateForm.WMCustom(var Msg: TMessage);
begin
  inherited;
end;

end.
