unit ContractOriginalWinapiMessagesUnused;

interface

uses
  System.SysUtils, System.Classes, Winapi.Messages, Vcl.Forms;

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

