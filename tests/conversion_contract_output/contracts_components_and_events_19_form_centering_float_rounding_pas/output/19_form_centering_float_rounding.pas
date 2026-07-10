unit ContractFormCenteringFloatRounding;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
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
  ScreenWidth := Round(Screen.WorkAreaWidth);
  ScreenHeight := Round(Screen.WorkAreaHeight);
  AForm.left := Round((ScreenWidth - AForm.Width) / 2);
  AForm.Top := Round((ScreenHeight - AForm.Height) / 2);
end;
end.
