unit ContractUserPeekMessageRecord;
interface
uses System.SysUtils, System.Classes;
type
  TDomainMsg = record Text: string; end;
  TContractUserPeekMessageRecord = class public procedure PeekMessage(const AMsg: TDomainMsg); end;
implementation
procedure TContractUserPeekMessageRecord.PeekMessage(const AMsg: TDomainMsg);
begin
  Writeln(AMsg.Text);
end;
end.

