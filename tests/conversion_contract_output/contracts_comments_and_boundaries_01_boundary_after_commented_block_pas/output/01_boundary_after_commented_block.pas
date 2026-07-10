unit ContractBoundaryAfterCommentedBlock;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type
  TContractBoundaryAfterCommentedBlock = class
  public
    procedure Run;
    procedure SendMessage(const AText: string);
  end;
implementation
procedure TContractBoundaryAfterCommentedBlock.Run;
begin
  // FMX manual review: SendMessage(
  // FMX manual review: 0,
  // FMX manual review: WM_CLOSE,
  // FMX manual review: 0,
  // FMX manual review: 0)
end;
procedure TContractBoundaryAfterCommentedBlock.SendMessage(const AText: string);
begin
  Writeln(AText);
end;
end.
