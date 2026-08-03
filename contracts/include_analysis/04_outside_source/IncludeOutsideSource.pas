unit IncludeOutsideSource;

interface

uses System.SysUtils;

{$I ..\outside_shared\OutsideSource.inc}

type
  TIncludeOutsideSource = class
  public
    procedure Run;
  end;

implementation

procedure TIncludeOutsideSource.Run;
begin
  Writeln('outside include');
end;

end.
