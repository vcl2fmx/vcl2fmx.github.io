unit ContractSendMessageSystemCommandClose;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type TContractSendMessageSystemCommandClose = class(TForm) public procedure Run; end;
implementation
procedure TContractSendMessageSystemCommandClose.Run;
begin
  Close;
end;
end.
