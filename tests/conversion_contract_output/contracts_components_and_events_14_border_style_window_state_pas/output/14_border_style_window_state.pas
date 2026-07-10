unit ContractBorderStyleWindowState;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractBorderStyleWindowState = class(TForm) procedure Run; end;
implementation
procedure TContractBorderStyleWindowState.Run;
begin
  BorderStyle := bsDialog;
  WindowState := TWindowState.wsMaximized;
end;
end.
