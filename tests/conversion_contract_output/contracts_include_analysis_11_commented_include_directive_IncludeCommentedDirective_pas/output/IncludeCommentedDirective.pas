unit IncludeCommentedDirective;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
// {$I CommentedOutLine.inc}
{ Comment block: {$INCLUDE CommentedOutBrace.inc} }
(* Comment block: {$I CommentedOutParen.inc} *)
// (*$I CommentedOutParenDirective.inc*)
procedure RunCommentedIncludeDirective;
implementation
procedure RunCommentedIncludeDirective;
begin
  Writeln('commented include directives must stay inactive');
end;
end.
