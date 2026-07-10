unit ContractOpenOptionEnums;
interface
uses System.SysUtils, System.Classes, Vcl.Dialogs;
type TContractOpenOptionEnums = class private OpenDialog1: TOpenDialog; public procedure Run; end;
implementation
procedure TContractOpenOptionEnums.Run;
begin
  OpenDialog1.Options := OpenDialog1.Options + [ofAllowMultiSelect];
end;
end.

