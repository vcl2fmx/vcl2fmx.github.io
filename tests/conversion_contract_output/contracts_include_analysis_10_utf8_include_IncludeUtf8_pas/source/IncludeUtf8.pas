unit IncludeUtf8;

interface

uses System.SysUtils;

{$I Utf8Text.inc}

type
  TIncludeUtf8 = class
  public
    procedure Run;
  end;

implementation

procedure TIncludeUtf8.Run;
begin
  Writeln(Utf8IncludeText);
end;

end.
