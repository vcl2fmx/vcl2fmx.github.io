unit ContractVclClColorConversion;

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics;

type
  TContractVclClColorConversion = class
  public
    procedure Run;
  end;

implementation

procedure TContractVclClColorConversion.Run;
var
  C: TColor;
begin
  C := clRed;
  Writeln(IntToStr(C));
end;

end.

