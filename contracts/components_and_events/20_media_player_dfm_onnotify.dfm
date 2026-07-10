object ContractMediaPlayerDfmOnNotifyForm: TContractMediaPlayerDfmOnNotifyForm
  Left = 0
  Top = 0
  Caption = 'Media Notify DFM Contract'
  ClientHeight = 240
  ClientWidth = 320
  object MediaPlayer1: TMediaPlayer
    Left = 16
    Top = 16
    OnNotify = MediaPlayer1Notify
  end
end