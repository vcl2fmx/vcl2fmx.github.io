unit ContractPlainUtilityInterfaceUsesNoFMX;

interface

uses
  SysUtils;

function FirstCharUpperCase(const AValue: string): string;

implementation

uses
  Classes;

function FirstCharUpperCase(const AValue: string): string;
begin
  if AValue = '' then
    Exit('');
  Result := UpperCase(Copy(AValue, 1, 1)) + Copy(AValue, 2, MaxInt);
end;

end.
