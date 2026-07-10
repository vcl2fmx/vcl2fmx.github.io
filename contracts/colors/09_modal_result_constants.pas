unit ContractModalResultConstants;
interface
uses System.SysUtils, System.Classes, Vcl.Forms;
type TContractModalResultConstants = class(TForm) public procedure Run; end;
implementation
procedure TContractModalResultConstants.Run;
begin
  ModalResult := mrCancel;
end;
end.

