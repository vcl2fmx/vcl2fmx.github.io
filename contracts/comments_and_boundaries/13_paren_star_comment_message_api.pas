unit ContractParenStarCommentMessageAPI;
interface
uses System.SysUtils, System.Classes;
type TContractParenStarCommentMessageAPI = class public procedure Run; end;
implementation
procedure TContractParenStarCommentMessageAPI.Run;
begin
  (* PostMessage(Handle, WM_USER + 1, 0, 0); *)
  Writeln('paren star comment only');
end;
end.

