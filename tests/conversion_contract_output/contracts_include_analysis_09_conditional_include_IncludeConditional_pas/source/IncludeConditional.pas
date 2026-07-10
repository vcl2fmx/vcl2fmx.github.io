unit IncludeConditional;

interface

uses System.SysUtils;

{$IFDEF MSWINDOWS}
{$INCLUDE ConditionalWin.inc}
{$ENDIF}

type
  TIncludeConditional = class
  public
    procedure Run;
  end;

implementation

procedure TIncludeConditional.Run;
begin
  Writeln('conditional include');
end;

end.
