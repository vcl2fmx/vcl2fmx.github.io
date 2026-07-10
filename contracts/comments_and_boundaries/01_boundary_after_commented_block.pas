unit ContractBoundaryAfterCommentedBlock;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;

type
  TContractBoundaryAfterCommentedBlock = class
  public
    procedure Run;
    procedure SendMessage(const AText: string);
  end;

implementation

procedure TContractBoundaryAfterCommentedBlock.Run;
begin
  SendMessage(
    0,
    WM_CLOSE,
    0,
    0)
end;

procedure TContractBoundaryAfterCommentedBlock.SendMessage(const AText: string);
begin
  Writeln(AText);
end;

end.

