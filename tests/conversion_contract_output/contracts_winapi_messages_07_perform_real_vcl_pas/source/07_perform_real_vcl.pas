unit ContractPerformRealVcl;

interface

uses
  System.SysUtils, System.Classes, Vcl.StdCtrls;

type
  TContractPerformRealVcl = class
  private
    Memo1: TMemo;
  public
    procedure Run;
  end;

implementation

procedure TContractPerformRealVcl.Run;
begin
  Memo1.Perform(EM_LINESCROLL, 0, -3);
end;

end.

