object RealWorldForm: TRealWorldForm
  Left = 0
  Top = 0
  Caption = 'Real World Report Shape'
  ClientHeight = 300
  ClientWidth = 460
  object Memo1: TMemo
    Left = 16
    Top = 16
    Width = 220
    Height = 120
    Lines.Strings = (
      'real project shape')
    TabOrder = 0
  end
  object StringGrid1: TStringGrid
    Left = 16
    Top = 160
    Width = 400
    Height = 100
    ColCount = 2
    RowCount = 4
    TabOrder = 1
  end
end
