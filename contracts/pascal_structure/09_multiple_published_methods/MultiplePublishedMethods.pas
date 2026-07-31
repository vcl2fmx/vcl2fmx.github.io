unit ContractMultiplePublishedMethods;

interface

type
  TContractMultiplePublishedMethods = class
  published
    procedure FirstPublished;
    procedure SecondPublished;
  end;

implementation

procedure TContractMultiplePublishedMethods.FirstPublished;
begin
end;

procedure TContractMultiplePublishedMethods.SecondPublished;
begin
end;

end.
