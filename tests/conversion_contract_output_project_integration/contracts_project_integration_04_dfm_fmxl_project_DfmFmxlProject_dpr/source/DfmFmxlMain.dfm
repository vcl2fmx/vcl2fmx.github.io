object DfmFmxlForm: TDfmFmxlForm
  Left = 0
  Top = 0
  Caption = 'DFM FMXL Project'
  ClientHeight = 320
  ClientWidth = 520
  object Memo1: TMemo
    Left = 16
    Top = 16
    Width = 220
    Height = 120
    Lines.Strings = (
      'Café'
      'déjà vu'
      'éléphant')
    TabOrder = 0
  end
  object StringGrid1: TStringGrid
    Left = 16
    Top = 160
    Width = 460
    Height = 120
    ColCount = 3
    RowCount = 5
    OnSelectCell = StringGrid1SelectCell
    TabOrder = 1
  end
end
