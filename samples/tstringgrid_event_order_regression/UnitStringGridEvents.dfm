object frmStringGridEvents: TfrmStringGridEvents
  Left = 0
  Top = 0
  Caption = 'StringGrid Event Order Regression'
  ClientHeight = 300
  ClientWidth = 460
  object sgTestAc: TStringGrid
    Left = 15
    Top = 20
    Width = 404
    Height = 245
    ColCount = 3
    RowCount = 10
    TabOrder = 0
    ShowHint = True
    ReadOnly = True
    OnDragOver = sgTestAcDragOver
    OnSelectCell = sgTestAcSelectCell
    OnDragDrop = sgTestAcDragDrop
    OnMouseDown = sgTestAcMouseDown
    OnKeyDown = sgTestKeyDown
  end
end
