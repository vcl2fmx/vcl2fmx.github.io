unit KeywordBoundaryDeclarations;

interface

const
  UsesLegacyMode = False;
  ConstField = 1;

var
  VariableCount: Integer;

type
  TypeAliasRecord = record
    UsesField: string;
  end;

procedure Run;

implementation

procedure Run;
begin
  VariableCount := ConstField;
end;

end.
