unit ContractMemoNameStringNoHelper;

interface

uses
  SysUtils;

function DescribesMemoClass(const AClassName: string): Boolean;

implementation

function DescribesMemoClass(const AClassName: string): Boolean;
begin
  Result := SameText(AClassName, 'TMemo');
end;

end.
