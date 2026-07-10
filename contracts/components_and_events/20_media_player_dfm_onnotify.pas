unit ContractMediaPlayerDfmOnNotify;

interface

uses
  System.Classes, Vcl.Forms, Vcl.MPlayer;

type
  TContractMediaPlayerDfmOnNotifyForm = class(TForm)
  private
    MediaPlayer1: TMediaPlayer;
    procedure MediaPlayer1Notify(Sender: TObject);
  end;

implementation

procedure TContractMediaPlayerDfmOnNotifyForm.MediaPlayer1Notify(Sender: TObject);
begin
end;

end.