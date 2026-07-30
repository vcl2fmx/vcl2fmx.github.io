unit ContractUserAppMenusPreserved;

interface

uses
  System.SysUtils,
  AppMenus,
  MenusConfig,
  MyDBGridsHelper;

type
  TContractUserAppMenusPreserved = class
  public
    procedure Run;
  end;

implementation

procedure TContractUserAppMenusPreserved.Run;
begin
  Writeln('user units whose names contain legacy VCL unit words');
end;

end.
