unit IncludeVclUses;

interface

uses System.SysUtils;

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
