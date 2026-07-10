unit ContractLowercaseCmTcmFalsePositive;

interface

uses
  System.SysUtils, System.Classes;

type
  TContractLowercaseCmTcmFalsePositive = class
  private
    cm_custom_mode: Integer;
    tcmWidgetName: string;
  public
    procedure Run;
  end;

implementation

procedure TContractLowercaseCmTcmFalsePositive.Run;
begin
  cm_custom_mode := 1;
  tcmWidgetName := 'not a Windows message type';
end;

end.

