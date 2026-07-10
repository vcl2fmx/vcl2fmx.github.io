unit IncludeNested;

interface

uses System.SysUtils;

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
