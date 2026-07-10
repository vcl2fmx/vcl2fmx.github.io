unit ContractComObjNeededByCode;
interface
uses System.SysUtils, System.Classes, ComObj;
type TContractComObjNeededByCode = class public procedure Run; end;
implementation
procedure TContractComObjNeededByCode.Run;
var V: Variant;
begin
  V := CreateOleObject('Scripting.Dictionary');
end;
end.

