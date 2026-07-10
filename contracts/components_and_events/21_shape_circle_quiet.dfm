object ContractShapeCircleQuietForm: TContractShapeCircleQuietForm
  Left = 0
  Top = 0
  Caption = 'Contract Shape Circle Quiet'
  ClientHeight = 120
  ClientWidth = 220
  OnCreate = FormCreate
  object shpLED: TShape
    Left = 24
    Top = 24
    Width = 20
    Height = 20
    Shape = stCircle
    Brush.Color = clRed
  end
end
