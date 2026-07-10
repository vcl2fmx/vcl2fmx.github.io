unit ContractMessageDlgNeedsUITypes;
interface
uses System.SysUtils, System.Classes, Vcl.Dialogs;
type TContractMessageDlgNeedsUITypes = class public procedure Run; end;
implementation
procedure TContractMessageDlgNeedsUITypes.Run;
begin
  MessageDlg('question', mtConfirmation, [mbOK, mbCancel], 0);
end;
end.

