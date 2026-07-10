unit ContractUserPeekMessageRecord;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TDomainMsg = record Text: string; end;
  TContractUserPeekMessageRecord = class public procedure PeekMessage(const AMsg: TDomainMsg); end;
implementation
procedure TContractUserPeekMessageRecord.PeekMessage(const AMsg: TDomainMsg);
begin
  Writeln(AMsg.Text);
end;
end.
