unit ContractUserPostMessageWithWMText;
interface
uses System.SysUtils, System.Classes;
type TContractUserPostMessageWithWMText = class public procedure PostMessage(const AText: string); procedure Run; end;
implementation
procedure TContractUserPostMessageWithWMText.PostMessage(const AText: string);
begin
  Writeln(AText);
end;
procedure TContractUserPostMessageWithWMText.Run;
begin
  PostMessage('WM_ is just text here');
end;
end.

