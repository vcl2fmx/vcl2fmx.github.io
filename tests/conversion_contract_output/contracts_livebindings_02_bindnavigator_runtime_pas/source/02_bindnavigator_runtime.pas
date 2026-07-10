unit ContractBindNavigatorRuntime;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Data.Bind.Controls;
type TContractBindNavigatorRuntime = class(TForm) BindNavigator1: TBindNavigator; procedure Run; end;
implementation
procedure TContractBindNavigatorRuntime.Run;
begin
  BindNavigator1.Enabled := True;
end;
end.

