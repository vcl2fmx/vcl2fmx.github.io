unit ContractBraceCommentMessageAPI;
interface
uses System.SysUtils, System.Classes;
type TContractBraceCommentMessageAPI = class public procedure Run; end;
implementation
procedure TContractBraceCommentMessageAPI.Run;
begin
  { SendMessage(Handle, WM_CLOSE, 0, 0); }
  Writeln('brace comment only');
end;
end.

