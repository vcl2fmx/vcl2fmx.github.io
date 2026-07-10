unit ContractSystemUnitsRetained;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.Generics.Collections,
  System.Rtti, System.SysUtils, System.Variants;
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
