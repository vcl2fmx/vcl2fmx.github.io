unit ContractConditionalVclThemesRemoved;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants
  {$IFDEF USE_VCL_STYLES}
  {$ENDIF}
;
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
