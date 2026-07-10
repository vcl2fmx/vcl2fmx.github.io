unit ContractWndProcOverride;

interface

uses
  System.SysUtils, System.Classes, Winapi.Messages, Vcl.Forms;

type
  TContractWndProcOverride = class(TForm)
  protected
    procedure WndProc(var Msg: TMessage); override;
  end;

implementation

procedure TContractWndProcOverride.WndProc(var Msg: TMessage);
begin
  if Msg.Msg = WM_SIZE then
    Caption := 'sized';
  inherited;
end;

end.

