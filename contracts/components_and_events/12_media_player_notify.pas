unit ContractMediaPlayerNotify;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.MPlayer;
type TContractMediaPlayerNotify = class(TForm) MediaPlayer1: TMediaPlayer; procedure Run; end;
implementation
procedure TContractMediaPlayerNotify.Run;
begin
  MediaPlayer1.Notify := True;
end;
end.

