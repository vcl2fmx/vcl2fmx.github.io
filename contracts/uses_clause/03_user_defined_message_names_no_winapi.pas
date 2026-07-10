unit ContractUserDefinedMessageNamesNoWinapi;

interface

uses
  System.SysUtils, System.Classes;

type
  TContractUserDefinedMessageNamesNoWinapi = class
  public
    procedure SendMessage(const AText: string);
    procedure PostMessage(const AText: string);
    function GetMessage: string;
  end;

implementation

procedure TContractUserDefinedMessageNamesNoWinapi.SendMessage(const AText: string);
begin
  Writeln(AText);
end;

procedure TContractUserDefinedMessageNamesNoWinapi.PostMessage(const AText: string);
begin
  Writeln(AText);
end;

function TContractUserDefinedMessageNamesNoWinapi.GetMessage: string;
begin
  Result := 'domain method';
end;

end.

