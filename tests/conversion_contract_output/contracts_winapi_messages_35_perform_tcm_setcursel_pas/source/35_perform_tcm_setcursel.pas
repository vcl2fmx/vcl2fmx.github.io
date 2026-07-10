unit ContractPerformTCMSetCurSel;

interface

uses System.SysUtils, System.Classes, Vcl.ComCtrls, Winapi.Messages;

type
  TContractPerformTCMSetCurSel = class
  private
    PageControl1: TPageControl;
  public
    procedure Run;
  end;

implementation

procedure TContractPerformTCMSetCurSel.Run;
begin
  PageControl1.Perform(TCM_SETCURSEL, 1, 0);
end;

end.
