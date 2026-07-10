unit IncludeMissing;

interface

uses System.SysUtils;

{$I MissingIncludeFile.inc}

type
  TIncludeMissing = class
  public
    procedure Run;
  end;

implementation

procedure TIncludeMissing.Run;
begin
  Writeln('missing include');
end;

end.
