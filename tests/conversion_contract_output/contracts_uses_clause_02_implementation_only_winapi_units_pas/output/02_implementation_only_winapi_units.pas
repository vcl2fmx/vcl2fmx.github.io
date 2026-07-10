unit ContractImplementationOnlyWinapiUnits;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractImplementationOnlyWinapiUnits = class(TForm)
  public
    procedure Run;
  end;
implementation
procedure TContractImplementationOnlyWinapiUnits.Run;
begin
  Caption := 'Implementation uses cleanup sample';
end;
end.
