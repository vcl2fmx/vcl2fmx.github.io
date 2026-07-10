unit ContractLongLine;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractLongLine = class public procedure Run; end;
implementation
procedure TContractLongLine.Run;
begin
  Writeln('This is a deliberately long line used to make sure wrapping and parsing do not corrupt source text during conversion contract tests for the converter pipeline and generated reports.');
end;
end.
