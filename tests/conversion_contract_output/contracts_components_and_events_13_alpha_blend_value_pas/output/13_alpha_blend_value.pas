unit ContractAlphaBlendValue;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractAlphaBlendValue = class(TForm) procedure Run; end;
implementation
procedure TContractAlphaBlendValue.Run;
begin
  AlphaBlendValue := 128;
end;
end.
