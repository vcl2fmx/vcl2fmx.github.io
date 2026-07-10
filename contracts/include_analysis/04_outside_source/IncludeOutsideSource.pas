unit IncludeOutsideSource;

interface

uses System.SysUtils;

{$I C:\New Delphi Projects\VCL2FMXConverterV5\contracts\include_analysis\outside_shared\OutsideSource.inc}

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
