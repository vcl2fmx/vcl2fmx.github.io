unit ContractClassShouldNotAddUIConsts;

interface

uses
  System.SysUtils, System.Classes;

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

