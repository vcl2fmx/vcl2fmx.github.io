unit ContractUserDefinedSendMessageCall;

interface

uses
  System.SysUtils, System.Classes;

type
  TContractUserDefinedSendMessageCall = class
  private
    procedure SendMessage(const AText: string);
  public
    procedure Run;
  end;

implementation

procedure TContractUserDefinedSendMessageCall.SendMessage(const AText: string);
begin
  Writeln(AText);
end;

procedure TContractUserDefinedSendMessageCall.Run;
begin
  SendMessage('status updated');
end;

end.

