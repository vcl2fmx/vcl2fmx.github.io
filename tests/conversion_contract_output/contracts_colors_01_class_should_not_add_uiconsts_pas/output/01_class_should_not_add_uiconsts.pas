unit ContractClassShouldNotAddUIConsts;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractClassShouldNotAddUIConsts = class
  public
    procedure Run;
  end;
implementation
procedure TContractClassShouldNotAddUIConsts.Run;
var
  TClassName: string;
begin
  TClassName := 'class and declare are not cla colors';
  Writeln(TClassName);
end;
end.
