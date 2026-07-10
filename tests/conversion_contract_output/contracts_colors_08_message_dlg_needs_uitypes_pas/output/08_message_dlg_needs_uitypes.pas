unit ContractMessageDlgNeedsUITypes;
interface
uses FMX.Controls, FMX.Dialogs, FMX.Forms, FMX.Graphics, FMX.Types, System.Classes, System.SysUtils,
  System.UITypes, System.Variants;
type TContractMessageDlgNeedsUITypes = class public procedure Run; end;
implementation
procedure TContractMessageDlgNeedsUITypes.Run;
begin
  MessageDlg('question', TMsgDlgType.mtConfirmation, mbOKCancel, 0);
end;
end.
