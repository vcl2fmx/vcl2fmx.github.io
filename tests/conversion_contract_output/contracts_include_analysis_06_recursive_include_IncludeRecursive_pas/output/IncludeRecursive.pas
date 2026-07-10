unit IncludeRecursive;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
{$I LoopA.inc}
type
  TIncludeRecursive = class
  public
    procedure Run;
  end;
implementation
procedure TIncludeRecursive.Run;
begin
  Writeln('recursive include');
end;
end.
