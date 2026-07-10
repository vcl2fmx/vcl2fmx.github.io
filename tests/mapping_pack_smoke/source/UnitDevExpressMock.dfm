object FormDevExpressMock: TFormDevExpressMock
  Left = 0
  Top = 0
  Caption = 'DevExpress Mapping Pack Mock Test'
  ClientHeight = 360
  ClientWidth = 560
  object cxButton1: TcxButton
    Left = 24
    Top = 24
    Width = 120
    Height = 32
    Caption = 'Click Me'
    Enabled = True
    Visible = True
    Hint = 'Button hint'
    OnClick = cxButton1Click
  end
  object cxTextEdit1: TcxTextEdit
    Left = 24
    Top = 72
    Width = 180
    Height = 24
    Text = 'Sample text'
    Enabled = True
    Visible = True
    OnChange = cxTextEdit1Change
  end
  object cxMemo1: TcxMemo
    Left = 24
    Top = 112
    Width = 220
    Height = 80
    Text = 'Sample memo'
    Enabled = True
    Visible = True
  end
  object cxMaskEdit1: TcxMaskEdit
    Left = 24
    Top = 208
    Width = 180
    Height = 24
    Text = '12345'
  end
  object cxGrid1: TcxGrid
    Left = 260
    Top = 24
    Width = 260
    Height = 180
  end
  object dxRibbon1: TdxRibbon
    Left = 0
    Top = 264
    Width = 560
    Height = 80
  end
end
