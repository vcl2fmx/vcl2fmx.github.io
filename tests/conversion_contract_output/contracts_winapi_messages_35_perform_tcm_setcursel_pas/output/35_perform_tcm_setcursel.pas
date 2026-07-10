unit ContractPerformTCMSetCurSel;
interface
uses FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.Variants;
type
  TContractPerformTCMSetCurSel = class
  private
    PageControl1: TTabControl;
  public
    procedure Run;
  end;
implementation
procedure TContractPerformTCMSetCurSel.Run;
begin
  { FMX: TCM_SETCURSEL - Use FMX list view, tree view, tab control, or adapter APIs instead of common-control messages. }
  { Original: PageControl1.Perform(TCM_SETCURSEL, 1, 0); }
end;
end.
