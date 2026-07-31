unit ContractMultiplePublishedMethods;

interface

type
  TContractMultiplePublishedMethods = class
  published
    PublishedCount: Integer;
    PublishedLabel: string;

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
