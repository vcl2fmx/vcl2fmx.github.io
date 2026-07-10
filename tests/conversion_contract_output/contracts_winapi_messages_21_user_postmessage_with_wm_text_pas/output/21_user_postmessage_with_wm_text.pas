unit ContractUserPostMessageWithWMText;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
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
