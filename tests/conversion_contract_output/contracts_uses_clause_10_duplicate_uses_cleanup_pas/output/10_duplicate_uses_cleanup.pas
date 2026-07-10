unit ContractDuplicateUsesCleanup;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractDuplicateUsesCleanup = class(TForm) public procedure Run; end;
implementation
procedure TContractDuplicateUsesCleanup.Run;
begin
  Caption := 'duplicates';
end;
end.
