unit ContractCustomMessageConstantNotPrefix;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
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
