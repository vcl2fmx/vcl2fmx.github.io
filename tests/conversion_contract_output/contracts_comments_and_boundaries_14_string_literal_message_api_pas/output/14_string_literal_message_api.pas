unit ContractStringLiteralMessageAPI;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractStringLiteralMessageAPI = class public procedure Run; end;
implementation
procedure TContractStringLiteralMessageAPI.Run;
begin
  Writeln('SendMessage(Handle, WM_CLOSE, 0, 0)');
end;
end.
