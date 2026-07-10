unit ContractStringLiteralMessageAPI;
interface
uses System.SysUtils, System.Classes;
type TContractStringLiteralMessageAPI = class public procedure Run; end;
implementation
procedure TContractStringLiteralMessageAPI.Run;
begin
  Writeln('SendMessage(Handle, WM_CLOSE, 0, 0)');
end;
end.

