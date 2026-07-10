unit ContractMediaPlayerDfmOnNotify;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Media, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractMediaPlayerDfmOnNotifyForm = class(TForm)
  private
    MediaPlayer1: TMediaPlayer;
    procedure MediaPlayer1Notify(Sender: TObject);
  end;
implementation
{$R *.fmx}

procedure TContractMediaPlayerDfmOnNotifyForm.MediaPlayer1Notify(Sender: TObject);
begin
end;
end.
