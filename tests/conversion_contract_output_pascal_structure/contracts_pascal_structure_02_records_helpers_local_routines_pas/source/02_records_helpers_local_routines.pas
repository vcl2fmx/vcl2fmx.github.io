unit ContractPascalStructureRecordsHelpersLocalRoutines;

interface

uses
  System.SysUtils;

type
  TContractRecord = record
  private
    FValue: Integer;
  public
    procedure Clear;
    property Value: Integer read FValue write FValue;
  end;

  TContractRecordHelper = record helper for TContractRecord
    procedure ResetTo(const AValue: Integer);
  end;

implementation

procedure TContractRecord.Clear;

  procedure ResetField;
  begin
    FValue := 0;
  end;

begin
  ResetField;
end;

procedure TContractRecordHelper.ResetTo(const AValue: Integer);
begin
  Value := AValue;
end;

end.
