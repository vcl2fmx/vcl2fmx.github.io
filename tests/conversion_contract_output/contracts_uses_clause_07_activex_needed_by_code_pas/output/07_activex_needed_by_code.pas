unit ContractActiveXNeededByCode;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.ActiveX;
type TContractActiveXNeededByCode = class public procedure Run; end;
implementation
procedure TContractActiveXNeededByCode.Run;
begin
  CoInitialize(nil);
  CoUninitialize;
end;
end.
