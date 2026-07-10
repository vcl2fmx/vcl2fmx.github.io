unit ContractUserDispatchMessageString;
interface
uses System.SysUtils, System.Classes;
type TContractUserDispatchMessageString = class public procedure DispatchMessage(const AText: string); procedure Run; end;
implementation
procedure TContractUserDispatchMessageString.DispatchMessage(const AText: string);
begin
  Writeln(AText);
end;
procedure TContractUserDispatchMessageString.Run;
begin
  DispatchMessage('Msg is only a word in a string');
end;
end.

