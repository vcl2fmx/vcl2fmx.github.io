unit IncludeSourceSubfolder;

interface

uses System.SysUtils;

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
