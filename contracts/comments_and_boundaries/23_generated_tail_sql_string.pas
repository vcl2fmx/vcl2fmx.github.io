unit ContractGeneratedTailSqlString;

interface

uses
  System.SysUtils;

type
  TContractGeneratedTailSqlString = class
  private
    function BuildQueryText: string;
  end;

implementation

function TContractGeneratedTailSqlString.BuildQueryText: string;
begin
  Result := 'SELECT COUNT(*) AS C FROM playlist';
end;

end.
