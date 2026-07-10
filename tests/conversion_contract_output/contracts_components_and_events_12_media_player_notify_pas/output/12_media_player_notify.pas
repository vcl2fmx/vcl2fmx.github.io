unit ContractMediaPlayerNotify;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Media, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type TContractMediaPlayerNotify = class(TForm) MediaPlayer1: TMediaPlayer; procedure Run; end;
implementation
procedure TContractMediaPlayerNotify.Run;
begin
  // FMX manual review: MediaPlayer1.Notify := True;
end;
end.
