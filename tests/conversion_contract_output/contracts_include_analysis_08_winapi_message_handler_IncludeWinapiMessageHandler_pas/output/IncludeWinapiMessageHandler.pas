unit IncludeWinapiMessageHandler;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
{$I MessageHandler.inc}
type
  TIncludeWinapiMessageHandler = class
  public
    procedure Run;
  end;
implementation
procedure TIncludeWinapiMessageHandler.Run;
begin
  Writeln('message include');
end;
end.
