unit ContractCommentsShouldNotTriggerUses;

interface

uses
  System.SysUtils, System.Classes;

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

