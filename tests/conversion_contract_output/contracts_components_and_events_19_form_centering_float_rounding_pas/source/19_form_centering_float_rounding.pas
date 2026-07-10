unit ContractFormCenteringFloatRounding;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms;

type
  TContractFormCenteringFloatRounding = class(TForm)
  private
    procedure CenterFormForScreen(AForm: TForm);
  end;

implementation

procedure TContractFormCenteringFloatRounding.CenterFormForScreen(AForm: TForm);
var
  ScreenWidth, ScreenHeight: Integer;
begin
  ScreenWidth := Screen.WorkAreaWidth;
  ScreenHeight := Screen.WorkAreaHeight;

  AForm.left := (ScreenWidth - AForm.Width) div 2;
  AForm.Top := (ScreenHeight - AForm.Height) div 2;
end;

end.
