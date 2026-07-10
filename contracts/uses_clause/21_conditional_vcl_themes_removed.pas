unit ContractConditionalVclThemesRemoved;

interface

uses
  System.SysUtils,
  {$IFDEF USE_VCL_STYLES}
  Vcl.Themes,
  {$ENDIF}
  System.Classes;

type
  TContractConditionalVclThemesRemoved = class
  public
    procedure Run;
  end;

implementation

procedure TContractConditionalVclThemesRemoved.Run;
begin
  Writeln('conditional VCL style unit');
end;

end.
