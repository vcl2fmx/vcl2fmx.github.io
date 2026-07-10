unit IncludeRecursive;

interface

uses System.SysUtils;

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
