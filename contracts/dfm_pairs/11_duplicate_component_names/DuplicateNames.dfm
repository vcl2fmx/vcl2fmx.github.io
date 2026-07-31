object DuplicateNamesForm: TContractDuplicateComponentNames
  object Panel1: TPanel
    Caption = 'Outer panel'
    object Panel1: TPanel
      Caption = 'Inner panel'
    end
  end
end
