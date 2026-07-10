unit IncludeSourceSubfolder;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
{$INCLUDE includes\SubfolderConstants.inc}
type
  TIncludeSourceSubfolder = class
  public
    procedure Run;
  end;
implementation
procedure TIncludeSourceSubfolder.Run;
begin
  Writeln(SubfolderIncludeValue);
end;
end.
