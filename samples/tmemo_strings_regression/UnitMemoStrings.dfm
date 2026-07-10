object frmMemoStrings: TfrmMemoStrings
  Left = 0
  Top = 0
  Caption = 'TMemo Strings Regression'
  ClientHeight = 240
  ClientWidth = 360
  object MemoPlain: TMemo
    Left = 16
    Top = 16
    Width = 150
    Height = 180
    Lines.Strings = (
      'un'
      'deux'
      'trois'
      'quatre')
    TabOrder = 0
  end
  object MemoEncoded: TMemo
    Left = 184
    Top = 16
    Width = 150
    Height = 180
    Lines.Strings = (
      'alpha'#$D#$A
      'beta'
      'gamma')
    TabOrder = 1
  end
end
