unit IncludeConditional;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
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
