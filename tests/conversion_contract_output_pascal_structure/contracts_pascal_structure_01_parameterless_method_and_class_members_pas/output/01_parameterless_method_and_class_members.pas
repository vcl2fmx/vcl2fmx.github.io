unit ContractPascalStructureClassMembers;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UIConsts, System.UITypes, System.Variants;
type
  TContractPascalStructureClassMembers = class(TForm)
  private
    FValue: Integer;
  // FMX manual review: procedure WMSize(var Msg: TWMSize); message WM_SIZE;
    procedure Run;
    property Value: Integer read FValue write FValue;
  end;
implementation
procedure TContractPascalStructureClassMembers.Run;
begin
  if FValue > 0 then
  begin
    Inc(FValue);
  end;
end;
end.
