unit ContractStatusBarPanels;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.ComCtrls;
type TContractStatusBarPanels = class(TForm) StatusBar1: TStatusBar; procedure Run; end;
implementation
procedure TContractStatusBarPanels.Run;
begin
  StatusBar1.Panels[0].Text := 'ready';
end;
end.

