unit IncludeWinapiMessageHandler;

interface

uses System.SysUtils;

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
