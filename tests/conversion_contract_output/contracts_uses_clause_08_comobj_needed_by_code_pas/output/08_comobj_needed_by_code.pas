unit ContractComObjNeededByCode;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, System.Win.ComObj;
type TContractComObjNeededByCode = class public procedure Run; end;
implementation
procedure TContractComObjNeededByCode.Run;
var V: Variant;
begin
  V := CreateOleObject('Scripting.Dictionary');
end;
end.
