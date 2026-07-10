unit ContractBorderStyleWindowState;
interface
uses System.SysUtils, System.Classes, Vcl.Forms;
type TContractBorderStyleWindowState = class(TForm) procedure Run; end;
implementation
procedure TContractBorderStyleWindowState.Run;
begin
  BorderStyle := bsDialog;
  WindowState := wsMaximized;
end;
end.

