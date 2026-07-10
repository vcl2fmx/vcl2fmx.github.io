unit ContractCustomMessageConstantNotPrefix;
interface
uses System.SysUtils, System.Classes;
const AppMessageClose = 1001;
type TContractCustomMessageConstantNotPrefix = class public procedure SendMessage(const AName: string; ACode: Integer); procedure Run; end;
implementation
procedure TContractCustomMessageConstantNotPrefix.SendMessage(const AName: string; ACode: Integer);
begin
  Writeln(AName + IntToStr(ACode));
end;
procedure TContractCustomMessageConstantNotPrefix.Run;
begin
  SendMessage('Close', AppMessageClose);
end;
end.

