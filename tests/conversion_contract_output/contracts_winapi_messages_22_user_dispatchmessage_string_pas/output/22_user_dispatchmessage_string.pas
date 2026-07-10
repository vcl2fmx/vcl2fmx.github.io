unit ContractUserDispatchMessageString;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
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
