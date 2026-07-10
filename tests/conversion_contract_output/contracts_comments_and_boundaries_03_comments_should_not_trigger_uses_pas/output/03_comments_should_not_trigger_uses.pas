unit ContractCommentsShouldNotTriggerUses;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractCommentsShouldNotTriggerUses = class
  public
    procedure Run;
  end;
implementation
procedure TContractCommentsShouldNotTriggerUses.Run;
begin
  // SendMessage(Handle, WM_CLOSE, 0, 0);
  { PostMessage(Handle, WM_USER + 1, 0, 0); }
  Writeln('comments only');
end;
end.
