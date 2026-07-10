unit IncludeBesideSource;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
{$I LocalConstants.inc}
type
  TIncludeBesideSource = class
  public
    procedure Run;
  end;
implementation
procedure TIncludeBesideSource.Run;
begin
  Writeln(LocalIncludeValue);
end;
end.
