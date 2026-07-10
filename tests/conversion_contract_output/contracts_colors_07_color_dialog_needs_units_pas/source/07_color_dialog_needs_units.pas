unit ContractColorDialogNeedsUnits;
interface
uses System.SysUtils, System.Classes, Vcl.Dialogs;
type TContractColorDialogNeedsUnits = class private ColorDialog1: TColorDialog; public procedure Run; end;
implementation
procedure TContractColorDialogNeedsUnits.Run;
begin
  if ColorDialog1.Execute then Writeln('ok');
end;
end.

