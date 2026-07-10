unit ContractModalResultConstants;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UITypes, System.Variants;
type TContractModalResultConstants = class(TForm) public procedure Run; end;
implementation
procedure TContractModalResultConstants.Run;
begin
  ModalResult := mrCancel;
end;
end.
