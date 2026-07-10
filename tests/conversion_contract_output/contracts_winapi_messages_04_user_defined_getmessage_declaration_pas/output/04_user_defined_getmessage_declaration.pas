unit ContractUserDefinedGetMessageDeclaration;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractUserDefinedGetMessageDeclaration = class
  public
    function GetMessage: string;
  end;
implementation
function TContractUserDefinedGetMessageDeclaration.GetMessage: string;
begin
  Result := 'not a Windows message pump call';
end;
end.
