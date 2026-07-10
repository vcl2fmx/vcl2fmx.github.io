unit ContractButtonClickSignature;
interface
uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.StdCtrls;
type TContractButtonClickSignature = class(TForm) Button1: TButton; procedure Button1Click(Sender: TObject); end;
implementation
procedure TContractButtonClickSignature.Button1Click(Sender: TObject);
begin
  Caption := 'clicked';
end;
end.

