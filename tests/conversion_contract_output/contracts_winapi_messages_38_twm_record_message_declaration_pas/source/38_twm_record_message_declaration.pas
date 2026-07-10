unit ContractTWMRecordMessageDeclaration;

interface

uses System.SysUtils, System.Classes, Winapi.Messages;

type
  TContractTWMRecordMessageDeclaration = class
  private
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  public
    procedure Run;
  end;

implementation

procedure TContractTWMRecordMessageDeclaration.WMSize(var Message: TWMSize);
begin
  Writeln(Message.Width);
end;

procedure TContractTWMRecordMessageDeclaration.Run;
begin
  Writeln('message declaration');
end;

end.
