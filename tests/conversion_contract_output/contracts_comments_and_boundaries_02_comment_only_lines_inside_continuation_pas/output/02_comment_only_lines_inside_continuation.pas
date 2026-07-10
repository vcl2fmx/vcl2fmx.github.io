unit ContractCommentOnlyLinesInsideContinuation;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants, Winapi.Windows;
type
  TContractCommentOnlyLinesInsideContinuation = class
  public
    procedure Run;
  end;
implementation
procedure TContractCommentOnlyLinesInsideContinuation.Run;
begin
  if True then
  // FMX manual review: SendMessage(
  // FMX manual review: 0,
  // FMX manual review: WM_CLOSE,
  // FMX manual review: // comment-only source line must remain commented with the disabled block
  // FMX manual review: 0,
  // FMX manual review: 0);
end;
end.
