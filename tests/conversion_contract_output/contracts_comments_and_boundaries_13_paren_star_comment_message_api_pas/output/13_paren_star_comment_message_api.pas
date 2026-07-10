unit ContractParenStarCommentMessageAPI;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractParenStarCommentMessageAPI = class public procedure Run; end;
implementation
procedure TContractParenStarCommentMessageAPI.Run;
begin
  (* PostMessage(Handle, WM_USER + 1, 0, 0); *)
  Writeln('paren star comment only');
end;
end.
