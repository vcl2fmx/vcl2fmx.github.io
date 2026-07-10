unit IncludeNested;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
{$I FirstLevel.inc}
type
  TIncludeNested = class
  public
    procedure Run;
  end;
implementation
procedure TIncludeNested.Run;
begin
  Writeln(NestedIncludeValue);
end;
end.
