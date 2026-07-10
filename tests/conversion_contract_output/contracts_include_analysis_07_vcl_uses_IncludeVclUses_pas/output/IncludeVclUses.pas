unit IncludeVclUses;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
{$I VclUses.inc}
type
  TIncludeVclUses = class
  public
    procedure Run;
  end;
implementation
procedure TIncludeVclUses.Run;
begin
  Writeln('vcl include');
end;
end.
