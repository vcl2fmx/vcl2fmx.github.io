unit IncludeMissing;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
{$I MissingIncludeFile.inc}
type
  TIncludeMissing = class
  public
    procedure Run;
  end;
implementation
procedure TIncludeMissing.Run;
begin
  Writeln('missing include');
end;
end.
