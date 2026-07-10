unit ContractUTF8Comments;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractUTF8Comments = class public procedure Run; end;
implementation
procedure TContractUTF8Comments.Run;
begin
  // accents: cafe naive facade resume
  Writeln('utf8');
end;
end.
