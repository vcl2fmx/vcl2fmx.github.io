unit ContractAlphaBlendValue;
interface
uses System.SysUtils, System.Classes, Vcl.Forms;
type TContractAlphaBlendValue = class(TForm) procedure Run; end;
implementation
procedure TContractAlphaBlendValue.Run;
begin
  AlphaBlendValue := 128;
end;
end.

