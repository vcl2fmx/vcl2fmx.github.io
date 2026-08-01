object ContractCarillonComponentClassification: TForm
  Left = 0
  Top = 0
  ClientHeight = 240
  ClientWidth = 320
  object DatePicker1: TDateTimePicker
    Left = 16
    Top = 16
    Width = 140
    Height = 24
  end
  object FileDialog1: TFileOpenDialog
  end
  object Query1: TADOQuery
    object SongCount: TIntegerField
    end
    object ScheduleTime: TTimeField
    end
    object SongTitle: TWideMemoField
    end
  end
  object SSLHandler1: TIdSSLIOHandlerSocketOpenSSL
  end
end
