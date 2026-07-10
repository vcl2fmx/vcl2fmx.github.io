unit ContractBindNavigatorRuntime;
interface
uses Data.Bind.Controls, Fmx.Bind.Navigator, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types,
  System.Classes, System.SysUtils, System.Variants;
type TContractBindNavigatorRuntime = class(TForm) BindNavigator1: TBindNavigator; procedure Run; end;
implementation
procedure TContractBindNavigatorRuntime.Run;
begin
  BindNavigator1.Enabled := True;
end;
end.
