unit ContractNestedDefaultParentheses;

interface

type
  TContractNestedDefaultParentheses = class
  public
    function ReadValue(AValue: Integer = Ord((1))): string;
  end;

implementation

function TContractNestedDefaultParentheses.ReadValue(AValue: Integer): string;
begin
  Result := IntToStr(AValue);
end;

end.
