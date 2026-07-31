unit ContractScaleByReview;

interface

type
  TContractScaleByReview = class
  public
    procedure ResizeForm;
  end;

implementation

procedure TContractScaleByReview.ResizeForm;
begin
  Self.ScaleBy(2, 1);
end;

end.
