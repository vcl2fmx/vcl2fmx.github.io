unit ContractActiveXNeededByCode;
interface
uses System.SysUtils, System.Classes, Winapi.ActiveX;
type TContractActiveXNeededByCode = class public procedure Run; end;
implementation
procedure TContractActiveXNeededByCode.Run;
begin
  CoInitialize(nil);
  CoUninitialize;
end;
end.

