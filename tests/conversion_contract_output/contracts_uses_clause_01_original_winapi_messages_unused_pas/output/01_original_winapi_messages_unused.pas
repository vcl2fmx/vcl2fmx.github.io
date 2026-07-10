unit ContractOriginalWinapiMessagesUnused;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractOriginalWinapiMessagesUnused = class(TForm)
  public
    procedure Run;
  end;
implementation
procedure TContractOriginalWinapiMessagesUnused.Run;
begin
  Caption := 'No active Windows message usage';
end;
end.
