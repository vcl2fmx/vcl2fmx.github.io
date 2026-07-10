unit ContractUserDefinedGetMessageDeclaration;

interface

uses
  System.SysUtils, System.Classes;

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

