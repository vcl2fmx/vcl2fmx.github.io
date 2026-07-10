unit ContractImplementationOnlyWinapiUnits;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms;

type
  TContractImplementationOnlyWinapiUnits = class(TForm)
  public
    procedure Run;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, Winapi.ActiveX, Winapi.Messages;

procedure TContractImplementationOnlyWinapiUnits.Run;
begin
  Caption := 'Implementation uses cleanup sample';
end;

end.

