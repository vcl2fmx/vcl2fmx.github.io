unit ContractSystemUnitsRetained;
interface
uses System.SysUtils, System.Classes, System.Generics.Collections, System.Rtti;
type TContractSystemUnitsRetained = class public procedure Run; end;
implementation
procedure TContractSystemUnitsRetained.Run;
var L: TObjectList<TObject>; V: TValue;
begin
  L := TObjectList<TObject>.Create;
  V := TValue.From<Integer>(L.Count);
  L.Free;
end;
end.

