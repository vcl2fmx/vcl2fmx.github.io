unit ContractDuplicateUsesCleanup;
interface
uses SysUtils, System.SysUtils, Classes, System.Classes, Vcl.Forms, Forms;
type TContractDuplicateUsesCleanup = class(TForm) public procedure Run; end;
implementation
procedure TContractDuplicateUsesCleanup.Run;
begin
  Caption := 'duplicates';
end;
end.

