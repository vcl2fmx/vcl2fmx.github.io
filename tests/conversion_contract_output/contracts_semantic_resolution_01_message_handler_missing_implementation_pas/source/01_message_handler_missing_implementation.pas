unit ContractSemanticMissingMessageImplementation;

interface

uses
  Winapi.Messages;

type
  TContractSemanticMissingMessageImplementation = class
  private
    procedure WMSysCommand(var Message: TWMSysCommand); message WM_SYSCOMMAND;
  public
    procedure Run;
  end;

implementation

procedure TContractSemanticMissingMessageImplementation.Run;
begin
end;

end.
