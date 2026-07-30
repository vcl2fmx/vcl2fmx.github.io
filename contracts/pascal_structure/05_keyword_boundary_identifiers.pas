unit ContractKeywordBoundaryIdentifiers;

interface

uses
  System.SysUtils;

type
  TContractKeywordBoundaryIdentifiers = class
  public
    procedure Run;
  end;

implementation

procedure TContractKeywordBoundaryIdentifiers.Run;
var
  UsesLegacyMode: Boolean;
  TypeName: string;
  VariableCount: Integer;
  ConstValue: Integer;
begin
  UsesLegacyMode := True;
  TypeName := 'Sample';
  VariableCount := Length(TypeName);
  ConstValue := VariableCount;
  Writeln(BoolToStr(UsesLegacyMode, True), ConstValue);
end;

end.
