unit IncludeBesideSource;

interface

uses System.SysUtils;

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
