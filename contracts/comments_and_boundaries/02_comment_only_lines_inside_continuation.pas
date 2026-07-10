unit ContractCommentOnlyLinesInsideContinuation;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages;

type
  TContractCommentOnlyLinesInsideContinuation = class
  public
    procedure Run;
  end;

implementation

procedure TContractCommentOnlyLinesInsideContinuation.Run;
begin
  if True then
    SendMessage(
      0,
      WM_CLOSE,
      // comment-only source line must remain commented with the disabled block
      0,
      0);
end;

end.

