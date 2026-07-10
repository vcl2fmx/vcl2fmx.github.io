unit ContractPascalStructureRecordsHelpersLocalRoutines;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
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
