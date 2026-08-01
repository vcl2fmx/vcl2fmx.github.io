unit ContractWrappedConstParameterList;

interface

type
  TContractWrappedConstParameterList = class
    function GetColor(
      const DisplayColor: Integer;
      const Enabled: Boolean
    ): Integer;
    procedure Touch;
  end;

implementation

function TContractWrappedConstParameterList.GetColor(
  const DisplayColor: Integer;
  const Enabled: Boolean
): Integer;
begin
  if Enabled then
    Result := DisplayColor
  else
    Result := 0;
end;

procedure TContractWrappedConstParameterList.Touch;
begin
end;

end.
