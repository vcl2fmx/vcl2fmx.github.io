unit ContractOpenOptionEnums;
interface
uses FMX.Controls, FMX.Dialogs, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UITypes, System.Variants;
type TContractOpenOptionEnums = class private OpenDialog1: TOpenDialog; public procedure Run; end;
implementation
procedure TContractOpenOptionEnums.Run;
begin
  OpenDialog1.Options := OpenDialog1.Options + [TOpenOption.ofAllowMultiSelect];
end;
end.
