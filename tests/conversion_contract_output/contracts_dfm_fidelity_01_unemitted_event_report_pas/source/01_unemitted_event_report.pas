unit ContractDfmFidelityEvent;

interface

uses
  Vcl.Forms;

type
  TContractDfmFidelityForm = class(TForm)
  private
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  end;

implementation

procedure TContractDfmFidelityForm.FormMouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean);
begin
  Handled := True;
end;

end.
