unit ContractInlineClassTerminator;

interface

uses
  System.SysUtils;

type
  TContractInlineClassTerminator = class
    procedure Touch;
  public OffsetX, OffsetY: Integer end;

implementation

procedure TContractInlineClassTerminator.Touch;
begin
  OffsetX := OffsetX + 1;
  OffsetY := OffsetY + 1;
end;

end.
