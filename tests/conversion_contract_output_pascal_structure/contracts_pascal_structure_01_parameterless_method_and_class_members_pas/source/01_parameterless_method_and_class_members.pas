unit ContractPascalStructureClassMembers;

interface

uses
  System.SysUtils, System.Classes, Winapi.Messages, Vcl.Forms;

type
  TContractPascalStructureClassMembers = class(TForm)
  private
    FValue: Integer;
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;
    procedure Run;
    property Value: Integer read FValue write FValue;
  end;

implementation

procedure TContractPascalStructureClassMembers.Run;
begin
  if FValue > 0 then
  begin
    Inc(FValue);
  end;
end;

end.
